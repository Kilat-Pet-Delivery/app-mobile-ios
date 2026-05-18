import SwiftUI
import UIKit
import XCTest
@testable import KilatOwner

@MainActor
final class MapPlaceholderSnapshotTests: XCTestCase {
    private let pickup = Coordinate(lat: 3.1599, lng: 101.7123)
    private let dropoff = Coordinate(lat: 3.1478, lng: 101.6953)

    func testMapPlaceholder_compact_180pt() throws {
        let view = MapPlaceholder(pickup: pickup, dropoff: dropoff, mode: .compact)
            .frame(width: 343)

        try assertSnapshot(view, named: "testMapPlaceholder_compact_180pt")
    }

    func testMapPlaceholder_full_inFrame() throws {
        let view = MapPlaceholder(pickup: pickup, dropoff: dropoff, mode: .full)
            .frame(width: 343, height: 320)

        try assertSnapshot(view, named: "testMapPlaceholder_full_inFrame")
    }

    private func assertSnapshot<V: View>(
        _ view: V,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let image = try render(view, file: file, line: line)
        let snapshotURL = snapshotDirectory(file: file)
            .appendingPathComponent("\(name).png")

        if ProcessInfo.processInfo.environment["KILAT_RECORD_SNAPSHOTS"] == "1" {
            try FileManager.default.createDirectory(
                at: snapshotURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try XCTUnwrap(image.pngData(), file: file, line: line).write(to: snapshotURL)
            return
        }

        guard FileManager.default.fileExists(atPath: snapshotURL.path) else {
            XCTFail("Missing snapshot baseline: \(snapshotURL.path)", file: file, line: line)
            return
        }

        let baselineData = try Data(contentsOf: snapshotURL)
        let baseline = try XCTUnwrap(UIImage(data: baselineData), file: file, line: line)
        XCTAssertEqual(image.size, baseline.size, file: file, line: line)
        XCTAssertEqual(try rgbaData(for: image), try rgbaData(for: baseline), file: file, line: line)
    }

    private func render<V: View>(
        _ view: V,
        file: StaticString,
        line: UInt
    ) throws -> UIImage {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        return try XCTUnwrap(renderer.uiImage, file: file, line: line)
    }

    private func rgbaData(for image: UIImage) throws -> Data {
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
                throw SnapshotError.renderContextUnavailable
            }

            UIGraphicsPushContext(context)
            image.draw(in: CGRect(origin: .zero, size: image.size))
            UIGraphicsPopContext()
        }

        return data
    }

    private func snapshotDirectory(file: StaticString) -> URL {
        URL(fileURLWithPath: "\(file)")
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__/MapPlaceholderSnapshotTests", isDirectory: true)
    }
}

private enum SnapshotError: Error {
    case renderContextUnavailable
}
