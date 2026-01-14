import SwiftUI
import UniformTypeIdentifiers

struct PalettesDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var payload: PalettesPayload

    init(payload: PalettesPayload) {
        self.payload = payload
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        payload = try JSONDecoder().decode(PalettesPayload.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(payload)
        return .init(regularFileWithContents: data)
    }
}
