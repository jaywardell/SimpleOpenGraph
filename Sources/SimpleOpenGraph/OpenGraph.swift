//
//  OpenGraph.swift
//  SkyMark Data
//
//  Created by Joseph Wardell on 12/14/24.
//

import Foundation
internal import TagUrIt

public struct OpenGraph: Equatable, Codable, Sendable {
    
    private struct Tag: Equatable, Codable {
        let key: String
        let value: String
    }
    private let tags: [Tag]
        
    #if DEBUG
    public init(_ array: [(Key, String)]) throws {
        let tags = array.map { ($0.rawValue, $1) }
        try self.init(tags)
    }
    #endif
    
    init(_ array: [(String, String)]) throws {
        guard !array.isEmpty else { throw Error.notFound }
        
        // insist on title and type properties
        guard array.containsValue(matching: Key.title.rawValue) else { throw Error.noTitle }
        
        // insist on url property,
        // and it must be valid http or https
        let webSchemes: [String?] = ["http", "https"]
        let possibleURLs = array.allValues(matching: Key.url.rawValue)
        guard !possibleURLs.isEmpty,
              nil != possibleURLs.first(where: {
                  guard let url = URL(string: $0) else { return false }
                  return webSchemes.contains(url.scheme)
              })
        else { throw Error.noURL }
        
        // yes, https://ogp.me says that image is a required property,
        // but it's conceivable that a page could not have an image
        // for some reason
        // so we don't insist upon it
        
        self.tags = array.map { Tag(key: $0, value: $1) }
    }
    
    init(html: String, verboseErrorLogging: Bool = false) throws {
 
        func stripog(from string: String) -> String {
            guard let firstColon = string.firstIndex(of: ":") else { return "" }
            return String(string[string.index(after: firstColon)...])
        }
        
        let tags: [(String, String)] = MetaTag.all(in: html)
            .map { tag in
                if verboseErrorLogging {
                    #if DEBUG
                    print(tag)
                    #endif
                }
                let property = tag.attribute(for: "property")
                let og = property?.value
                let content = tag.attribute(for: "content")?.value
                return (og, content)
            }
            .compactMap { (property: String?, content: String?) in
                guard let property, let content else { return nil }
                return (stripog(from: property), content.htmlDecoded)
            }
        
        do {
            try self.init(tags) 
        }
        catch {
            print("Error creating OpenGraph instance: \(error.localizedDescription)")
            if verboseErrorLogging {
                #if DEBUG
                print(html)
                #endif
            }
            throw error
        }
    }
}

// MARK: - fetching properties
public extension OpenGraph {
    
    /// Given a Key, return any opengraph property that matches that key in the document
    ///
    /// Note: results are not url-unencoded, so user-facing strings may need extra processing to look right
    subscript(_ key: OpenGraph.Key) -> [String]? {
        self[key.rawValue]
    }

    subscript(_ key: String) -> [String]? {
        tags.filter {
            $0.key == key
        }
        .map(\.value)
    }

    // the required properties can technically have multiple values
    // but for our purposes, we just care about the first valid one
    
    // NOTE: decodes html entities
    var siteName: String? { self[Key.siteName]?.first?.htmlDecoded }
    var title: String? { self[Key.title]?.first?.htmlDecoded }
    
    // according to https://ogp.me/#types (at the bottom of the section):
    // "Any non-marked up webpage should be treated as og:type website."
    static var websiteType: String { "website" }
    var type: String? { self[Key.type]?.first ?? Self.websiteType }

    // NOTE: decodes html entities
    var description: String? { self[Key.description]?.first?.htmlDecoded }
    var url: URL {
        // it has to be there because the init required it
        self[Key.url]!
            .compactMap(URL.init(string:))
            .first!
    }

    func contains(_ key: String, matching match: String) -> Bool {
        nil != tags.first { $0.key == key && $0.value == match }
    }
    
    subscript(_ key: String) -> [String] {
        tags.filter {
            $0.key == key
        }
        .map(\.value)
    }
}

extension OpenGraph {
    public var displayName: String {
        if let siteName,
        let title,
           siteName != title
        // will never be nil, but it is an optional…
        {
            return "\(siteName) | \(title)"
        }
        
        return title ?? ""
    }
}

extension OpenGraph {
    public struct Image: Hashable {
        // NOTE: Opengraph offers much richer data about images
        // such as height and width and mime type, etc.
        // however, it could be some real work to deal with all those possiblities
        public let url: URL
    }
    
    public func images() -> [Image] {
        let imageTags = self[.image] ?? []
        let imageURLTags = self[.imageUrl] ?? []
        let secureImageURLTags = self[.secureImageURL] ?? []
        let allTags = imageTags + imageURLTags + secureImageURLTags
        
        return allTags
            .compactMap {
                guard let url = URL(string: $0) else { return nil }
                return Image(url: url)
            }
            .unique()
    }

}

// MARK: -
extension OpenGraph {

    enum Error: Swift.Error, LocalizedError {
        case notFound
        case noTitle
        case noURL
        
        var errorDescription: String? {
            switch self {
                
            case .notFound:
                "No meta tags were provided"
            case .noTitle:
                "No title opengraph tag was provided"
            case .noURL:
                "No URL opengraph tag was provided"
            }
        }
    }
}

// MARK: -
public extension OpenGraph {
    
    // see, https://ogp.me
    enum Key: String, CaseIterable {
        // Basic Metadata
        case title
        case type
        case image
        case url
        
        // Optional Metadata
        case audio
        case description
        case determiner
        case locale
        case localeAlternate = "locale:alternate"
        case siteName = "site_name"
        case video
        
        // Structured Properties
        case imageUrl        = "image:url"
        case secureImageURL = "image:secure_url"
        case imageType       = "image:type"
        case imageWidth      = "image:width"
        case imageHeight     = "image:height"
        
        // Music
        case musicDuration    = "music:duration"
        case musicAlbum       = "music:album"
        case musicAlbumDisc   = "music:album:disc"
        case musicAlbumMusic  = "music:album:track"
        case musicMusician    = "music:musician"
        case musicSong        = "music:song"
        case musicSongDisc    = "music:song:disc"
        case musicSongTrack   = "music:song:track"
        case musicReleaseDate = "music:release_date"
        case musicCreator     = "music:creator"

        // Video
        case videoActor       = "video:actor"
        case videoActorRole   = "video:actor:role"
        case videoDirector    = "video:director"
        case videoWriter      = "video:writer"
        case videoDuration    = "video:duration"
        case videoReleaseDate = "video:releaseDate"
        case videoTag         = "video:tag"
        case videoSeries      = "video:series"

        // No Vertical
        case articlePublishedTime  = "article:published_time"
        case articleModifiedTime   = "article:modified_time"
        case articleExpirationTime = "article:expiration_time"
        case articleAuthor         = "article:author"
        case articleSection        = "article:section"
        case articleTag            = "article:tag"

        case bookAuthor      = "book:author"
        case bookIsbn        = "book:isbn"
        case bookReleaseDate = "book:release_date"
        case bookTag         = "book:tag"

        case profileFirstName = "profile:first_name"
        case profileLastName  = "profile:last_name"
        case profileUsername  = "profile:username"
        case profileGender    = "profile:gender"
    }
}
