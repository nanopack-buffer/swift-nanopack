import Foundation

public protocol NanoPackMessage {
    init?(data: Data)
    
    func data() -> Data?
}
