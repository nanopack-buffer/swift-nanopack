import Foundation

/// Defines a function that is called whenever an RPC call is complete.
///
/// To access the result of the RPC call, including the return value,
/// read from the given response data, starting at the given offset.
///
/// - parameter responseData: The serialized response to the RPC call.
/// - parameter offset: The index at which the result of the RPC call starts.
public typealias NPRPCCallback = (_ responseData: Data, _ offset: Int) -> Void

public typealias NPRPCRequestHandler = (Data, Int) -> Void

/// An RPC client that sends RPC requests to a server and receives responses from it.
///
/// You normally shouldn't need to use this class directly, as this is subclassed by nanoc-generated RPC client classes.
/// This class contains all the functionality to send request data and resolve them,
/// but doesn't provide any interface to construct and serialize an RPC request - this is handled by the generated RPC client.
open class NPRPCClient {
    private let channel: NPRPCClientChannel

    private var pendingRequests: [NPRPCMessageID: NPRPCCallback] = [:]

    public init(channel: NPRPCClientChannel) {
        self.channel = channel
        channel.onResponse { self.onResponse($0) }
    }

    public func sendRequestData(_ messageID: UInt32, _ data: Data, completionHandler: @escaping NPRPCCallback) {
        pendingRequests[messageID] = completionHandler
        channel.sendRequestData(data)
    }

    public func newMessageID() -> NPRPCMessageID {
        var id: NPRPCMessageID
        repeat {
            id = NPRPCMessageID.random(in: 0 ... NPRPCMessageID.max)
        } while pendingRequests[id] != nil
        return id
    }

    private func onResponse(_ msgData: Data) {
        let msgID: NPRPCMessageID = msgData.read(at: 1)
        guard let handler = pendingRequests.removeValue(forKey: msgID) else {
            return
        }
        handler(msgData, 5)
    }
}
