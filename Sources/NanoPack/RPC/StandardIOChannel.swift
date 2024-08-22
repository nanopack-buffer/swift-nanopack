import Foundation

/// A channel that handles RPC traffic to a process via stdin and stdout.
/// You can make RPC calls to a process over stdio using this channel.
///
/// You can make RPC calls to a running process over stdio using this channel.
/// This channel is usable for both the client and the server,
/// so you can pass this channel directly to them.
/// However, only one client and one server can be bound to this channel at one time.
///
/// ``open`` must be called before the channels are usable.
public class NPStandardIOChannel: NPRPCClientChannel, NPRPCServerChannel {
    private let stdin: Pipe
    private let stdout: Pipe
    
    private var requestHandler: ((Data) -> Void)?
    private var responseHandler: ((Data) -> Void)?

    private var isClosed = false
    
    /// Creates a new channel for use with an RPC client and server.
    ///
    /// - parameter stdin: A ``Pipe`` to the stdin of a process. Requests will be sent to the process through stdin.
    /// - parameter stdout: A ``Pipe`` to the stdout of a process. Responses will be received through stdout.
    public init(stdin: Pipe, stdout: Pipe) {
        self.stdin = stdin
        self.stdout = stdout
    }
    
    public func sendRequestData(_ data: Data) {
        withUnsafeBytes(of: UInt32(data.count.littleEndian)) {
            stdin.fileHandleForWriting.write(Data($0))
        }
        stdin.fileHandleForWriting.write(data)
    }
    
    public func onResponse(responseHandler: @escaping (Data) -> Void) {
        self.responseHandler = responseHandler
    }
    
    public func receive(requestHandler: @escaping (Data) -> Void) {
        self.requestHandler = requestHandler
    }
    
    public func sendResponseData(_ data: Data) {
        withUnsafeBytes(of: UInt32(data.count.littleEndian)) {
            stdin.fileHandleForWriting.write(Data($0))
        }
        stdin.fileHandleForWriting.write(data)
    }
    
    /// Starts RPC communication with the process.
    public func open() {
        isClosed = false
        DispatchQueue.global().async {
            while !self.isClosed {
                self.readFromStdout()
            }
        }
    }
    
    /// Closes RPC communication with the process.
    ///
    /// You can reopen the communication by calling ``open`` again, but make sure the process is still running.
    public func close() {
        isClosed = true
    }
    
    private func readFromStdout() {
        let data = stdout.fileHandleForReading.readData(ofLength: 4)
        let msgSize = data.withUnsafeBytes { ptr in
            ptr.load(as: UInt32.self).littleEndian
        }
        guard msgSize > 0 else {
            return
        }

        let msgData = stdout.fileHandleForReading.readData(ofLength: Int(msgSize))
        switch msgData[0] {
        case NPRPCMessageType.response.rawValue:
            guard let handler = responseHandler else {
                return
            }
            DispatchQueue.global().async {
                handler(msgData)
            }
            
        case NPRPCMessageType.request.rawValue:
            guard let handler = requestHandler else {
                return
            }
            DispatchQueue.global().async {
                handler(msgData)
            }

        default:
            break
        }
    }
}
