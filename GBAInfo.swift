struct GBAInfo {
    var title: String
    var gameCode: String
    var makerCode: String
    var checksum: UInt8
    var calculatedChecksum: UInt8
    
    var isChecksumValid: Bool {
        return checksum == calculatedChecksum
    }
}

