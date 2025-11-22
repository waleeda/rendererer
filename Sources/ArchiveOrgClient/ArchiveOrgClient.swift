import Foundation
import FoundationNetworking

/// A lightweight client for the Archive.org HTTP API.
public final class ArchiveOrgClient {
    public enum ClientError: Error, Equatable {
        case invalidURL
        case unexpectedStatusCode(Int)
        case decodingFailed
        case requestFailed(Error)

        public static func == (lhs: ClientError, rhs: ClientError) -> Bool {
            switch (lhs, rhs) {
            case (.invalidURL, .invalidURL):
                return true
            case let (.unexpectedStatusCode(a), .unexpectedStatusCode(b)):
                return a == b
            case (.decodingFailed, .decodingFailed):
                return true
            case let (.requestFailed(a), .requestFailed(b)):
                return (a as NSError).domain == (b as NSError).domain && (a as NSError).code == (b as NSError).code
            default:
                return false
            }
        }
    }

    private let session: URLSession
    private let baseURL: URL

    /// Creates a new client instance.
    /// - Parameters:
    ///   - session: The URLSession used to perform requests. Defaults to ``URLSession.shared``.
    ///   - baseURL: The Archive.org API base URL. Defaults to ``https://archive.org``.
    public init(session: URLSession = .shared, baseURL: URL = URL(string: "https://archive.org")!) {
        self.session = session
        self.baseURL = baseURL
    }

    /// Performs an advanced search query.
    /// - Parameters:
    ///   - query: The search query string.
    ///   - page: The page index (1-based).
    ///   - rows: The number of results per page.
    ///   - fields: Specific fields to request. Uses Archive.org defaults when not provided.
    /// - Returns: A decoded ``ArchiveSearchResponse``.
    public func search(
        query: String,
        page: Int = 1,
        rows: Int = 50,
        fields: [String]? = nil
    ) async throws -> ArchiveSearchResponse {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.path = "/advancedsearch.php"
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "output", value: "json"),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "rows", value: String(rows))
        ]

        if let fields, !fields.isEmpty {
            queryItems.append(contentsOf: fields.map { URLQueryItem(name: "fl[]", value: $0) })
        }

        components?.queryItems = queryItems

        guard let url = components?.url else { throw ClientError.invalidURL }
        let searchContainer: ArchiveSearchContainer = try await performRequest(url: url)
        return searchContainer.response
    }

    /// Retrieves metadata for an Archive.org item.
    /// - Parameter identifier: The Archive.org item identifier.
    /// - Returns: Decoded item metadata including the file listing.
    public func itemMetadata(identifier: String) async throws -> ArchiveItemMetadata {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.path = "/metadata/\(identifier)"

        guard let url = components?.url else { throw ClientError.invalidURL }
        return try await performRequest(url: url)
    }

    /// Downloads a specific file associated with an Archive.org item.
    /// - Parameters:
    ///   - identifier: The Archive.org item identifier.
    ///   - fileName: The file name from the item's metadata response.
    /// - Returns: Raw file data.
    public func downloadFile(identifier: String, fileName: String) async throws -> Data {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.path = "/download/\(identifier)/\(fileName)"

        guard let url = components?.url else { throw ClientError.invalidURL }
        return try await performRawRequest(url: url)
    }

    // MARK: - Internal Helpers

    private func performRequest<T: Decodable>(url: URL) async throws -> T {
        let request = URLRequest(url: url)
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClientError.unexpectedStatusCode(-1)
            }

            guard (200 ... 299).contains(httpResponse.statusCode) else {
                throw ClientError.unexpectedStatusCode(httpResponse.statusCode)
            }

            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw ClientError.decodingFailed
            }
        } catch let error as ClientError {
            throw error
        } catch {
            throw ClientError.requestFailed(error)
        }
    }

    private func performRawRequest(url: URL) async throws -> Data {
        let request = URLRequest(url: url)
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClientError.unexpectedStatusCode(-1)
            }

            guard (200 ... 299).contains(httpResponse.statusCode) else {
                throw ClientError.unexpectedStatusCode(httpResponse.statusCode)
            }

            return data
        } catch let error as ClientError {
            throw error
        } catch {
            throw ClientError.requestFailed(error)
        }
    }
}
