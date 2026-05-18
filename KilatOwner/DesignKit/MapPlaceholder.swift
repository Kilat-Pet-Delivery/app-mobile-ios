import SwiftUI

struct Coordinate: Equatable, Sendable {
    var lat: Double
    var lng: Double
}

struct MapPlaceholder: View {
    enum Mode: Equatable, Sendable {
        case compact
        case full
    }

    let pickup: Coordinate
    let dropoff: Coordinate
    let mode: Mode

    init(pickup: Coordinate, dropoff: Coordinate, mode: Mode = .compact) {
        self.pickup = pickup
        self.dropoff = dropoff
        self.mode = mode
    }

    var body: some View {
        drawing
            .modifier(MapPlaceholderSizing(mode: mode))
    }

    private var drawing: some View {
        Canvas { context, size in
            drawNeighborhood(in: &context, size: size)

            let pickupPoint = point(for: pickup, in: size)
            let dropoffPoint = point(for: dropoff, in: size)
            let control = CGPoint(
                x: (pickupPoint.x + dropoffPoint.x) / 2 + size.width * 0.08,
                y: min(pickupPoint.y, dropoffPoint.y) - size.height * 0.12
            )

            var route = Path()
            route.move(to: pickupPoint)
            route.addQuadCurve(to: dropoffPoint, control: control)
            context.stroke(
                route,
                with: .color(Palette.coral),
                style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round, dash: [10, 8])
            )

            drawPickupPin(at: pickupPoint, in: &context)
            drawDropoffPin(at: dropoffPoint, in: &context)
        }
        .background(Palette.background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Palette.border, lineWidth: 1)
        )
    }

    private func drawNeighborhood(in context: inout GraphicsContext, size: CGSize) {
        let blockFill = Palette.block
        let road = Palette.road

        for index in 0..<5 {
            let y = size.height * (0.18 + Double(index) * 0.16)
            var path = Path()
            path.move(to: CGPoint(x: -20, y: y))
            path.addLine(to: CGPoint(x: size.width + 20, y: y - size.height * 0.08))
            context.stroke(path, with: .color(road), lineWidth: 10)
        }

        for index in 0..<4 {
            let x = size.width * (0.16 + Double(index) * 0.22)
            var path = Path()
            path.move(to: CGPoint(x: x, y: -20))
            path.addLine(to: CGPoint(x: x + size.width * 0.08, y: size.height + 20))
            context.stroke(path, with: .color(road), lineWidth: 8)
        }

        let blocks = [
            CGRect(x: size.width * 0.08, y: size.height * 0.10, width: size.width * 0.18, height: size.height * 0.15),
            CGRect(x: size.width * 0.38, y: size.height * 0.15, width: size.width * 0.20, height: size.height * 0.18),
            CGRect(x: size.width * 0.68, y: size.height * 0.12, width: size.width * 0.19, height: size.height * 0.16),
            CGRect(x: size.width * 0.14, y: size.height * 0.56, width: size.width * 0.22, height: size.height * 0.17),
            CGRect(x: size.width * 0.56, y: size.height * 0.60, width: size.width * 0.28, height: size.height * 0.18)
        ]

        for rect in blocks {
            let block = Path(roundedRect: rect, cornerRadius: 10)
            context.fill(block, with: .color(blockFill))
        }
    }

    private func drawPickupPin(at point: CGPoint, in context: inout GraphicsContext) {
        let outer = CGRect(x: point.x - 16, y: point.y - 16, width: 32, height: 32)
        let inner = CGRect(x: point.x - 7, y: point.y - 7, width: 14, height: 14)
        context.fill(Path(ellipseIn: outer), with: .color(Palette.cream))
        context.stroke(Path(ellipseIn: outer), with: .color(Palette.coral), lineWidth: 3)
        context.fill(Path(ellipseIn: inner), with: .color(Palette.coral))
    }

    private func drawDropoffPin(at point: CGPoint, in context: inout GraphicsContext) {
        let outer = CGRect(x: point.x - 17, y: point.y - 17, width: 34, height: 34)
        let inner = CGRect(x: point.x - 7, y: point.y - 7, width: 14, height: 14)
        context.fill(Path(ellipseIn: outer), with: .color(Palette.coral))
        context.stroke(Path(ellipseIn: outer), with: .color(.white), lineWidth: 4)
        context.fill(Path(ellipseIn: inner), with: .color(.white))
    }

    private func point(for coordinate: Coordinate, in size: CGSize) -> CGPoint {
        let padding = max(min(size.width, size.height) * 0.18, 34)
        let minLat = min(pickup.lat, dropoff.lat)
        let maxLat = max(pickup.lat, dropoff.lat)
        let minLng = min(pickup.lng, dropoff.lng)
        let maxLng = max(pickup.lng, dropoff.lng)
        let latSpan = max(maxLat - minLat, 0.000_001)
        let lngSpan = max(maxLng - minLng, 0.000_001)

        let xProgress = (coordinate.lng - minLng) / lngSpan
        let yProgress = 1 - ((coordinate.lat - minLat) / latSpan)

        return CGPoint(
            x: padding + xProgress * max(size.width - (padding * 2), 1),
            y: padding + yProgress * max(size.height - (padding * 2), 1)
        )
    }
}

private struct MapPlaceholderSizing: ViewModifier {
    let mode: MapPlaceholder.Mode

    func body(content: Content) -> some View {
        switch mode {
        case .compact:
            content.frame(height: 180)
        case .full:
            content
        }
    }
}

private enum Palette {
    static let background = Color(red: 0.96, green: 0.94, blue: 0.90)
    static let block = Color(red: 0.90, green: 0.86, blue: 0.79)
    static let road = Color.white.opacity(0.72)
    static let border = Color(red: 0.86, green: 0.80, blue: 0.72)
    static let coral = Color(red: 0.88, green: 0.32, blue: 0.26)
    static let cream = Color(red: 1.0, green: 0.94, blue: 0.82)
}
