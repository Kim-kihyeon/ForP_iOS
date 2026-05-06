import SwiftUI
import MapKit
import CoreSharedUI
import Domain

struct FootprintMapView: View {
    let courses: [Course]
    let isLoading: Bool
    let onDismiss: () -> Void

    @State private var position: MapCameraPosition = .automatic
    @State private var selectedFootprintId: String?

    private var footprints: [FootprintPlace] {
        FootprintPlace.make(from: courses)
    }

    private var selectedFootprint: FootprintPlace? {
        guard let selectedFootprintId else { return footprints.first }
        return footprints.first { $0.id == selectedFootprintId } ?? footprints.first
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    loadingState
                } else if footprints.isEmpty {
                    emptyState
                } else {
                    mapContent
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("우리 발자국")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { onDismiss() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Brand.pink)
                }
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(Brand.pink)
            Text("다녀온 곳을 모으고 있어요")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Brand.softPink)
                    .frame(width: 86, height: 86)
                Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Brand.pink)
            }

            VStack(spacing: 7) {
                Text("아직 발자국이 없어요")
                    .font(.system(size: 20, weight: .bold))
                Text("코스를 다녀오면 장소가 자동으로 쌓여요")
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var mapContent: some View {
        VStack(spacing: 0) {
            FootprintMapRendererView(
                footprints: footprints,
                selectedFootprintId: $selectedFootprintId,
                position: $position
            )
            .frame(height: 360)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(footprints.count)곳")
                        .font(.system(size: 18, weight: .black))
                    Text("다녀온 장소가 자동으로 쌓여요")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(14)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if let selectedFootprint {
                    selectedCard(selectedFootprint)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.bottom, 12)
                }
            }

            recentList
        }
        .onAppear {
            selectedFootprintId = selectedFootprintId ?? footprints.first?.id
            position = .region(regionFitting(footprints.map(\.coordinate)))
        }
    }

    private var recentList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("최근 발자국")
                        .font(.system(size: 15, weight: .bold))
                }
                .padding(.top, Spacing.lg)

                ForEach(footprints.sorted { $0.latestDate > $1.latestDate }) { footprint in
                    Button {
                        Haptics.selection()
                        selectedFootprintId = footprint.id
                        position = .region(regionFitting([footprint.coordinate]))
                    } label: {
                        footprintRow(footprint)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, 28)
        }
    }

    private func selectedCard(_ footprint: FootprintPlace) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Brand.pink)
                    .frame(width: 42, height: 42)
                Image(systemName: "mappin.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(footprint.placeName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("\(footprint.latestCourseTitle) · \(footprint.dateText)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if footprint.visitCount > 1 {
                Text("\(footprint.visitCount)번")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Brand.pink)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Brand.softPink)
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
    }

    private func footprintRow(_ footprint: FootprintPlace) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(Brand.softPink)
                    .frame(width: 44, height: 44)
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Brand.pink)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(footprint.placeName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("\(footprint.dateText) · \(footprint.latestCourseTitle)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if footprint.visitCount > 1 {
                Text("\(footprint.visitCount)회")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func regionFitting(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard let first = coordinates.first else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
        }

        guard coordinates.count > 1 else {
            return MKCoordinateRegion(
                center: first,
                span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
            )
        }

        let minLat = coordinates.map(\.latitude).min() ?? first.latitude
        let maxLat = coordinates.map(\.latitude).max() ?? first.latitude
        let minLon = coordinates.map(\.longitude).min() ?? first.longitude
        let maxLon = coordinates.map(\.longitude).max() ?? first.longitude
        let latDelta = max((maxLat - minLat) * 1.5, 0.018)
        let lonDelta = max((maxLon - minLon) * 1.5, 0.018)

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            ),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }
}

private struct FootprintMapRendererView: View {
    let footprints: [FootprintPlace]
    @Binding var selectedFootprintId: String?
    @Binding var position: MapCameraPosition

    var body: some View {
        Map(position: $position) {
            ForEach(footprints) { footprint in
                Annotation(footprint.placeName, coordinate: footprint.coordinate) {
                    Button {
                        Haptics.selection()
                        selectedFootprintId = footprint.id
                    } label: {
                        ZStack {
                            Circle()
                                .fill(selectedFootprintId == footprint.id ? Brand.pink : Brand.iconPurple)
                                .frame(width: selectedFootprintId == footprint.id ? 34 : 28, height: selectedFootprintId == footprint.id ? 34 : 28)
                                .shadow(color: .black.opacity(0.22), radius: 5, x: 0, y: 2)
                            if footprint.visitCount > 1 {
                                Text("\(footprint.visitCount)")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                            } else {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }
}

private struct FootprintPlace: Identifiable {
    let id: String
    let placeName: String
    let latestCourseTitle: String
    let latestDate: Date
    let visitCount: Int
    let coordinate: CLLocationCoordinate2D

    var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: latestDate)
    }

    static func make(from courses: [Course]) -> [FootprintPlace] {
        var grouped: [String: [FootprintVisit]] = [:]

        for course in courses where course.status == .completed {
            for place in course.places {
                guard let latitude = place.latitude, let longitude = place.longitude else { continue }
                let placeName = place.placeName ?? place.keyword
                let key = place.kakaoPlaceId
                    ?? "\(placeName)-\(place.address ?? "")-\(String(format: "%.5f", latitude))-\(String(format: "%.5f", longitude))"
                grouped[key, default: []].append(
                    FootprintVisit(
                        placeName: placeName,
                        courseTitle: course.title,
                        date: course.date,
                        coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    )
                )
            }
        }

        return grouped.compactMap { key, visits in
            guard let latest = visits.max(by: { $0.date < $1.date }) else { return nil }
            return FootprintPlace(
                id: key,
                placeName: latest.placeName,
                latestCourseTitle: latest.courseTitle,
                latestDate: latest.date,
                visitCount: visits.count,
                coordinate: latest.coordinate
            )
        }
        .sorted { $0.latestDate > $1.latestDate }
    }
}

private struct FootprintVisit {
    let placeName: String
    let courseTitle: String
    let date: Date
    let coordinate: CLLocationCoordinate2D
}
