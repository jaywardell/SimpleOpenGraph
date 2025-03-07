//
//  OpenGraph Tests.swift
//  SkyMark Data Tests
//
//  Created by Joseph Wardell on 12/14/24.
//

import Testing
import Foundation

// we don't want the init(html:) method to be public
@testable import SimpleOpenGraph

struct OpenGraph_Tests {

    struct init_from_array {
        @Test func throws_if_given_empty_array() async throws {
            #expect(throws: OpenGraph.Error.notFound) {
                try OpenGraph([(String, String)]())
            }
        }
    }

    struct init_html {
        @Test func throws_if_given_empty_string() async throws {
            #expect(throws: OpenGraph.Error.notFound) {
                try OpenGraph(html: "")
            }
        }
        
        @Test func throws_if_no_head_in_source() async throws {
            let source = "<html></html>"
            #expect(throws: OpenGraph.Error.notFound) {
                try OpenGraph(html: source)
            }
        }

        @Test func throws_if_no_title() async throws {
            let meta = """
            <meta property="og:type" content="some title" />
            """
            let source = Helpers.source(meta)

            #expect(throws: OpenGraph.Error.noTitle) {
                try OpenGraph(html: source)
            }
        }

        @Test func throws_if_no_url() async throws {
            let meta = """
            <meta property="og:type" content="some type" />
            <meta property="og:title" content="some title" />
            """
            let source = Helpers.source(meta)
            
            #expect(throws: OpenGraph.Error.noURL) {
                try OpenGraph(html: source)
            }
        }

        @Test func throws_if_url_is_invalid() async throws {
            let meta = """
            <meta property="og:type" content="some type" />
            <meta property="og:title" content="some title" />
            <meta property="og:url" content="invalid" />
            """
            let source = Helpers.source(meta)
            
            #expect(throws: OpenGraph.Error.noURL) {
                try OpenGraph(html: source)
            }
        }

        @Test func does_not_throw_if_given_title_and_url() async throws {
            let source = Helpers.validSource()
            
            #expect(throws: Never.self) {
                try OpenGraph(html: source)
            }
        }
        
        @Test func if_no_type_given_then_type_is_website() async throws {
            // see https://ogp.me/#types at the bottom of the section
            let source = Helpers.validSource()
            #expect(try OpenGraph(html: source).type == "website")
        }

    }

    struct subscripts {
        @Test func get_as_string() async throws {
            let sut = try OpenGraph(html: Helpers.simpleExample)
            
            #expect(sut["title"] == [Helpers.simpleExampleTitle])
        }

        @Test func get_as_key() async throws {
            let sut = try OpenGraph(html: Helpers.simpleExample)
            
            #expect(sut[.title] == [Helpers.simpleExampleTitle])
        }
 
        @Test func get_structured_proeprty_as_key() async throws {
            let audioLine = "<meta property=\"og:video:actor\" content=\"John\" />"
            let sut = try OpenGraph(html: Helpers.validSource(audioLine))
            
            #expect(sut[.videoActor] == [ "John"])
        }
    }
    
    struct basic_properties {
        @Test func title() async throws {
            let sut = try OpenGraph(html: Helpers.simpleExample)
            
            #expect(sut.title == Helpers.simpleExampleTitle)
        }

        @Test func title_expands_html_entities() async throws {

            let htmlEncodedExample = Helpers.source(
                    """
                   <meta property="og:title" content="The Rock &dollar; &amp; Roll" />
                   <meta property="og:type" content="video.movie" />
                   <meta property="og:url" content="https://www.imdb.com/title/tt0117500/" />
                   <meta property="og:image" content="https://ia.media-imdb.com/images/rock.jpg" />
                   """
            )
            
            let sut = try OpenGraph(html: htmlEncodedExample)
            
            // explicitly:
            #expect(sut.title == sut.title?.decodingHTMLEntities())
            // for example:
            #expect(sut.title?.contains("$") == true)
        }

        @Test func type() async throws {
            let sut = try OpenGraph(html: Helpers.simpleExample)
            
            #expect(sut.type == Helpers.simpleExampleType)
        }

        @Test func url() async throws {
            let sut = try OpenGraph(html: Helpers.simpleExample)
            
            #expect(sut.url == Helpers.simpleExampleURL)
        }
        
        @Test func description() async throws {
            let sut = try OpenGraph(html: Helpers.simpleExample)
            
            #expect(sut.description == Helpers.simpleExampleDescription)
        }

        @Test func description_expands_html_entities() async throws {
            let expected = "description$"
            let htmlEncodedExample = Helpers.source(
                    """
                   <meta property="og:title" content="The Rock &dollar; &amp; Roll" />
                   <meta property="og:type" content="video.movie" />
                   <meta property="og:url" content="https://www.imdb.com/title/tt0117500/" />
                   <meta property="og:image" content="https://ia.media-imdb.com/images/rock.jpg" />
                   <meta property="og:description" content="description&dollar;" />
                   """
            )

            let sut = try OpenGraph(html: htmlEncodedExample)
            
            #expect(sut.description?.contains("$") == true)
            #expect(sut.description == expected)
        }

    }
    
    struct Images {
        func test_returns_empty_array_if_no_images_found() throws {
            let sut = try OpenGraph(html: Helpers.validSource())
            
            #expect(sut.images().isEmpty)
        }
        
        @Test func test_returns_one_simple_image_if_found() async throws {
            let imagesource = """
            <meta property="og:image" content="https://ia.media-imdb.com/images/rock.jpg" />
            """
            let sut = try OpenGraph(html: Helpers.validSource(imagesource))

            #expect(sut.images().count == 1)
        }

        @Test func test_returns_one_image_if_given_image_url_property() async throws {
            let imagesource = """
            <meta property="og:image:url" content="https://ia.media-imdb.com/images/rock.jpg" />
            """
            let sut = try OpenGraph(html: Helpers.validSource(imagesource))

            #expect(sut.images().count == 1)
        }

        @Test func test_returns_one_image_if_given_secure_image_url_property() async throws {
            let imagesource = """
            <meta property="og:image:secure_url" content="https://ia.media-imdb.com/images/rock.jpg" />
            """
            let sut = try OpenGraph(html: Helpers.validSource(imagesource))

            #expect(sut.images().count == 1)
        }

        @Test func test_does_not_duplicate_images() async throws {
            let imagesource = """
            <meta property="og:image:url" content="https://ia.media-imdb.com/images/rock.jpg" />
            <meta property="og:image:secure_url" content="https://ia.media-imdb.com/images/rock.jpg" />
            <meta property="og:image:secure_url" content="https://ia.media-imdb.com/images/rock.jpg" />
            """
            let sut = try OpenGraph(html: Helpers.validSource(imagesource))

            #expect(sut.images().count == 1)
        }

        @Test func test_disinguishes_multiple_images() async throws {
            // same URL in 2 different tags,
            // but 2 following tags have 2 different URLs
            let imagesource = """
            <meta property="og:image" content="https://ia.media-imdb.com/images/rock.jpg" />
            <meta property="og:image:url" content="https://ia.media-imdb.com/images/rock.jpg" />
            <meta property="og:image:secure_url" content="https://ia.media-imdb.com/images/paper.jpg" />
            <meta property="og:image:secure_url" content="https://ia.media-imdb.com/images/scissors.jpg" />
            """
            let sut = try OpenGraph(html: Helpers.validSource(imagesource))

            #expect(sut.images().count == 3)
        }

    }
    
    struct displayName {
        @Test func shows_title_if_no_site_name() async throws {
            let expected = "some title"
            let html = Helpers.source(
            """
             <meta property="og:title" content="\(expected)" />
              <meta property="og:type" content="article" />
              <meta property="og:url" content="https://jaywardell.me" />
           """
            )
            let sut = try OpenGraph(html: Helpers.source(html))
            #expect(sut.displayName == expected)
        }

        @Test func shows_site_name_and_title_if_site_name_given() async throws {
            let title = "some title"
            let siteName = "some site name"
            let expected = "\(siteName) | \(title)"
            let html = Helpers.source(
            """
             <meta property="og:title" content="\(title)" />
             <meta property="og:site_name" content="\(siteName)" />
              <meta property="og:type" content="article" />
              <meta property="og:url" content="https://jaywardell.me" />
           """
            )
            let sut = try OpenGraph(html: Helpers.source(html))
            #expect(sut.displayName == expected)
        }

        @Test func shows_title_only_if_same_as_site_name() async throws {
            let title = "site name and title are the same"
            let siteName = "site name and title are the same"
            let expected = title
            let html = Helpers.source(
            """
             <meta property="og:title" content="\(title)" />
             <meta property="og:site_name" content="\(siteName)" />
              <meta property="og:type" content="article" />
              <meta property="og:url" content="https://jaywardell.me" />
           """
            )
            let sut = try OpenGraph(html: Helpers.source(html))
            #expect(sut.displayName == expected)
        }
    }
    
    // Helpers
    enum Helpers {
        static func source(_ string: String) -> String {
            """
            <html>
            <head>
            \(string)
            </head>
            </html>
            """
        }
        
        static func validSource(_ string: String = "") -> String {
            """
            <html>
            <head>
             <meta property="og:title" content="The Rock" />
             <meta property="og:url" content="https://www.imdb.com/title/tt0117500/" />
            \(string)
            </head>
            </html>
            """
        }
        
        static var simpleExample: String {
            source(
                """
               <meta property="og:title" content="The Rock" />
               <meta property="og:type" content="video.movie" />
               <meta property="og:url" content="https://www.imdb.com/title/tt0117500/" />
               <meta property="og:image" content="https://ia.media-imdb.com/images/rock.jpg" />
               <meta property="og:description" content="descriptions" />
               """
            )
        }

        static var simpleExampleTitle: String { "The Rock" }
        static var simpleExampleType: String { "video.movie" }
        static var simpleExampleURL: URL { URL(string: "https://www.imdb.com/title/tt0117500/")! }
        static var simpleExampleImageURL: URL { URL(string: "https://ia.media-imdb.com/images/rock.jpg")! }
        static var simpleExampleDescription: String { "descriptions" }
    }
}
