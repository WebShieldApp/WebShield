import Foundation

/// Simple container for the results of a single filter list conversion
struct ProcessedConversionResult {
    /// The regular JSON string (Safari content blocker format)
    let converted: String?
    /// The advanced blocking JSON string (if any)
    let advancedBlocking: String?
    /// Count of standard rules
    let convertedCount: Int
    /// Count of advanced rules
    let advancedBlockingCount: Int
    /// Number of errors encountered
    let errorsCount: Int
    /// If the converter found the rules were over the size limit
    let overLimit: Bool
    /// A human-readable message about the conversion
    let message: String?
}
