import postgresql_swift
import Foundation

/*
 Inspired by testlibpq.c - Test the C version of libpq, the PostgreSQL frontend library.
 */

extension String {
    // A simple extension to keep string length to be 15 characters (or greater).
    // This should be enough for case.
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
    case okConnection(reason: String)
    case okCommand(reason: String)
    case tuplesOKCommand(reason: String)
}

func printError(exampleError error: ExampleError) {
    switch error {
    case .okConnection(let reason):
        print("Connection Not OK: \(reason)")
    case .okCommand(let reason):
        print("Command Not OK: \(reason)")
    case .tuplesOKCommand(let reason):
        print("Tuples Not OK: \(reason)")
    }
}

func ensureConnectionOK(connection conn: PGConnection) throws {
    let status = try? conn.status()
    if status != PGConnStatus.ok {
        // FIXME status ...
        let msg = conn.errorMessage() ?? "MISSING ERROR MESSAGE"
        throw ExampleError.okConnection(reason: msg)
    }
}

func ensureCommandOK(result: PGResult) throws {
    let status = result.status
    if status != PGResultStatus.commandOK {
        // FIXME status ...
        let msg = result.errorMessage ?? "MISSING RESULT ERROR MESSAGE"
        throw ExampleError.okCommand(reason: msg)
    }
}

func ensureCommandTuplesOK(result: PGResult) throws {
    let status = result.status
    if status != PGResultStatus.tuplesOK {
        // FIXME status ...
        let msg = result.errorMessage ?? "MISSING RESULT ERROR MESSAGE"
        throw ExampleError.tuplesOKCommand(reason: msg)
    }
}

do {
    // Our default connection info string
    let connInfo = "postgresql://postgres@localhost:5432/postgres"

    // Make a connection to the database
    let conn = try PGConnection(info: connInfo)

    // Check to see that the backend connection was successfully made
    try ensureConnectionOK(connection: conn)

    // Our test case here involves using a cursor, for which we must be inside a
    // transaction block. We could do the whole thing with a single `exec()` of
    // `select * from pg_database`, but that's too trivial to make a good example.

    // Start a transaction block
    var res = try conn.exec(statement: "BEGIN")
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
    printError(exampleError: error)
    exit(1)
} catch {
    print("Something going wrong")
    exit(1)
}
