//
//  Array+String_String_Tuple.swift
//  SkyMark Data
//
//  Created by Joseph Wardell on 12/14/24.
//

import Foundation

extension Array where Element == (String, String) {
    func allValues(matching key: String) -> [String] {
        self
            .filter { $0.0 == key }
            .map { $0.1 }
    }

    func firstValue(matching key: String) -> String? {
        self
            .first { $0.0 == key }?
            .1
    }

    func containsValue(matching key: String) -> Bool {
        nil != self
            .firstValue(matching: key)
    }

    func contains(value filter: String, matching key: String) -> Bool {
        nil != self
            .first { $0.0 == key && $0.1 == filter }
    }

}
