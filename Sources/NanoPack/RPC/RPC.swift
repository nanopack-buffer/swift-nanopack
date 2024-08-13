import Foundation

public typealias NPRPCMessageID = UInt32

public enum NPRPCMessageType: UInt8 {
    case request = 1
    case response = 2
}
