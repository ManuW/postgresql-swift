import postgresql_swift
import Foundation

/*
 Inspired by testlibpq.c - Test the C version of libpq, the PostgreSQL frontend library.
 */

extension String {
    // A simple extension to keep string length to be 15 characters (or greater).
    // That should be enough in this case.
    func appendPadding() -> String {
        let toLength = 15
        let length = self.count
        if length < toLength {
            return self + String(repeatElement(" ", count: toLength - length))
        }
        return self
    }
}


enum ExampleError: Error {
    case notOkConnection(reason: String)
    case notOkCommand(reason: String)
    case tuplesNotOkCommand(reason: String)
}

func printError(_ error: ExampleError) {
    switch error {
    case .notOkConnection(let reason):
        print("Connection Not OK: \(reason)")
    case .notOkCommand(let reason):
        print("Command Not OK: \(reason)")
    case .tuplesNotOkCommand(let reason):
        print("Tuples Not OK: \(reason)")
    }
}

func ensureConnectionOK(connection conn: PGConnection) throws {
    let status = try? conn.status()
    if status != PGConnStatus.ok {
        let description = status?.description ?? "nil"
        debugPrint("Result Status: Not equal to connection ok ~ \(description)")
        let msg = conn.errorMessage() ?? "MISSING ERROR MESSAGE"
        throw ExampleError.notOkConnection(reason: msg)
    }
}

func ensureCommandOK(result: PGResult) throws {
    let status = result.status
    if status != PGResultStatus.commandOK {
        let description = status?.description ?? "nil"
        debugPrint("Result Status: Not equal to command ok ~ \(description)")
        let msg = result.errorMessage ?? "MISSING RESULT ERROR MESSAGE"
        throw ExampleError.notOkCommand(reason: msg)
    }
}

func ensureCommandTuplesOK(result: PGResult) throws {
    let status = result.status
    if status != PGResultStatus.tuplesOK {
        let description = status?.description ?? "nil"
        debugPrint("Result Status: Not equal to tuples ok ~ \(description)")
        let msg = result.errorMessage ?? "MISSING RESULT ERROR MESSAGE"
        throw ExampleError.tuplesNotOkCommand(reason: msg)
    }
}

do {
    // Our default connection info string
    let connInfo = "postgresql://postgres@localhost:5432/postgres"

    // Make a PGConnection object to our database
    let conn = try PGConnection(info: connInfo)

    // Check to see that the backend connection was successfully made
    try ensureConnectionOK(connection: conn)

    // Set always-secure search path, so malicous users can't take control.
    var res = try conn.exec(statement: "SELECT pg_catalog.set_config('search_path', '', false)")
    try ensureCommandOK(result: res)

    // Our test case here involves using a cursor, for which we must be inside a
    // transaction block. We could do the whole thing with a single `exec()` of
    // `select * from pg_database`, but that's too trivial to make a good example.

    // Start a transaction block
    res = try conn.exec(statement: "BEGIN")
    try ensureCommandOK(result: res)

    // Fetch rows from pg_database, the system catalog of databases
    res = try conn.exec(statement: "DECLARE myportal CURSOR FOR select * from pg_database")
    try ensureCommandOK(result: res)

    res = try conn.exec(statement: "FETCH ALL in myportal")
    try ensureCommandTuplesOK(result: res)

    // Print out the attribute names
    for column in 0..<res.numberOfColumns {
        let name = res.columnName(columnNumber: column) ?? "---"
        let formatedName = name.appendPadding()
        print(formatedName, terminator: "")
    }
    print("\n")

    // Print out the rows
    for row in 0..<res.numberOfRows {
        for column in 0..<res.numberOfColumns {
            let val = res.stringValue(rowNumber: row, columnNumber: column) ?? "---"
            let formatedVal = val.appendPadding()
            print(formatedVal, terminator: "")
        }
        print("\n")
    }

    // Close the portal ... we don't bother to check for errors ...
    try conn.exec(statement: "CLOSE myportal")

    // End the transaction
    try conn.exec(statement: "END")

} catch let error as ExampleError {
    printError(error)
    exit(1)
} catch {
    print("Something going wrong")
    exit(1)
}
