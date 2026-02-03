import Foundation
import Combine

struct GBAROMInfo {
    var title: String
    var gameCode: String
    var makerCode: String
    var checksum: UInt8
    var calculatedChecksum: UInt8
    var isLogoValid: Bool
    
    var isChecksumValid: Bool {
        return checksum == calculatedChecksum
    }
}

@MainActor
final class GBAManager: ObservableObject {
    @Published var statusMessage = "Please load GBA ROM."
    @Published var romInfo: GBAROMInfo? = nil
    var currentURL: URL?
    
    static let nintendoLogo: [UInt8] = [
        0x24, 0xFF, 0xAE, 0x51, 0x69, 0x9A, 0xA2, 0x21, 0x3D, 0x84, 0x82, 0x0A, 0x84, 0xE4, 0x09, 0xAD,
        0x11, 0x24, 0x8B, 0x98, 0xC0, 0x81, 0x7F, 0x21, 0xA3, 0x52, 0xBE, 0x19, 0x93, 0x09, 0xCE, 0x20,
        0x10, 0x46, 0x4A, 0x4A, 0xF8, 0x27, 0x31, 0xEC, 0x58, 0xC7, 0xE8, 0x33, 0x82, 0xE3, 0xCE, 0xBF,
        0x85, 0xF4, 0xDF, 0x94, 0xCE, 0x4B, 0x09, 0xC1, 0x94, 0x56, 0x8A, 0xC0, 0x13, 0x72, 0xA7, 0xFC,
        0x9F, 0x84, 0x4D, 0x73, 0xA3, 0xCA, 0x9A, 0x61, 0x58, 0x97, 0xA3, 0x27, 0xFC, 0x03, 0xD0, 0x7A,
        0x00, 0x26, 0x57, 0xAF, 0x8F, 0x40, 0x33, 0x0C, 0xCB, 0x39, 0x69, 0xCC, 0x21, 0xED, 0x29, 0x11,
        0xA0, 0xD1, 0x07, 0x05, 0x8E, 0x7B, 0x30, 0x2B, 0xD1, 0xE6, 0x2E, 0x6A, 0x0B, 0xC1, 0xA4, 0x8E,
        0x89, 0x82, 0x7E, 0x10, 0x7F, 0xB4, 0x4E, 0x4C, 0x80, 0x79, 0x0E, 0x25, 0xC0, 0x5A, 0x22, 0x32,
        0x23, 0x3D, 0xEE, 0x89, 0x01, 0xC0, 0x82, 0x22, 0x4B, 0x4C, 0x07, 0x97, 0x6F, 0x00, 0xAF, 0x4D,
        0x37, 0x30, 0x17, 0x3E, 0x02, 0x46, 0xA5, 0x27, 0x84, 0xFE, 0xC2, 0xAA
    ]

    func loadROM(at url: URL) {
        let accessRequested = url.startAccessingSecurityScopedResource()
        defer { if accessRequested { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            guard data.count >= 0xBE else {
                DispatchQueue.main.async {
                    self.statusMessage = "ERROR: ROM is too small."
                    self.romInfo = nil
                    self.currentURL = nil
                }
                return
            }

            let logoDataInROM = Array(data[0x04...0x9F])
            let isLogoValid = (logoDataInROM == Self.nintendoLogo)

            let titleData = data[0xA0...0xAB]
            let title = String(data: titleData, encoding: .ascii)?.trimmingCharacters(in: .controlCharacters).trimmingCharacters(in: .whitespaces) ?? "Unknown"

            let codeData = data[0xAC...0xAF]
            let gameCode = String(data: codeData, encoding: .ascii) ?? "????"

            let makerData = data[0xB0...0xB1]
            let makerCode = String(data: makerData, encoding: .ascii) ?? "00"

            let headerRange = data[0xA0...0xBC]
            let sum = headerRange.reduce(0) { $0 + Int($1) }
            let calculated = UInt8((-(sum + 0x19)) & 0xFF)
            let currentChecksum = data[0xBD]

            DispatchQueue.main.async {
                self.romInfo = GBAROMInfo(title: title, gameCode: gameCode, makerCode: makerCode, checksum: currentChecksum, calculatedChecksum: calculated, isLogoValid: isLogoValid)
                self.currentURL = url
                self.statusMessage = "Data loaded."
            }
        } catch {
            DispatchQueue.main.async {
                self.statusMessage = "ERROR: \(error.localizedDescription)"
            }
        }
    }

    func fixHeaderAndLogo() {
            guard let url = currentURL, let info = romInfo else { return }
            let accessRequested = url.startAccessingSecurityScopedResource()
            defer { if accessRequested { url.stopAccessingSecurityScopedResource() } }

            do {
                var data = try Data(contentsOf: url)
                
                for i in 0..<Self.nintendoLogo.count {
                    data[0x04 + i] = Self.nintendoLogo[i]
                }
                
                data[0xBD] = info.calculatedChecksum
                
                try data.write(to: url)
                loadROM(at: url)
                
                DispatchQueue.main.async { self.statusMessage = "Repair succeeded" }
            } catch {
                DispatchQueue.main.async { self.statusMessage = "Failed: \(error.localizedDescription)" }
            }
        }
    }

