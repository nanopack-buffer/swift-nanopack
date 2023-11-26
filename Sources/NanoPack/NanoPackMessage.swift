import Foundation

protocol NanoPackMessage {
    init?(data: Data)
    
    func data() -> Data?
}
