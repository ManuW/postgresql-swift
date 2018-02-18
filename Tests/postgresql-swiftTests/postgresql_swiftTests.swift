import XCTest
@testable import postgresql_swift

class postgresql_swiftTests: XCTestCase {

    let connInfo = "postgresql://postgres:postgres@localhost:5432/postgres"

    func testPGConnectionBad() {
        let badInfo = "postgresql://postgres:postgres@localhost/badDB"
        guard let conn = try? PGConnection(info: badInfo) else {
            XCTFail("Failed to create PGConnection instance")
            return
        }
        let status = try? conn.status()
        XCTAssertEqual(status, PGConnStatus.bad)
        guard conn.errorMessage() != nil else {
            XCTFail("Missing error message")
            return
        }
    }

    func testPGConnection() {
        guard let conn = try? PGConnection(info: connInfo) else {
            XCTFail("Failed to create PGConnection instance")
            return
        }
        let status = try? conn.status()
        XCTAssertEqual(status, PGConnStatus.ok)
        XCTAssert(conn.socket >= 0)

        XCTAssertEqual(conn.userName, "postgres")
        XCTAssertEqual(conn.password, "postgres")
        XCTAssertEqual(conn.hostName, "localhost")
        XCTAssertEqual(conn.port, "5432")
        XCTAssertEqual(conn.databaseName, "postgres")
    }

    static var allTests = [
        ("testPGConnectionBad", testPGConnectionBad),
        ("testPGConnection", testPGConnection),
    ]
}
