import Foundation

/// Defines a function that is called whenever a matching RPC call is received.
///
/// To access serialized arguments and deserialize them, read from the given request data, starting at the given offset.
/// The returned RPC response must contain the given message ID.
///
/// - parameter requestData: The serialized request that made the RPC call.
/// - parameter offset: The index at which serialized arguments of the call starts.
/// - parameter msgID: The ID of the RPC message.
/// - returns: A serialized RPC response to this call.
public typealias NPRPCCallHandler = (_ requestData: Data, _ offset: Int, _ msgID: NPRPCMessageID) -> Data?

open class NPRPCServer {
    private let channel: NPRPCServerChannel
    private var callHandlers: [String: NPRPCCallHandler] = [:]

    public init(channel: NPRPCServerChannel) {
        self.channel = channel
        channel.receive { self.onRequestData($0) }
    }

    public func on(_ method: String, _ callHandler: @escaping NPRPCCallHandler) {
        callHandlers[method] = callHandler
    }

    private func onRequestData(_ data: Data) {
        let msgID: UInt32 = data.read(at: 1)
        let methodNameLen: UInt32 = data.read(at: 5)
        guard let methodName: String = data.read(at: 9, withLength: Int(methodNameLen)),
              let handler = callHandlers[methodName]
        else {
            return
        }
        if let responseData = handler(data, Int(9 + methodNameLen), msgID) {
            channel.sendResponseData(responseData)
        } else {
            var data = Data(capacity: 6)
            data.append(int: NPRPCMessageType.response.rawValue)
            data.append(int: methodNameLen)
            data.append(int: 1)
        }
    }
}
