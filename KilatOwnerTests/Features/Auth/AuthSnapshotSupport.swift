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
    assertAuthSnapshotPixelsMatch(
        actual: try authRGBAData(for: image),
        baseline: try authRGBAData(for: baseline),
        file: file,
        line: line
    )
}

@MainActor
private func renderAuthSnapshot<V: View>(
    _ view: V,
    file: StaticString,
    line: UInt
) throws -> UIImage {
    let size = CGSize(width: 393, height: 852)
    let frame = CGRect(origin: .zero, size: size)
    let controller = UIHostingController(
        rootView: view
            .frame(width: size.width, height: size.height)
            .environment(\.colorScheme, .light)
    )
    controller.view.bounds = frame
    controller.view.backgroundColor = .clear

    let window = UIWindow(frame: frame)
    window.rootViewController = controller
    window.isHidden = false
    controller.view.setNeedsLayout()
    controller.view.layoutIfNeeded()

    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.preferredRange = .standard

    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    let image = renderer.image { context in
        UIColor.clear.setFill()
        context.fill(frame)
        controller.view.layer.render(in: context.cgContext)
    }
    window.isHidden = true

    return image
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

private func assertAuthSnapshotPixelsMatch(
    actual: Data,
    baseline: Data,
    file: StaticString,
    line: UInt
) {
    XCTAssertEqual(actual.count, baseline.count, file: file, line: line)
    guard actual.count == baseline.count else { return }

    let allowedChannelDelta = 2
    let allowedMismatchRatio = 0.02
    let mismatchCount = zip(actual, baseline).reduce(into: 0) { count, pair in
        if abs(Int(pair.0) - Int(pair.1)) > allowedChannelDelta {
            count += 1
        }
    }
    let mismatchRatio = Double(mismatchCount) / Double(actual.count)

    XCTAssertLessThanOrEqual(
        mismatchRatio,
        allowedMismatchRatio,
        "Snapshot mismatch ratio \(mismatchRatio) exceeded \(allowedMismatchRatio)",
        file: file,
        line: line
    )
}

private func authSnapshotDirectory(file: StaticString) -> URL {
    URL(fileURLWithPath: "\(file)")
        .deletingLastPathComponent()
        .appendingPathComponent("__Snapshots__", isDirectory: true)
}

private enum AuthSnapshotError: Error {
    case renderContextUnavailable
}
