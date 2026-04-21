import SwiftUI
import MapKit
import CoreSharedUI
import Domain

struct CourseLiveMapView: View {
    let places: [CoursePlace]
    let visitedOrders: Set<Int>
    let onVisit: (Int) -> Void
    let onDismiss: () -> Void
    let onStop: () -> Void

    @State private var position: MapCameraPosition = .automatic

    private var sortedPlaces: [CoursePlace] { places.sorted { $0.order < $1.order } }
    private var nextPlace: CoursePlace? { sortedPlaces.first { !visitedOrders.contains($0.order) } }
    private var allVisited: Bool { !sortedPlaces.isEmpty && sortedPlaces.allSatisfy { visitedOrders.contains($0.order) } }

    private var coordinatePlaces: [(CoursePlace, CLLocationCoordinate2D)] {
        sortedPlaces.compactMap { place in
            guard let lat = place.latitude, let lon = place.longitude else { return nil }
            return (place, CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Map(position: $position) {
                UserAnnotation()

                ForEach(sortedPlaces, id: \.order) { place in
                    if let lat = place.latitude, let lon = place.longitude {
                        Annotation("", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                            placePin(place)
                        }
                    }
                }

                if coordinatePlaces.count > 1 {
                    MapPolyline(coordinates: coordinatePlaces.map(\.1))
                        .stroke(Brand.pink.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                }
            }
            .mapControls {
                MapUserLocationButton()
            }
            .ignoresSafeArea()
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomCard
            }
            .onAppear {
                if !coordinatePlaces.isEmpty {
                    position = .region(regionFitting(coordinatePlaces.map(\.1)))
                }
            }

            // 닫기 버튼
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Circle())
            }
            .padding(.top, 16)
            .padding(.leading, 16)
        }
    }

    // MARK: - Pin

    private func placePin(_ place: CoursePlace) -> some View {
        let visited = visitedOrders.contains(place.order)
        let isNext = place.order == nextPlace?.order

        return ZStack {
            Circle()
                .fill(visited ? Color(.systemGray4) : (isNext ? Brand.pink : Brand.pink.opacity(0.55)))
                .frame(width: isNext ? 38 : 32, height: isNext ? 38 : 32)
                .shadow(color: isNext ? Brand.pink.opacity(0.45) : .black.opacity(0.15), radius: isNext ? 8 : 4)

            if visited {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Text("\(place.order)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .scaleEffect(isNext ? 1.0 : 0.9)
        .animation(.spring(response: 0.3), value: visitedOrders)
    }

    // MARK: - Bottom Card

    private var bottomCard: some View {
        VStack(spacing: 12) {
            if allVisited {
                Text("모든 장소 방문 완료 🎉")
                    .font(Typography.body.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Brand.softPink)
                    .foregroundStyle(Brand.pink)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else if let next = nextPlace {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Brand.softPink)
                            .frame(width: 40, height: 40)
                        Text("\(next.order)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Brand.pink)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("다음 장소")
                            .font(Typography.caption2)
                            .foregroundStyle(.secondary)
                        Text(next.placeName ?? next.keyword)
                            .font(Typography.body.weight(.semibold))
                            .lineLimit(1)
                    }
                    Spacer()
                }

                HStack(spacing: 10) {
                    Button {
                        Haptics.impact(.rigid)
                        onStop()
                    } label: {
                        Text("종료")
                            .font(Typography.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 64)
                            .padding(.vertical, Spacing.md)
                            .background(Color(.systemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    Button {
                        Haptics.impact(.medium)
                        onVisit(next.order)
                    } label: {
                        Text("도착했어요")
                            .font(Typography.body.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(Brand.pink)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Brand.pink.opacity(0.3), radius: 8, x: 0, y: 3)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, 16)
        .padding(.bottom, Spacing.lg)
        .background(.regularMaterial)
    }

    // MARK: - Helper

    private func regionFitting(_ coords: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coords.isEmpty else {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        }
        let lats = coords.map(\.latitude)
        let lons = coords.map(\.longitude)
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLon = lons.min()!, maxLon = lons.max()!
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.4, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.4, 0.01)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}
