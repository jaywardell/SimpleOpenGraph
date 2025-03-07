# SimpleOpenGraph

This is just about the world's simplest framework for loading and reading [**Open Graph**](https://ogp.me) data from web pages.

It's used by SkyMarks to load Open Graph data from `bsky.app`, and it's only been tested against that specific purpose.

## OpenGraph

The `OpenGraph` type stores Open Graph data that's been retrieved from a web page. It supports the basic elements of the Open Graph protocol as defined at https://ogp.me but it does not respect or guarantee order. If there is more than one `og:image` property in the document, the `OpenGraph` is guaranteed to ahve at least one, but it's not guaranteed to have any particular one. Also, any image structured properties (e.g. `og:image:type`, `og:image:width`) are not guaranteed to be associated with any particular `image` property. The same is true for other structured properties. Basically, `OpenGraph` assumes uniqueness for all opengraph properties and just includes all properties in a single array that's accessible via subscript.

`OpenGraph.init()` ensures valid opengraph format. See `OpenGraph Tests.swift` for examples of the rules it enforces.

## OpenGraphRetriever

This is a retriever type in the style of the retrievers in `NetworkRetrievers`. It has a single method to retrieve an `OpenGraph` instance from a given `URL`.

## CachingOpenGraphRetriever

This is a retriever type like `OpenGraphRetriever`, but it maintains an on-disk cache of `OpenGraph` instances that have been loaded before. It uses `CacheCow` to maintain this cache. Its init takes an optional **Group ID** which can be used to save a shared cache for an App Group (e.g. to share a cache between an app and a widget or an app and an action extension) 

## Dependencies

This package depends on a few others:

        // to parse meta tags from html:
        .package(url: "https://github.com/jaywardell/TagUrIt", .upToNextMajor(from: "0.1.0")),
        
        // to retrieve html source over the nework
        .package(url: "https://github.com/jaywardell/NetworkRetrievers", .upToNextMajor(from: "0.4.0")),
        
        // to cache retrieved opengraph data
        .package(url: "https://github.com/jaywardell/CacheCow", .upToNextMajor(from: "0.2.0")),


