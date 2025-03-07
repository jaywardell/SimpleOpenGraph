//
//  CachingOpenGraphRetriever.swift
//  SkyMark Data
//
//  Created by Joseph Wardell on 12/15/24.
//

import Foundation
import OSLog
internal import CacheCow

public final class CachingOpenGraphRetriever {
    
    private let archiver: CacheArchiver
    private let cache: Cache<URL, OpenGraph>
    private let retriever: OpenGraphRetriever
    
    /// a type that can be passed in on init
    /// which determines if any specific logging should be done
    public struct TestingParameters {
        
        /// if true, then the the process of creating an OpenGraph instance will be logged
        ///
        /// this includes
        /// * each meta tag found
        /// * each OpenGraph tag that is put in the created `OpemGraph` instance
        /// * any errors encountered,
        /// * the full source of the html that was used if an error was encountered
        let logParsing: Bool
        
        /// If true, then any time there is no cached OpenGraph instance
        /// for an URL that's already been retrieved once,
        /// there will be a log message
        let logDuplicateLoads: Bool
    }
    let testing: TestingParameters?
    
    private var retrievedURLs = Set<URL>()

    public init(
        name: String,
        appGroupID: String? = nil,
        testing: TestingParameters? = nil
    ) {
        self.archiver = CacheArchiver(name: name, groupID: appGroupID)
        self.retriever = OpenGraphRetriever()
        
        do {
            let c: Cache<URL, OpenGraph> = try archiver.load()
            self.cache = c
            if true == testing?.logDuplicateLoads {
                self.retrievedURLs = Set(c.keys)
        }
        }
        catch {
            self.cache = Cache()
        }
        
        self.testing = testing
    }
        
    public func retrieveOpenGraph(at url: URL) async throws -> OpenGraph {
        
        if let cached = cache.value(for: url) {
            return cached
        }
        
        if true == testing?.logDuplicateLoads && retrievedURLs.contains(url) {
            // this is a class, so it's not isolated
            // so we could theoretically get multiple requests to retrieve the same URL
            // if that happens, log it so that we can know in testing
            Logger.opengraphRetrieval.warning("retrieved url \(url.absoluteString) for a second time")
        }
        
        let retrieved = try await retriever.retrieveOpenGraph(at: url, logging: true == testing?.logParsing)
        cache.insert(retrieved, for: url)
        
        if true == testing?.logDuplicateLoads {
            retrievedURLs.insert(url)
        }
        
        Logger.opengraphRetrieval.info("retrieved URL \(url)")
        do {
            try await archiver.saveCacheToFile(cache)
        }
        catch {
            Logger.opengraphRetrieval.error("Error archiving ur: \(url), \(error.localizedDescription)")
        }
        
        return retrieved
    }
}

// MARK: -

fileprivate extension Logger {
    // see https://www.avanderlee.com/debugging/oslog-unified-logging/
        
    /// Logs the view cycles like a view that appeared.
    static let opengraphRetrieval = Logger(subsystem: "\(CachingOpenGraphRetriever.self)", category: "opengraph retrieval")
}
