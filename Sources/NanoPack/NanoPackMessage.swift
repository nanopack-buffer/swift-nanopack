import Foundation

public protocol NanoPackMessage {
    var typeID: TypeID { get }

    init?(data: Data)

    func data() -> Data?
}
