import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var manager = GBAManager()
    @State private var isImporting = false

    var body: some View {
        VStack(spacing: 20) {
            Text("GBAed - GBA header Examiner & Debugger")
                .font(.title2).bold()

            if let info = manager.romInfo {
                VStack(spacing: 10) {
                    InfoRow(label: "Game Title", value: info.title)
                    InfoRow(label: "Game Code", value: info.gameCode)
                    InfoRow(label: "Maker", value: info.makerCode)
                    
                    Divider()
                    
                    HStack {
                        Text("Nintendo Logo:")
                        Spacer()
                        Text(info.isLogoValid ? "✅ OK" : "❌ BAD")
                            .foregroundColor(info.isLogoValid ? .green : .red)
                            .bold()
                    }
                    
                    HStack {
                        Text("Checksum:")
                        Spacer()
                        Text("0x\(String(format: "%02X", info.checksum))")
                        Text(info.isChecksumValid ? "✅ OK" : "❌ BAD")
                            .foregroundColor(info.isChecksumValid ? .green : .red)
                            .bold()
                    }
                }
                
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))
            }

            Text(manager.statusMessage)
                .font(.footnote)
                .foregroundColor(.secondary)

            HStack {
                Button("Load") {
                    isImporting = true
                }
                .buttonStyle(.bordered)

                if let info = manager.romInfo, (!info.isChecksumValid || !info.isLogoValid) {
                    Button("Fix") {
                        manager.fixHeaderAndLogo()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
            }
        }
        .padding()
        .frame(width: 400, height: 350)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [UTType.data, UTType(filenameExtension: "gba")!].compactMap { $0 },
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    manager.loadROM(at: url)
                }
            case .failure(let error):
                manager.statusMessage = "FAILED: \(error.localizedDescription)"
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).monospaced()
        }
    }
}

