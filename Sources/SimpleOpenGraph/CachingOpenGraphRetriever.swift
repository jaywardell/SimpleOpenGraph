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
    
    public struct TestingParameters {
        let logHTMLSource: Bool
        let logDuplicateLoads: Bool
    }
    let testing: TestingParameters?
    
    public init(
        name: String,
        appGroupID: String? = nil,
        testing: TestingParameters? = nil
    ) {
        self.archiver = CacheArchiver(name: name, groupID: appGroupID)
        
        do {
            let c: Cache<URL, OpenGraph> = try archiver.load()
            self.cache = c
        }
        catch {
            self.cache = Cache()
        }
        
        self.testing = testing
    }
    
    private var retrievedURLs = Set<URL>()
    
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
        
        let retrieved = try await OpenGraphRetriever.fetcher.retrieveOpenGraph(at: url, logging: true == testing?.logHTMLSource)
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
