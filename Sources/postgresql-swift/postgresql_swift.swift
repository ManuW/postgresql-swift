import CLibpq
import Foundation

/// PostgreSQL swift adapter
///
/// More or less comments are take from PostgreSQL documentation
/// https://www.postgresql.org/docs/10/static/libpq.html

/**
 Return the version of libpq that is being used.

 - Returns: The major, submajor and minor number

 - Note: See PGlibRawVersion() for details

 Example version 10.1  -> 100001 -> major: 10, submajor: 0, minor: 1<br/>
 Example version 11.0  -> 110000 -> major: 11, submajor: 0, minor: 0<br/>
 Example version 9.2.0 ->  90200 -> major:  9, submajor: 2: minor: 0<br/>
 Example version 9.1.5 ->  90105 -> major:  9, submajor: 1, minor: 5
 */
public func PGlibVersion() -> (major: Int, submajor: Int, minor: Int) {
    let version = Int(PGlibRawVersion())
    let major = version / 10000
    let submajor = (version / 100) % 100
    let minor = version % 100
    return (major: major, submajor: submajor, minor: minor)
}

/**
 Return the version of libpq that is being used.

 The result of this function can be used to determine, at run time, whether specific
 functionality is available in the currently loaded version of libpq. The function
 can be used, for example, to determine which connection options are available in
 PQconnectdb.

 The result is formed by multiplying the library's major version number by 10000
 and adding the minor version number. For example, version 10.1 will be returned
 as 100001, and version 11.0 will be returned as 110000.

 Prior to major version 10, PostgreSQL used three-part version numbers in which
 the first two parts together represented the major version. For those versions,
 PQlibVersion uses two digits for each part; for example version 9.1.5 will be
 returned as 90105, and version 9.2.0 will be returned as 90200.

 Therefore, for purposes of determining feature compatibility, applications should
 divide the result of PQlibVersion by 100 not 10000 to determine a logical major
 version number. In all release series, only the last two digits differ between
 minor releases (bug-fix releases).
 */
public func PGlibRawVersion() -> Int32 {
    let version = PQlibVersion()
    return version
}


public enum PGError: Error {
    case fatal
    case unexpectedResult
    case invalidConnStatus
    case sendQueryError(reason: String)
    case consumeInputError(reason: String)
}


/**
 PGConn Status Enumeration Adapter

 *Values*

 `ok` Connection is ready

 `bad` Connection procedure has failed

 `started` Waiting for connection to be made.

 `made` Connection OK; waiting to send.

 `awaitingRsponse` Waiting for a response from the postmaster.

 `authenticationOk` Received authentication; waiting for backend startup.

 `setenv` Negotiating environment-driven parameter settings.

 `sslStartup` Negotiating SSL encryption.

 `needed` Internal state: connect() needed

 `checkWritable` Checking if connection is able to handle write transactions.

 `consume` Consuming any remaining response messages on connection.

 Outside of an asynchronous connection procedure only `ok` and `bad` are seen.
 */
public enum PGConnStatus {
    
    /// Connection is ready
    case ok
    
    /// Connection procedure has failed
    case bad
    
    // Non-blocking mode only below here
    // The existence of these should never be relied upon - they should only
    // be used for user feedback or similar purposes.
    
    /// Waiting for connection to be made.
    case started
    
    /// Connection OK; waiting to send.
    case made
    
    /// Waiting for a response from the postmaster.
    case awaitingRsponse
    
    /// Waiting for a response from the postmaster.
    case authenticationOk
    
    /// Received authentication; waiting for backend startup.
    case setenv
    
    /// Negotiating SSL encryption.
    case sslStartup
    
    /// Internal state: connect() needed
    case needed
    
    /// Checking if connection is able to handle write transactions.
    case checkWritable
    
    /// Consuming any remaining response messages on connection.
    case consume

    /// Returns the converted status or nil if the status is not valid.
    init?(pgStatus: ConnStatusType) {
        switch pgStatus.rawValue {
        case CONNECTION_OK.rawValue:
            self = .ok
        case CONNECTION_BAD.rawValue:
            self = .bad
        case CONNECTION_STARTED.rawValue:
            self = .started
        case CONNECTION_MADE.rawValue:
            self = .made
        case CONNECTION_AWAITING_RESPONSE.rawValue:
            self = .awaitingRsponse
        case CONNECTION_AUTH_OK.rawValue:
            self = .authenticationOk
        case CONNECTION_SETENV.rawValue:
            self = .setenv
        case CONNECTION_SSL_STARTUP.rawValue:
            self = .sslStartup
        case CONNECTION_NEEDED.rawValue:
            self = .needed
        case CONNECTION_CHECK_WRITABLE.rawValue:
            self = .checkWritable
        case CONNECTION_CONSUME.rawValue:
            self = .consume
        default:
            return nil
        }
    }
}

extension PGConnStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .ok:
            return "Connection is ready"
        case .bad:
            return "Connection procedure has failed"
        case .started:
            return "Waiting for  connection to be made."
        case .made:
            return "Conneciton OK; waiting to send."
        case .awaitingRsponse:
            return "Waiting for a response from the postmaster."
        case .authenticationOk:
            return "Waiting for a response from the postmaster."
        case .setenv:
            return "Received authentication; waiting for backend startup."
        case .sslStartup:
            return "Negotiating SSL encryption."
        case .needed:
            return "Internal state: connect() needed"
        case .checkWritable:
            return "Checking if connection is able to handle write transactions."
        case .consume:
            return "Consuming any remaining response messages on connection."
        }
    }
}

/**
 In-transaction status

 *values*

 `idle` currently idle

 `active` a command is in progress
 
 Is reported only when a query has been sent to the server and not yet completed.

 `idleTransaction` idle, in a valid transaction block

 `idleFailedTransaction` idle, in a failed transaction block

 `unkown` is reported if the connection is bad
 */
public enum PGTransactionStatus {
    
    /// currently idle
    case idle
    
    /// a command is in progress
    ///
    /// Is reported only when a query has been sent to the server and not yet completed.
    case active
    
    ///  idle, in a valid transaction block
    case idleTransaction
    
    /// idle, in a failed transaction block
    case idleFailedTransaction
    
    /// is reported if the connection is bad
    case unkown

    init?(transStatus: PGTransactionStatusType) {
        switch transStatus.rawValue {
        case PQTRANS_IDLE.rawValue:
            self = .idle
        case PQTRANS_ACTIVE.rawValue:
            self = .active
        case PQTRANS_INTRANS.rawValue:
            self = .idleTransaction
        case PQTRANS_INERROR.rawValue:
            self = .idleFailedTransaction
        case PQTRANS_UNKNOWN.rawValue:
            self = .unkown
        default:
            return nil
        }
    }
}

/**
 Result Status

 *values*

 `emptyQuery` The string sent to the server was empty.

 `commandOK` Successful completion of a command returning no data.

 `tuplesOK` Successful completion of a command returning data (such as a SELECT or SHOW).

 `copyOut` Copy Out (from server) data transfer started.

 `copyIn` Copy In (to server) data transfer started.

 `badResponse` The server's response was not understood.

 `nonfatalError` A nonfatal error (a notice or warning) occurred.

 `fatalError` A fatal error occurred.

 `copyBoth` Copy In/Out (to and from server) data transfer started.
 This feature is currently used only for streaming replication, so this status
 should not occur in ordinary applications.

 `singleTuple` The PGresult contains a single result tuple from the current command.
 This status occurs only when single-row mode has been selected for the query
 */
public enum PGResultStatus {
    case emptyQuery
    case commandOK
    case tuplesOK
    case copyOut
    case copyIn
    case badResponse
    case nonfatalError
    case fatalError
    case copyBoth
    case singleTuple

    init?(execStatus: ExecStatusType) {
        switch execStatus.rawValue {
        case PGRES_EMPTY_QUERY.rawValue:
            self = .emptyQuery
        case PGRES_COMMAND_OK.rawValue:
            self = .commandOK
        case PGRES_TUPLES_OK.rawValue:
            self = .tuplesOK
        case PGRES_COPY_OUT.rawValue:
            self = .copyOut
        case PGRES_COPY_IN.rawValue:
            self = .copyIn
        case PGRES_BAD_RESPONSE.rawValue:
            self = .badResponse
        case PGRES_NONFATAL_ERROR.rawValue:
            self = .nonfatalError
        case PGRES_FATAL_ERROR.rawValue:
            self = .fatalError
        case PGRES_COPY_BOTH.rawValue:
            self = .copyBoth
        case PGRES_SINGLE_TUPLE.rawValue:
            self = .singleTuple
        default:
            return nil
        }
    }
}

extension PGResultStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .emptyQuery:
            return "Empty Query"
        case .commandOK:
            return "Command OK"
        case .tuplesOK:
            return "Tuples OK"
        case .copyOut:
            return "Copy Out"
        case .copyIn:
            return "Copy In"
        case .badResponse:
            return "Bad Response"
        case .nonfatalError:
            return "Non Fatal Error"
        case .fatalError:
            return "Fatal Error"
        case .copyBoth:
            return "Copy Both"
        case .singleTuple:
            return "Single Tuple"
        }
    }
}

extension PGResultStatus: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .emptyQuery:
            return "Empty Query: The string sent to the server was empty"
        case .commandOK:
            return "Command OK: Successful completion of a command returning no data"
        case .tuplesOK:
            return "Tuples OK: Successful completion of a command returning data (such as a SELECT or SHOW)"
        case .copyOut:
            return "Copy Out: Copy Out (from server) data transfer started"
        case .copyIn:
            return "Copy In: Copy In (to server) data transfer started"
        case .badResponse:
            return "Bad Response: The server's response was not understood"
        case .nonfatalError:
            return "Non Fatal Error: A nonfatal error (a notice or warning) occurred"
        case .fatalError:
            return "Fatal Error: A fatal error occurred"
        case .copyBoth:
            return "Copy Both: Copy In/Out (to and from server) data transfer started"
        case .singleTuple:
            return "Single Tuple: The PGresult contains a single result tuple from the current command"
        }
    }
}

public final class PGResult {

    /// The result pointer
    let pgResult: OpaquePointer

    /// Init with an valid result pointer
    public init(result: OpaquePointer) {
        pgResult = result
    }

    /// Frees the storage associated with a PGresult.
    deinit {
        clear()
    }

    /**
     Frees the storage associated with a PGresult.

     You can keep a PGresult object around for as long as you need it; it does not
     go away when you issue a new command, nor even if you close the connection.
     To get rid of it, you must call PQclear. Failure to do this will result in
     memory leaks in your application.
     */
    private func clear() {
        PQclear(pgResult)
    }

    /// Raw result status of the command
    public lazy var rawStatus: ExecStatusType = {
        return PQresultStatus(pgResult)
    }()

    /// Result status of the command
    public lazy var status: PGResultStatus? = {
        return PGResultStatus(execStatus: rawStatus)
    }()

    /// Readable result status of the command
    public lazy var statusString: String? = {
        guard let str = PQresStatus(rawStatus) else {
            return nil
        }
        return String(cString: str)
    }()

    /**
     Error message associated with the command, or nil if there was no error or
     the returned error message is empty.
     
     If there was an error, the returned string will include a trailing newline.
    */
    public lazy var errorMessage: String? = {
        guard let msg = PQresultErrorMessage(pgResult) else {
            return nil
        }
        let str = String(cString: msg)
        if str.isEmpty {
            return nil
        }
        return str
    }()

    /// Number of rows (tuples) in the query result.
    public lazy var numberOfRows: Int32 = {
        let nTuples = PQntuples(pgResult)
        return nTuples
    }()

    /// Number of columns (fields) in each row of the query result.
    public lazy var numberOfColumns: Int32 = {
        let nFields = PQnfields(pgResult)
        return nFields
    }()

    /**
     Returns the column name associated with the given column number.

     Column numbers start at 0. The caller should not free the result directly.
     nil is returned if the column number is out of range.
     */
    public func columnName(columnNumber: Int32) -> String? {
        guard let name = PQfname(pgResult, columnNumber) else {
            return nil
        }
        return String(cString: name)
    }

    /**
     Returns the column number associated with the given column name.

     -1 is returned if the given name does not match any column.

     The given name is treated like an identifier in an SQL command, that is, it
     is downcased unless double-quoted. For example, given a query result generated
     from the SQL command:

        `SELECT 1 AS FOO, 2 AS "BAR";`

     we would have the results:

        `columnName(0) -> foo`

        `columnName(1) -> BAR`

        `columnNumber("FOO") -> 0  `

        `columnNumber("foo") -> 0  `

        `columnNumber("BAR") -> -1  `

        `columnNumber("\"BAR\"") -> 1  `
     */
    public func columnNumber(columnName: String) -> Int32 {
        let number = PQfnumber(pgResult, columnName)
        return number
    }

    /**
     Returns the OID of the table from which the given column was fetched.

     Column numbers start at 0. InvalidOid is returned if the column number is
     out of range, or if the specified column is not a simple reference to a table
     column, or when using pre-3.0 protocol. You can query the system table
     pg_class to determine exactly which table is referenced.
     */
    public func columnOid(columnNumber: Int32) -> Oid {
        let oid = PQftable(pgResult, columnNumber)
        return oid
    }

    /**
     Returns the column number (within its table) of the column making up the specified query result column.

     Query-result column numbers start at 0, but table columns have nonzero numbers.
     Zero is returned if the column number is out of range, or if the specified
     column is not a simple reference to a table column, or when using pre-3.0 protocol.
     */
    public func tableColumnNumber(columnNumber: Int32) -> Int32 {
        let number = PQftablecol(pgResult, columnNumber)
        return number
    }

    /**
     Returns the format code indicating the format of the given column.

     Column numbers start at 0. Format code zero indicates textual data representation,
     while format code one indicates binary representation. (Other codes are reserved
     for future definition.)
     */
    public func formatCode(columnNumber: Int32) -> Int32 {
        let code = PQfformat(pgResult, columnNumber)
        return code
    }

    /**
     Returns the data type associated with the given column number.

     The integer returned is the internal OID number of the type. Column numbers
     start at 0. You can query the system table pg_type to obtain the names and
     properties of the various data types. The OIDs of the built-in data types
     are defined in the file src/include/catalog/pg_type.h in the source tree.
     */
    public func dataType(columnNumber: Int32) -> Oid {
        let type = PQftype(pgResult, columnNumber)
        return type
    }

    /**
     Returns the type modifier of the column associated with the given column number.

     Column numbers start at 0. The interpretation of modifier values is type-specific;
     they typically indicate precision or size limits. The value -1 is used to
     indicate “no information available”. Most data types do not use modifiers,
     in which case the value is always -1.
     */
    public func typeModifier(columnNumber: Int32) -> Int32 {
        let modifier = PQfmod(pgResult, columnNumber)
        return modifier
    }

    /**
     Returns the size in bytes of the column associated with the given column number.

     Column numbers start at 0. PQfsize returns the space allocated for this column
     in a database row, in other words the size of the server's internal representation
     of the data type. (Accordingly, it is not really very useful to clients.) A
     negative value indicates the data type is variable-length.
     */
    public func columnSize(columnNumber: Int32) -> Int32 {
        let size = PQfsize(pgResult, columnNumber)
        return size
    }

    /**
     Returns a single field value of one row of a PGresult.

     Row and column numbers start at 0.

     `nil` is returned if the field value is null. See `getIsNil()` to distinguish
     null values from empty-string values.
     */
    private func value(rowNumber: Int32, columnNumber: Int32) -> UnsafeMutablePointer<Int8>? {
        let value = PQgetvalue(pgResult, rowNumber, columnNumber)
        return value
    }

    public func stringValue(rowNumber row: Int32, columnNumber column: Int32) -> String? {
        guard let val = value(rowNumber: row, columnNumber: column) else {
            return nil
        }
        return String(cString: val)
    }

    /**
     Tests a field for a null value.

     Row and column numbers start at 0. This function returns `true` if the field
     is `nil` and `false` if it contains a non-null value. (Note that `value()`
     will return an empty string, not nil, for a nil field.)
    */
    public func isNil(rowNumber: Int32, columnNumber: Int32) -> Bool {
        let isNull = PQgetisnull(pgResult, rowNumber, columnNumber)
        return (isNull == 1)
    }

    /**
     Returns the actual length of a field value in bytes.

     Row and column numbers start at 0. This is the actual data length for the
     particular data value, that is, the size of the object pointed to by `value()`.
     For text data format this is the same as `strlen()`. For binary format this
     is essential information. Note that one should not rely on `columnSize()` to
     obtain the actual data length.
     */
    public func length(rowNumber: Int32, columnNumber: Int32) -> Int32 {
        let length = PQgetlength(pgResult, rowNumber, columnNumber)
        return length
    }

    /**
     Number of parameters of a prepared statement.

     This property is only useful when inspecting the result of
     `describePrepared()`. For other types of queries it will return zero.
     */
    public lazy var numberOfParameter: Int32 = {
        let number = PQnparams(pgResult)
        return number
    } ()

    /**
     Returns the data type of the indicated statement parameter.

     Parameter numbers start at 0. This function is only useful when inspecting
     the result of `describePrepared()`. For other types of queries it will return zero.
     */
    public func dataType(parameterNumber: Int32) -> Oid {
        let type = PQparamtype(pgResult, parameterNumber)
        return type
    }
}

/// PGNotify class
public final class PGNotify {

    private let notify: UnsafeMutablePointer<PGnotify>

    init(_ notify: UnsafeMutablePointer<PGnotify>) {
        self.notify = notify
    }

    deinit {
        clean()
    }

    private func clean() {
        PQfreemem(notify)
    }

    public lazy var channel: String? = {
        guard let relname = notify.pointee.relname else {
            return nil
        }
        return String(cString: relname)
    }()

    public lazy var pid: Int32 = {
        return notify.pointee.be_pid
    }()

    public lazy var payload: String? = {
        guard let extra = notify.pointee.extra else {
            return nil
        }
        return String(cString: extra)
    }()
}

/// Class to handle PGconn object
public final class PGConnection {

    /// Pointer to PGconn object that encapsulates a connection to the backend.
    let pgConn: OpaquePointer

    /**
     Makes a new connection to the database server.

     - Parameter info: PostgreSQL Connection String.
     The passed string can be empty to use all default parameters, or it can
     contain one or more parameter settings separated by whitespace,
     or it can contain a URI.

     - Throws: PGError.unexpectedResult if there is too litte memory to allocate.
     */
    public init(info: String) throws {
        guard let conn = PQconnectdb(info) else {
            throw PGError.unexpectedResult
        }
        pgConn = conn
    }

    deinit {
        finish()
    }

    /**
     Closes the connection to the server. Also frees memory used by the PGconn object.

     Note that even if the server connection attempt fails (as indicated by status()),
     the application should call finish() to free the memory used by the PGconn object.
     The PGconn pointer must not be used again after finish() has been called.
     */
    private func finish() {
        PQfinish(pgConn)
    }

    /**
     Status of the connection

     - Returns: status of the connection

     - Throws: PGError.invalidConnStatus if the status is not valid

     At any time during connection, the status of the connection can be checked
     by calling status(). If this call returns PGConnStatus.bad, then the connection
     procedure has failed; if the call returns PGConnStatus.ok, then the connection
     is ready. Other states might also occur during (and only during) an asynchronous
     connection procedure. These indicate the current stage of the connection
     procedure and might be useful to provide feedback to the user for example.
     */
    public func status() throws -> PGConnStatus {
        guard let status = PGConnStatus(pgStatus: PQstatus(pgConn)) else {
            throw PGError.invalidConnStatus
        }
        return status
    }

    /**
     Resets the communication channel to the server.

     This function will close the connection to the server and attempt to reestablish
     a new connection to the same server, using all the same parameters previously
     used. This might be useful for error recovery if a working connection is lost.
     */
    public func reset() {
        PQreset(pgConn)
    }

    /// Database name of the connection.
    public lazy var databaseName: String? = {
        guard let name = PQdb(pgConn) else {
            return nil
        }
        return String(cString: name)
    }()

    /// User name of the connection.
    public lazy var userName: String? = {
        guard let name = PQuser(pgConn) else {
            return nil
        }
        return String(cString: name)
    }()

    /// Password of the connection.
    public var password: String? {
        guard let passwd = PQpass(pgConn) else {
            return nil
        }
        return String(cString: passwd)
    }

    /// Server host name of the connection.
    ///
    /// This can be a host name, an IP address, or a directory path if the
    /// connection is via Unix socket. (The path case can be distinguished
    /// because it will always be an absolute path, beginning with /.)
    public var hostName: String? {
        guard let host = PQhost(pgConn) else {
            return nil
        }
        return String(cString: host)
    }

    /// Port of the connection.
    public var port: String? {
        guard let port = PQport(pgConn) else {
            return nil
        }
        return String(cString: port)
    }

    /// Command-line options passed in the connection request.
    public lazy var commandLineOptions: String? = {
        guard let options = PQoptions(pgConn) else {
            return nil
        }
        return String(cString: options)
    }()

    /// Returns the current in-transaction status of the server.
    public func transactionStatus() -> PGTransactionStatus? {
        let status = PQtransactionStatus(pgConn)
        return PGTransactionStatus(transStatus: status)
    }

    /// TODO: Implement PQparameterStatus

    /**
     Interrogates the frontend/backend protocol being used.

     Applications might wish to use this function to determine whether certain
     features are supported. Currently, the possible values are 2 (2.0 protocol),
     3 (3.0 protocol), or zero (connection bad). The protocol version will not change
     after connection startup is complete, but it could theoretically change during
     a connection reset. The 3.0 protocol will normally be used when communicating
     with PostgreSQL 7.4 or later servers; pre-7.4 servers support only protocol 2.0.
     (Protocol 1.0 is obsolete and not supported by libpq.)
     */
    public var protocolVersion: Int32 {
        let version = PQprotocolVersion(pgConn)
        return version
    }

    /**
     Returns an integer representing the server version.

     - Returns: The major, submajor and minor number

     - Note: See rawServerVersion() for details

     Example version 10.1  -> 100001 -> major: 10, submajor: 0, minor: 1
     Example version 11.0  -> 110000 -> major: 11, submajor: 0, minor: 0
     Example version 9.2.0 ->  90200 -> major:  9, submajor: 2: minor: 0
     Example version 9.1.5 ->  90105 -> major:  9, submajor: 1, minor: 5
     */
    public var serverVersion: (major: Int, submajor: Int, minor: Int) {
        let version = Int(rawServerVersion)
        let major = version / 10000
        let submajor = (version / 100) % 100
        let minor = version % 100
        return (major: major, submajor: submajor, minor: minor)
    }

    /**
     Returns the server version number.

     Applications might use this function to determine the version of the database
     server they are connected to. The result is formed by multiplying the server's
     major version number by `10000` and adding the minor version number. For example,
     version 10.1 will be returned as `100001`, and version 11.0 will be returned as
     `110000`. Zero is returned if the connection is bad.

     Prior to major version 10, PostgreSQL used three-part version numbers in which
     the first two parts together represented the major version. For those versions,
     serverVersion() uses two digits for each part; for example version 9.1.5 will
     be returned as `90105`, and version 9.2.0 will be returned as 90200.

     Therefore, for purposes of determining feature compatibility, applications
     should divide the result of serverVersion() by `100` not `10000` to determine a
     logical major version number. In all release series, only the last two digits
     differ between minor releases (bug-fix releases).
     */
    public var rawServerVersion: Int32 {
        let version = PQserverVersion(pgConn)
        return version
    }

    /**
     Returns the error message most recently generated by an operation on the connection.

     - Returns: Error message

     Nearly all libpq functions will set a message for PQerrorMessage if they
     fail. Note that by libpq convention, a nonempty PQerrorMessage result can
     consist of multiple lines, and will include a trailing newline.
     */
    public func errorMessage() -> String? {
        guard let msg = PQerrorMessage(pgConn) else {
            return nil
        }
        return String(cString: msg)
    }

    /**
     Obtains the file descriptor number of the connection socket to the server.

     - Returns: The file descriptor

     A valid descriptor will be greater than or equal to 0; a result of -1 indicates
     that no server connection is currently open. (This will not change during
     normal operation, but could change during connection setup or reset.)
     */
    public var socket: Int32 {
        let sock = PQsocket(pgConn)
        return sock
    }

    /**
     The process ID (PID) of the backend process handling this connection.

     - Returns: process ID

     The backend PID is useful for debugging purposes and for comparison to
     NOTIFY messages (which include the PID of the notifying backend process).
     Note that the PID belongs to a process executing on the database server
     host, not the local host!
     */
    public var backendPid: Int32 {
        let pid = PQbackendPID(pgConn)
        return pid
    }

    /// True if the connection authentication method required a password, but none was available
    public var connectionNeedsPassword: Bool {
        let needsPasswd = PQconnectionNeedsPassword(pgConn)
        return needsPasswd == 1 // true (1), false (0) if not
    }

    /// True if connections uses SSL.
    public var sslInUse: Bool {
        let inUse = PQsslInUse(pgConn)
        return inUse == 1 // true (1), false (0) if not
    }

    /**
     Submits a command to the server and waits for the result.
 
     - Returns: A PGResult object.
     
     - Throws: PGError.fatal after out-of-memory conditions or serious errors such
     as inability to send the command to the server.
     
     The result status should be checked for any errors. Use result errorMessage
     to get more information about such errors.
     
     The command string can include multiple SQL commands (separated by semicolons).
     Multiple queries sent in a single exec() call are processed in a single transaction,
     unless there are explicit BEGIN/COMMIT commands included in the query string
     to divide it into multiple transactions. Note however that the returned PGResult
     object describes only the result of the last command executed from the string.
     Should one of the commands fail, processing of the string stops with it and
     the returned PGResult describes the error condition.
    */
    @discardableResult
    public func exec(statement: String) throws -> PGResult {
        guard let result = PQexec(pgConn, statement) else {
            throw PGError.fatal
        }
        return PGResult(result: result)
    }

    /**
     Submits a command to the server without waiting for the result(s).

     After successfully calling sendQuery(), call result() one or more times to
     obtain the results. sendQuery() cannot be called again (on the same connection)
     until getResult() has returned nil, indicating that the command is done.
     */
    public func sendQuery(statement: String) throws {
        guard PQsendQuery(pgConn, statement) == 1 else {
            let msg = errorMessage() ?? "SEND QUERY FAILED WITHOUT ANY ERROR MESSAGE"
            throw PGError.sendQueryError(reason: msg)
        }
    }

    /**
     Waits for the next result.

     Nil is returned when the command is complete and there will be no more results.
     */
    public func result() -> PGResult? {
        guard let result = PQgetResult(pgConn) else {
            return nil
        }
        return PGResult(result: result)
    }

    /// Waits for the next result and returns all result(s).
    public func allResults() -> [PGResult] {
        var results = [PGResult]()
        while let res = result() {
            results.append(res)
        }
        return results
    }

    public func eachResult(_ handle: (PGResult) -> Void) {
        while let res = result() {
            handle(res)
        }
    }

    /// If input is available from the server, consume it.
    ///
    /// If there was some kind of trouble consumeInput() throws PostgreSQLError.
    /// A successful return does not say whether any input data was actually
    /// collected. After calling consumeInput(), the application can check
    /// isBusy() and/or notifies() to see if their state has changed.
    public func consumeInput() throws {
        guard PQconsumeInput(pgConn) == 1 else {
            let msg = errorMessage() ?? "CONSUME INPUT FAILED WITHOUT ANY ERROR MESSAGE"
            throw PGError.consumeInputError(reason: msg)
        }
    }

    /// Returns true if a command is busy.
    ///
    /// Busy means, getResult() would block waiting for input. false indicates
    /// that getResult() can be called with assurance of not blocking. isBusy()
    /// will not itself attempt to read data from the server; therefore
    /// consumeInput() must be invoked first, or the busy state will never end.
    public func isBusy() -> Bool {
        let busy = PQisBusy(pgConn)
        return (busy == 1)
    }

    /// notifies() returns the next notification from a list of unhandled
    /// notification messages received from the server.
    ///
    /// It returns nil if there are no pending notifications. Once a notification
    /// is returned from notifies(), it is considered handled and will be removed
    /// from the list of notifications.
    public func nextNotification() -> PGNotify? {
        guard let notify = PQnotifies(pgConn) else {
            return nil
        }
        return PGNotify(notify)
    }

    public func eachNotification(_ handle: (PGNotify) -> Void) {
        while let notify = nextNotification() {
            handle(notify)
        }
    }

    // MARK: Control Functions

    // These functions control miscellaneous details of libpq's behavior.

    /**
     Returns the client encoding.

     Note that it returns the encoding ID, not a symbolic string such as EUC_JP.
     If unsuccessful, it returns -1.
     */
    public var rawClientEncoding: Int32 {
        let encoding = PQclientEncoding(pgConn)
        return encoding
    }

    /**
     Returns the client encoding as String.
     */
    public var clientEncoding: String? {
        guard let encoding = pg_encoding_to_char(rawClientEncoding) else {
            return nil
        }
        return String(cString: encoding)
    }

    /**
     Enables tracing of the client/server communication to a debugging file stream.
     */
    public func trace(stream: UnsafeMutablePointer<FILE>) {
        PQtrace(pgConn, stream)
    }

    /**
     Disables tracing started by PQtrace.
    */
    public func untrace() {
        PQuntrace(pgConn)
    }

}

