import SwiftUI
import UIKit
import XCTest

@MainActor
func assertAuthSnapshot<V: View>(
    _ view: V,
    named name: String,
    file: StaticString = #filePath,
    line: UInt = #line
) throws {
    let image = try renderAuthSnapshot(view, file: file, line: line)
    let snapshotURL = authSnapshotDirectory(file: file)
        .appendingPathComponent("\(name).png")

    guard FileManager.default.fileExists(atPath: snapshotURL.path) else {
        try FileManager.default.createDirectory(
            at: snapshotURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try XCTUnwrap(image.pngData(), file: file, line: line).write(to: snapshotURL)
        XCTFail("Recorded missing snapshot baseline: \(snapshotURL.path)", file: file, line: line)
        return
    }

    let baselineData = try Data(contentsOf: snapshotURL)
    let baseline = try XCTUnwrap(UIImage(data: baselineData), file: file, line: line)
    XCTAssertEqual(image.size, baseline.size, file: file, line: line)
    XCTAssertEqual(try authRGBAData(for: image), try authRGBAData(for: baseline), file: file, line: line)
}

@MainActor
private func renderAuthSnapshot<V: View>(
    _ view: V,
    file: StaticString,
    line: UInt
) throws -> UIImage {
    let renderer = ImageRenderer(
        content: view
            .frame(width: 393, height: 852)
            .environment(\.colorScheme, .light)
    )
    renderer.scale = 1
    return try XCTUnwrap(renderer.uiImage, file: file, line: line)
}

private func authRGBAData(for image: UIImage) throws -> Data {
    let width = Int(image.size.width)
    let height = Int(image.size.height)
    var data = Data(count: width * height * 4)

    try data.withUnsafeMutableBytes { bytes in
        guard
            let address = bytes.baseAddress,
            let context = CGContext(
                data: address,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            throw AuthSnapshotError.renderContextUnavailable
        }

        UIGraphicsPushContext(context)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        UIGraphicsPopContext()
    }

    return data
}

private func authSnapshotDirectory(file: StaticString) -> URL {
    URL(fileURLWithPath: "\(file)")
        .deletingLastPathComponent()
        .appendingPathComponent("__Snapshots__", isDirectory: true)
}

private enum AuthSnapshotError: Error {
    case renderContextUnavailable
}
