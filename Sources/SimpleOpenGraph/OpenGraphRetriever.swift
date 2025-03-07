//
//  OpenGraphRetriever.swift
//  SkyMark Data
//
//  Created by Joseph Wardell on 12/14/24.
//

import Foundation
internal import NetworkRetrievers

public actor OpenGraphRetriever {
              
    public static let fetcher = OpenGraphRetriever()
    
    public func retrieveOpenGraph(at url: URL, logging: Bool = false) async throws -> OpenGraph {
        
        do {
            let source = try await StringRetriever.retrieveString(from: url)
            if logging {
                print("retrieving opengraph for \(url)")
            }
            return try OpenGraph(html: source, verboseLogging: logging)
        }
        catch {
            print("Error loading OpenGraph for page at \(url)")
            print(error.localizedDescription)
            print(error)
            
            throw error
        }
    }
}
