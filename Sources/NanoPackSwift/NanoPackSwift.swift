import Foundation

typealias Size = Int
typealias TypeID = Int

/// Provides additional methods for reading from/writing to a NanoPack-formatted Data.
extension Data {
    /// Read the type ID of the message stored in the data buffer.
    func readTypeID() -> TypeID {
        let id: Int32 = read(at: 0)
        return TypeID(id)
    }
    
    /// Read a fixed width integer.
    ///
    /// - parameter at: The index of the first byte of the integer in the Data buffer.
    func read<T: FixedWidthInteger>(at index: Int) -> T {
        return self[index..<index + MemoryLayout<T>.size].withUnsafeBytes {
            $0.load(as: T.self).littleEndian
        }
    }
    
    /// Read a UTF-8 encoded string.
    ///
    /// - parameter at: The index of the first byte of the string in the Data buffer.
    /// - parameter withLength: The number of bytes of the string.
    ///                         Note that NanoPack strings are not null-terminated, so there is no need to include it in the length.
    func read(at index: Int, withLength: Int) -> String? {
        return String(data: self[index..<index + withLength], encoding: .utf8)
    }
    
    /// Read a boolean.
    ///
    /// - parameter at: The index of the byte of the boolean in the Data buffer.
    func read(at index: Int) -> Bool {
        return self[index] == 1;
    }
    
    /// Read a fixed width integer.
    ///
    /// - parameter at: The index of the first byte of the double in the Data buffer.
    func read(at index: Int) -> Double {
        return self[index..<index + MemoryLayout<Double>.size].withUnsafeBytes {
            $0.load(as: Double.self)
        }
    }
    
    /// Read the size (in bytes) of a field.
    ///
    /// - parameter ofField: The number of the field.
    func readSize(ofField index: Int) -> Size {
        let size: Int32 = read(at: MemoryLayout<Int32>.size * (index + 1))
        return Size(size)
    }

    /// Read a size that is not byte-aligned.
    ///
    /// - parameter at: The index of the first byte of the encoded size number.
    func readUnalignedSize(at index: Int) -> Int {
        return subdata(in: index..<index + MemoryLayout<Int32>.size).withUnsafeBytes {
            Size($0.load(as: Int32.self).littleEndian)
        }
    }
    
    /// Write the size (in bytes) of a field to the size header.
    ///
    /// - parameter size: The number of bytes the field takes in the buffer
    /// - parameter ofField: The number of the field
    mutating func write(size: Size, ofField: Int) {
        write(size: size, at: MemoryLayout<Int32>.size * (ofField + 1))
    }
    
    /// Write a size at the given index.
    ///
    /// - parameter size: The size to be written
    /// - parameter at: The index at which the first byte of the encoded size should be
    mutating func write(size: Size, at index: Int) {
        Swift.withUnsafeBytes(of: Int32(size).littleEndian) {
            self[index] = $0[0]
            self[index + 1] = $0[1]
            self[index + 2] = $0[2]
            self[index + 3] = $0[3]
        }
    }
    
    /// Append a size to the end of the data buffer
    mutating func append(size: Size) {
        append(int: Int32(size))
    }
    
    /// Append the boolean to the end of the data buffer
    mutating func append(bool: Bool) {
        var b: UInt8 = bool ? 1 : 0
        append(&b, count: 1)
    }
    
    /// Append the fixed width integer to the end of the data buffer
    mutating func append<T: FixedWidthInteger>(int: T) {
        Swift.withUnsafeBytes(of: int.littleEndian) {
            append(contentsOf: $0)
        }
    }
    
    /// Append the double to the end of the data buffer
    mutating func append(double: Double) {
        Swift.withUnsafeBytes(of: double) {
            append(contentsOf: $0)
        }
    }
    
    /// Append the string to the end of the data buffer
    mutating func append(string: String) {
        string.utf8CString.withUnsafeBytes {
            // drop the null character at the end
            append(contentsOf: $0.dropLast())
        }
    }
}
