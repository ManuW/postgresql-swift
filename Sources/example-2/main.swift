import postgresql_swift
import Foundation

/*
 Inspired by testlibpq2.c - Test of the asynchronous notification interface

 We are using poll() instead of select() because it is simpler to use and
 Swift does not support C marcros like FD_SET or FD_ZERO.

 Start this program, then from psql in another window do
    NOTIFY TBL2, 'some payload';
 Repeat four times to get this program to exit.

 Or, if you want to get fancy, try this:
 populate a database with the following commands
    CREATE TABLE TBL1 (i int4);

    CREATE TABLE TBL2 (i int4);

    CREATE RULE r1 AS ON INSERT TO TBL1 DO
      (INSERT INTO TBL2 VALUES (new.i); NOTIFY TBL2);

 and do this four times:
    INSERT INTO TBL1 VALUES (10);
 */

extension String {
    init?(errnum: Int32) {
        guard let str = strerror(errnum) else {
            return nil
        }
        self = String(cString: str)
    }
}


enum ExampleError: Error {
    case okConnection(reason: String)
    case okCommand(reason: String)
    case pollFailed
}

func printError(exampleError error: ExampleError) {
    switch error {
    case .okConnection(let reason):
        print("Connection Not OK: \(reason)")
    case .okCommand(let reason):
        print("Command Not OK: \(reason)")
    case .pollFailed:
        print("poll() failed")
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

func ensurePollSucceeded(success: Int32) throws {
    if success == -1 {
        print("errno \(errno): \(String(errnum: errno) ?? "")")
        throw ExampleError.pollFailed
    }
}

do {
    // Our default connection info string
    let connInfo = "postgresql://postgres@localhost:5432/postgres"

    // Make a connection to the database
    let conn = try PGConnection(info: connInfo)

    // Check to see that the backend connection was successfully made
    try ensureConnectionOK(connection: conn)

    // Issue LISTEN command to enable notifications from the rule's NOTIFY.
    let res = try conn.exec(statement: "LISTEN TBL2")
    try ensureCommandOK(result: res)

    // Create file descriptor array
    var fds = [pollfd()]
    fds[0].fd = conn.socket
    fds[0].events = Int16(POLLIN)

    // Quit after four notifies are received.
    var count = 1
    while count < 5 {
        print("Waiting (\(count))")
        let readyFDs = poll(&fds, UInt32(fds.count), -1)
        try ensurePollSucceeded(success: readyFDs)
        if readyFDs > 0 {
            try conn.consumeInput()
            // Iterate through all available notifications
            conn.eachNotification({(notify: PGNotify) -> Void in
                let channel = notify.channel ?? "MISSING CHANNEL"
                let pid = notify.pid
                print("ASYNC NOTIFY of \(channel) received from backend PID \(pid)")
                if let payload = notify.payload {
                    print("  with payload: \(payload)")
                }
            })
            count += 1
        }
    }

} catch let error as ExampleError {
    printError(exampleError: error)
    exit(1)
} catch {
    print("Something going wrong")
    exit(1)
}
