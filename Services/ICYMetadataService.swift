import Foundation

/// Connects to an ICY (Icecast/Shoutcast) stream, reads the first metadata block,
/// extracts the StreamTitle, then closes the connection.
///
/// Usage:
///   let title = try await ICYMetadataService.fetchTitle(from: url)
enum ICYMetadataService {

    enum ICYError: Error {
        case noMetaint
        case noMetadata
        case invalidStream
    }

    /// Fetches the current StreamTitle from an ICY stream.
    /// Opens a raw TCP-level HTTP connection so we can read the binary stream directly.
    static func fetchTitle(from url: URL) async throws -> String {
        // Build request with the magic header that tells the server to embed metadata.
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue("1", forHTTPHeaderField: "Icy-MetaData")
        // Request a tiny buffer to minimise how many audio bytes we have to read.
        request.setValue("0", forHTTPHeaderField: "Range")

        // Use a one-shot URLSession with no caching so we get a raw byte stream.
        let config = URLSessionConfiguration.ephemeral
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }

        let (asyncBytes, response) = try await session.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ICYError.invalidStream
        }

        // icy-metaint tells us how many audio bytes appear between each metadata block.
        guard let metaintString = httpResponse.value(forHTTPHeaderField: "icy-metaint"),
              let metaint = Int(metaintString), metaint > 0 else {
            throw ICYError.noMetaint
        }

        var iterator = asyncBytes.makeAsyncIterator()

        // Skip the first audio block (metaint bytes).
        for _ in 0 ..< metaint {
            guard (try await iterator.next()) != nil else { throw ICYError.invalidStream }
        }

        // The next byte is the metadata length indicator.
        // Actual byte count = indicator * 16.
        guard let lengthByte = try await iterator.next() else { throw ICYError.invalidStream }
        let metadataLength = Int(lengthByte) * 16
        guard metadataLength > 0 else { throw ICYError.noMetadata }

        // Read the metadata block.
        var metadataBytes = [UInt8]()
        metadataBytes.reserveCapacity(metadataLength)
        for _ in 0 ..< metadataLength {
            guard let byte = try await iterator.next() else { break }
            metadataBytes.append(byte)
        }

        // The metadata is a UTF-8 string like: StreamTitle='Artist - Title';StreamUrl='...';
        guard let raw = String(bytes: metadataBytes, encoding: .utf8) ??
                        String(bytes: metadataBytes, encoding: .isoLatin1) else {
            throw ICYError.noMetadata
        }

        return try parseStreamTitle(from: raw)
    }

    // MARK: - Parsing

    private static func parseStreamTitle(from raw: String) throws -> String {
        // Find StreamTitle='...'; — the value may contain single quotes escaped as ''
        guard let startRange = raw.range(of: "StreamTitle='") else {
            throw ICYError.noMetadata
        }
        let afterKey = raw[startRange.upperBound...]

        // Find the closing '; — walk forward to handle escaped quotes inside the value.
        var result = ""
        var idx = afterKey.startIndex
        while idx < afterKey.endIndex {
            let ch = afterKey[idx]
            if ch == "'" {
                // Peek ahead: '' is an escaped single quote, '; ends the value.
                let next = afterKey.index(after: idx)
                if next < afterKey.endIndex && afterKey[next] == ";" {
                    break   // closing ';
                } else if next < afterKey.endIndex && afterKey[next] == "'" {
                    result.append("'")
                    idx = afterKey.index(after: next)
                    continue
                } else {
                    break   // closing ' without ;
                }
            }
            result.append(ch)
            idx = afterKey.index(after: idx)
        }

        let title = result.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw ICYError.noMetadata }
        return title
    }
}
