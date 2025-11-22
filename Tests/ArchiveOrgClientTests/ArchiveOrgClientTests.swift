import Foundation
import FoundationNetworking
import XCTest
@testable import ArchiveOrgClient

final class ArchiveOrgClientTests: XCTestCase {
    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    func testSearchDecoding() async throws {
        let searchJSON = """
        {
          "response": {
            "numFound": 1,
            "start": 0,
            "docs": [
              {
                "identifier": "test_item",
                "title": "Test Item",
                "creator": ["Test Creator"],
                "collection": ["texts"],
                "mediatype": "texts"
              }
            ]
          }
        }
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, searchJSON)
        }

        let session = makeSession()
        let client = ArchiveOrgClient(session: session)
        let result = try await client.search(query: "test")

        XCTAssertEqual(result.numFound, 1)
        XCTAssertEqual(result.docs.first?.identifier, "test_item")
        XCTAssertEqual(result.docs.first?.title, "Test Item")
    }

    func testMetadataDecoding() async throws {
        let metadataJSON = """
        {
          "metadata": {
            "identifier": "test_item",
            "title": "Test Item",
            "creator": ["Creator"],
            "description": ["A test item"],
            "subject": ["Testing"]
          },
          "files": [
            {
              "name": "sample.txt",
              "size": 1234,
              "format": "Text",
              "md5": "abc",
              "sha1": "def",
              "mtime": 1700000000
            }
          ]
        }
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, metadataJSON)
        }

        let session = makeSession()
        let client = ArchiveOrgClient(session: session)
        let metadata = try await client.itemMetadata(identifier: "test_item")

        XCTAssertEqual(metadata.metadata.identifier, "test_item")
        XCTAssertEqual(metadata.files.first?.name, "sample.txt")
        XCTAssertEqual(metadata.files.first?.size, 1234)
    }

    func testUnexpectedStatusCodeThrows() async {
        let errorData = Data()
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, errorData)
        }

        let session = makeSession()
        let client = ArchiveOrgClient(session: session)

        do {
            _ = try await client.search(query: "test")
            XCTFail("Expected to throw")
        } catch let error as ArchiveOrgClient.ClientError {
            XCTAssertEqual(error, .unexpectedStatusCode(500))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
