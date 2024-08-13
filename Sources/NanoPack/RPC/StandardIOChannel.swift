import Foundation

/// A channel that handles RPC traffic to a process via stdin and stdout.
/// You can make RPC calls to a process over stdio using this channel.
///
/// You can make RPC calls to a running process over stdio using this channel.
/// To access the channel that should be used by the RPC client, use ``clientChannel``.
/// Requests will be sent to the process through this channel.
/// To access the channel that should be used by the RPC server, use ``serverChannel``.
/// Requests sent from the process will be sent through this channel.
///
/// ``open`` must be called before the channels are usable.
public class NPStandardIOChannel {
    private let stdin: Pipe
    private let stdout: Pipe
    
    private let _clientChannel: StandardIOClientChannel
    var clientChannel: NPRPCClientChannel { _clientChannel }
    
    private let _serverChannel: StandardIOServerChannel
    var serverChannel: NPRPCServerChannel { _serverChannel }
    
    private var isClosed = false
    
    /// Creates a new channel for use with an RPC client and server.
    ///
    /// - parameter stdin: A ``Pipe`` to the stdin of a process. Requests will be sent to the process through stdin.
    /// - parameter stdout: A ``Pipe`` to the stdout of a process. Responses will be received through stdout.
    init(stdin: Pipe, stdout: Pipe) {
        self.stdin = stdin
        self.stdout = stdout
        _clientChannel = StandardIOClientChannel(stdin: stdin)
        _serverChannel = StandardIOServerChannel(stdin: stdin)
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
        var data = Data(count: 4)
        data.withUnsafeMutableBytes { ptr in
            let bufptr = ptr.bindMemory(to: UInt8.self)
            read(stdout.fileHandleForReading.fileDescriptor, bufptr.baseAddress, 4)
        }
        let msgSize = data.withUnsafeBytes { ptr in
            ptr.load(as: UInt32.self).littleEndian
        }

        var msgData = Data(count: Int(msgSize))
        msgData.withUnsafeMutableBytes { ptr in
            let bufptr = ptr.bindMemory(to: UInt8.self)
            read(stdout.fileHandleForReading.fileDescriptor, bufptr.baseAddress, 4)
        }

        switch msgData[0] {
        case NPRPCMessageType.response.rawValue:
            _clientChannel.didReceive(response: msgData)
        case NPRPCMessageType.request.rawValue:
            _serverChannel.didReceive(request: msgData)
        default:
            break
        }
    }
}

private class StandardIOClientChannel: NPRPCClientChannel {
    private var responseHandler: ((Data) -> Void)?
    private let stdin: Pipe
    
    fileprivate init(stdin: Pipe) {
        self.stdin = stdin
    }
    
    public func sendRequestData(_ data: Data) {
        withUnsafeBytes(of: data.count.littleEndian) {
            stdin.fileHandleForWriting.write(Data($0))
        }
        stdin.fileHandleForWriting.write(data)
    }
    
    public func onResponse(responseHandler: @escaping (Data) -> Void) {
        self.responseHandler = responseHandler
    }
    
    fileprivate func didReceive(response: Data) {
        guard let handler = responseHandler else {
            return
        }
        DispatchQueue.global().async {
            handler(response)
        }
    }
}

private class StandardIOServerChannel: NPRPCServerChannel {
    private var requestHandler: ((Data) -> Void)?
    private let stdin: Pipe
    
    fileprivate init(stdin: Pipe) {
        self.stdin = stdin
    }
    
    public func receive(requestHandler: @escaping (Data) -> Void) {
        self.requestHandler = requestHandler
    }
    
    func sendResponseData(_ data: Data) {
        withUnsafeBytes(of: data.count.littleEndian) {
            stdin.fileHandleForWriting.write(Data($0))
        }
        stdin.fileHandleForWriting.write(data)
    }

    fileprivate func didReceive(request data: Data) {
        guard let handler = requestHandler else {
            return
        }
        DispatchQueue.global().async {
            handler(data)
        }
    }
}
