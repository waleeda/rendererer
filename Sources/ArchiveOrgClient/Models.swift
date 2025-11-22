import Foundation

public struct ArchiveSearchContainer: Decodable {
    public let response: ArchiveSearchResponse
}

public struct ArchiveSearchResponse: Decodable, Equatable {
    public let numFound: Int
    public let start: Int
    public let docs: [ArchiveSearchDocument]
}

public struct ArchiveSearchDocument: Decodable, Equatable {
    public let identifier: String
    public let title: String?
    public let creator: [String]?
    public let collection: [String]?
    public let mediatype: String?
}

public struct ArchiveItemMetadata: Decodable, Equatable {
    public let metadata: ArchiveItemDetails
    public let files: [ArchiveFile]
}

public struct ArchiveItemDetails: Decodable, Equatable {
    public let identifier: String
    public let title: String?
    public let creator: [String]?
    public let description: [String]?
    public let subject: [String]?
}

public struct ArchiveFile: Decodable, Equatable {
    public let name: String
    public let size: Int64?
    public let format: String?
    public let md5: String?
    public let sha1: String?
    public let mtime: Int?

    enum CodingKeys: String, CodingKey {
        case name
        case size
        case format
        case md5
        case sha1
        case mtime
    }
}
