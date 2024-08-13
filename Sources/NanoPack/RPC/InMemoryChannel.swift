import Foundation

public class NPInMemoryRPCClientChannel: NPRPCClientChannel {
    private var responseHandler: ((Data) -> Void)?
    private var serverChannel: NPInMemoryRPCServerChannel?
    
    public init() {}
    
    public func sendTo(_ channel: NPInMemoryRPCServerChannel) {
        serverChannel = channel
    }
    
    public func sendRequestData(_ data: Data) {
        serverChannel?.didReceiveRequest(data: data)
    }
    
    public func onResponse(responseHandler: @escaping (Data) -> Void) {
        self.responseHandler = responseHandler
    }
    
    fileprivate func didReceiveResponse(data: Data) {
        guard let handler = responseHandler else {
            return
        }
        handler(data)
    }
}

public class NPInMemoryRPCServerChannel: NPRPCServerChannel {
    private var requestHandler: ((Data) -> Void)?
    private var clientChannel: NPInMemoryRPCClientChannel?
    
    public init() {}
    
    public func replyTo(_ channel: NPInMemoryRPCClientChannel) {
        clientChannel = channel
    }
    
    public func receive(requestHandler: @escaping (Data) -> Void) {
        self.requestHandler = requestHandler
    }
    
    public func sendResponseData(_ data: Data) {
        clientChannel?.didReceiveResponse(data: data)
    }
    
    fileprivate func didReceiveRequest(data: Data) {
        guard let handler = requestHandler else {
            return
        }
        handler(data)
    }
}
