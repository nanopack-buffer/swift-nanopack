import Foundation

/// Describes a client-side channel that sends requests to a server and which responses are received from.
public protocol NPRPCClientChannel {
    /// Sends the given serialized RPC request to the server.
    ///
    /// - parameter data: The serialized RPC request to be sent.
    func sendRequestData(_ data: Data)

    /// Registers the given callback to be called whenever this channel receives a response from the server.
    ///
    /// - parameter onRespnose: The callback that should be called whenever a response is received.
    func onResponse(responseHandler: @escaping (Data) -> Void)
}

/// Describes a server-side channel that receives requests from client and which replies are sent through.
public protocol NPRPCServerChannel {
    /// Registers the given callback to be called whenever this channel receives a request from the client.
    ///
    /// - parameter requestHandler: The callback that should be called whenever a request is received.
    func receive(requestHandler: @escaping (Data) -> Void)

    /// Sends the given serialized RPC response to the client.
    ///
    /// - parameter data: The serialized RPC response to be sent.
    func sendResponseData(_ data: Data)
}
