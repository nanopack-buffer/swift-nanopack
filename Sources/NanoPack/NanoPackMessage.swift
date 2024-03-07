import Foundation

/// All NanoPack messages conform to this protocol.
public protocol NanoPackMessage {
    var typeID: TypeID { get }
    
    var headerSize: Int { get }

    /// De-serializes the given NanoPack buffer into this message class.
    /// - parameter data: The NanoPack-formatted data to be read.
    init?(data: Data)

    /// De-serializes the given NanoPack buffer into this message class.
    /// - parameter data: The NanoPack-formatted data to be read.
    /// - parameter bytesRead: The number of bytes read is stored in this inout parameter.
    init?(data: Data, bytesRead: inout Int)

    /// Writes the serialized bytes to the given data at the given offset
    /// There must be enough space at the offset to accomodate for the size header of the message
    func write(to data: inout Data, offset: Int) -> Int

    /// Serializes this message into a NanoPack buffer.
    /// - returns This message serialized into a ``Data``, or `nil` if the message is malformed.
    func data() -> Data?
}
