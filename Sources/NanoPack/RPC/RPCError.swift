import Foundation

public enum NPRPCError: Error {
    /// The RPC call was made successfully, but the server returned an invalid response,
    /// and the client was not able to deserialize it.
    case malformedResponse

    /// The remote function has thrown a typed error defined in the schema.
    case thrown(error: NanoPackMessage)
}
