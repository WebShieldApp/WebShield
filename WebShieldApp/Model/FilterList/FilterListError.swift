//
//  FilterListError.swift
//  WebShield
//
//  Created by Arjun on 2024-07-16.
//

import Foundation

enum FilterListError: LocalizedError {
    case invalidData
    case invalidFormat
    case downloadFailed
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid filter list data"
        case .invalidFormat:
            return "Invalid filter list format"
        case .downloadFailed:
            return "Failed to download filter list"
        case .parsingFailed:
            return "Failed to parse filter list"
        }
    }
}
