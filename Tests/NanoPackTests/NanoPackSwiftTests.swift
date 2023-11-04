import XCTest
@testable import NanoPack

final class NanoPackSwiftTests: XCTestCase {
    func testReadTypeID() throws {
        let data = Data([4, 0, 0, 0])
        let typeID = data.readTypeID()
        XCTAssertEqual(typeID, 4)
        
        let dataWithNoTypeID = Data([0, 0, 0, 0, 4, 1, 2, 24])
        XCTAssertEqual(dataWithNoTypeID.readTypeID(), 0)
    }
    
    func testReadInt() throws {
        let data = Data([4, 5, 2, 3])
        
        let int8: Int8 = data.read(at: 1)
        XCTAssertEqual(int8, 5)
        
        let int16: Int16 = data.read(at: 2)
        XCTAssertEqual(int16, 770)
        
        let int32: Int32 = data.read(at: 0)
        XCTAssertEqual(int32, 50464004)
    }
    
    func testReadString() throws {
        let data = Data([0, 1, 3, 0x62, 0x72, 0x65, 0x61, 0x64, 0x20, 0xf0, 0x9f, 0x91, 0x8d])
        let str: String? = data.read(at: 3, withLength: 10)
        XCTAssertEqual(str, "bread 👍")
    }
    
    func testReadBool() throws {
        let data = Data([0, 0, 1, 0])
        
        let shouldBeTrue: Bool = data.read(at: 2)
        XCTAssertEqual(shouldBeTrue, true)
        
        let shouldBeFalse: Bool = data.read(at: 3)
        XCTAssertEqual(shouldBeFalse, false)
    }
    
    func testReadDouble() throws {
        let data = Data([0x66, 0x66, 0x66, 0x66, 0x66, 0xA6, 0x58, 0x40])
        let double: Double = data.read(at: 0)
        XCTAssertEqual(double, 98.6)
    }
    
    func testReadFieldSize() throws {
        let data = Data([1, 0, 0, 0, 8, 0, 0, 0, 12, 8, 0, 0])
        XCTAssertEqual(data.readSize(ofField: 0), 8)
        XCTAssertEqual(data.readSize(ofField: 1), 2060)
    }
    
    func testReadUnalignedSize() throws {
        let data = Data([1, 2, 8, 9, 0, 9])
        XCTAssertEqual(data.readUnalignedSize(at: 1), 591874)
    }
    
    func testWriteFieldSize() throws {
        var data = Data([1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        
        data.write(size: 12, ofField: 0)
        XCTAssertEqual(data, Data([1, 0, 0, 0, 12, 0, 0, 0, 0, 0, 0, 0]))
        
        data.write(size: 289, ofField: 1)
        XCTAssertEqual(data, Data([1, 0, 0, 0, 12, 0, 0, 0, 33, 1, 0, 0]))
    }
    
    func testWriteUnalignedSize() throws {
        var data = Data([0, 0, 0, 0, 0, 0, 0])
        data.write(size: 280192, at: 3)
        XCTAssertEqual(data, Data([0, 0, 0, 128, 70, 4, 0]))
    }
    
    func testAppendSize() throws {
        var data = Data([0, 1])
        data.append(size: 178)
        XCTAssertEqual(data, Data([0, 1, 178, 0, 0, 0]))
    }
    
    func testAppendBool() throws {
        var data = Data([0, 0, 1])
        data.append(bool: true)
        XCTAssertEqual(data, Data([0, 0, 1, 1]))
        data.append(bool: false)
        XCTAssertEqual(data, Data([0, 0, 1, 1, 0]))
    }
    
    func testAppendInt() throws {
        var data = Data([0, 0])
        
        data.append(int: Int8(27))
        XCTAssertEqual(data, Data([0, 0, 27]))
        
        data.append(int: Int16(2456))
        XCTAssertEqual(data, Data([0, 0, 27, 152, 9]))
        
        data.append(int: Int32(289))
        XCTAssertEqual(data, Data([0, 0, 27, 152, 9, 33, 1, 0, 0]))
    }
    
    func testAppendDouble() throws {
        var data = Data([0])
        data.append(double: 9.8)
        XCTAssertEqual(data, Data([0, 0x9A, 0x99, 0x99, 0x99, 0x99, 0x99, 0x23, 0x40]))
    }
    
    func testAppendString() throws {
        var data = Data([0, 1, 2])
        data.append(string: "hello world")
        XCTAssertEqual(data, Data([0, 1, 2, 0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64]))
    }
}
