import SwiftUI
import MapKit
import CoreLocation
import CoreSharedUI
import Domain

struct DepartureCalculatorView: View {
    let places: [CoursePlace]
    @Environment(\.dismiss) private var dismiss
    @State private var desiredStartTime: Date = {
        Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date()
    }()
    @State private var result: DepartureResult? = nil
    @State private var isCalculating = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 시작 시각 입력
                    VStack(alignment: .leading, spacing: 8) {
                        Text("첫 장소 도착 목표 시각")
                            .font(Typography.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        HStack {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(Brand.pink)
                                .frame(width: 36, height: 36)
                                .background(Brand.softPink)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            DatePicker("", selection: $desiredStartTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .environment(\.locale, Locale(identifier: "ko_KR"))
                                .tint(Brand.pink)

                            Spacer()
                        }
                        .padding(Spacing.md)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // 계산 버튼
                    Button {
                        Task {
                            isCalculating = true
                            let r = await calculateWithLocation()
                            withAnimation(.spring(response: 0.4)) {
                                result = r
                                isCalculating = false
                            }
                            Haptics.notification(.success)
                        }
                    } label: {
                        Group {
                            if isCalculating {
                                ProgressView().tint(.white)
                            } else {
                                Text("계산하기").font(Typography.body.weight(.bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Brand.pink)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Brand.pink.opacity(0.3), radius: 8, x: 0, y: 3)
                    }
                    .disabled(isCalculating)

                    // 결과
                    if let result {
                        resultCard(result)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("출발 시각 계산")
            .navigationBarTitleDisplayMode(.inline)
            .tint(Brand.pink)
            .toolbarBackground(Brand.softPink, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(Brand.pink)
                }
            }
        }
    }

    // MARK: - Result Card

    private func resultCard(_ result: DepartureResult) -> some View {
        VStack(spacing: 16) {
            // 출발 시각 헤드라인
            VStack(spacing: 6) {
                Text("집에서 출발 시각")
                    .font(Typography.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(formatTime(result.departureTime))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(Brand.pink)
                Text("첫 장소까지 약 \(result.travelMinutes)분 소요")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(Brand.softPink)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // 타임라인
            VStack(alignment: .leading, spacing: 0) {
                Text("예상 일정")
                    .font(Typography.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 12)

                ForEach(Array(result.timeline.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 14) {
                        // 시간
                        Text(formatTime(item.arrival))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Brand.pink)
                            .frame(width: 52, alignment: .leading)

                        // 타임라인 라인
                        VStack(spacing: 0) {
                            Circle()
                                .fill(Brand.pink)
                                .frame(width: 8, height: 8)
                            if index < result.timeline.count - 1 {
                                Rectangle()
                                    .fill(Brand.pink.opacity(0.2))
                                    .frame(width: 2)
                                    .frame(maxHeight: .infinity)
                            }
                        }

                        // 장소 정보
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.name)
                                .font(Typography.caption.weight(.semibold))
                            Text("약 \(item.dwell)분")
                                .font(Typography.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.bottom, index < result.timeline.count - 1 ? 20 : 0)
                    }
                }
            }
            .padding(Spacing.md)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Calculation

    private func calculateWithLocation() async -> DepartureResult {
        let sorted = places.sorted { $0.order < $1.order }
        let travelBetween = 15

        var travelToFirst = 20
        if let first = sorted.first, let lat = first.latitude, let lon = first.longitude {
            let dest = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            travelToFirst = await fetchTravelMinutes(to: dest)
        }

        return buildResult(sorted: sorted, travelToFirst: travelToFirst, travelBetween: travelBetween)
    }

    private func fetchTravelMinutes(to destination: CLLocationCoordinate2D) async -> Int {
        let fetcher = LocationFetcher()
        guard let userLocation = await fetcher.fetchCurrentLocation() else { return 20 }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile

        let minutes: Int = await withCheckedContinuation { cont in
            MKDirections(request: request).calculate { response, _ in
                let seconds = response?.routes.first?.expectedTravelTime ?? 1200
                cont.resume(returning: max(1, Int(seconds / 60)))
            }
        }
        return minutes
    }

    private func buildResult(sorted: [CoursePlace], travelToFirst: Int, travelBetween: Int) -> DepartureResult {
        let travelToFirst = travelToFirst
        let travelBetween = travelBetween

        var timeline: [(order: Int, name: String, arrival: Date, dwell: Int)] = []
        var currentTime = desiredStartTime

        for (index, place) in sorted.enumerated() {
            let dwell = dwellMinutes(for: place.category)
            timeline.append((
                order: place.order,
                name: place.placeName ?? place.keyword,
                arrival: currentTime,
                dwell: dwell
            ))
            if index < sorted.count - 1 {
                currentTime = currentTime.addingTimeInterval(Double(dwell + travelBetween) * 60)
            }
        }

        let departure = desiredStartTime.addingTimeInterval(-Double(travelToFirst) * 60)
        return DepartureResult(departureTime: departure, travelMinutes: travelToFirst, timeline: timeline)
    }

    private func dwellMinutes(for category: String) -> Int {
        if category.contains("카페") || category.contains("커피") || category.contains("디저트") { return 60 }
        if category.contains("레스토랑") || category.contains("식당") || category.contains("맛집")
            || category.contains("한식") || category.contains("일식") || category.contains("중식")
            || category.contains("양식") || category.contains("이탈리안") || category.contains("브런치") { return 75 }
        if category.contains("바") || category.contains("펍") || category.contains("와인") { return 90 }
        if category.contains("영화") { return 120 }
        if category.contains("쇼핑") { return 60 }
        if category.contains("공원") || category.contains("자연") || category.contains("산책") { return 45 }
        return 60
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "a h:mm"
        return f.string(from: date)
    }
}

// MARK: - Model

private struct DepartureResult {
    var departureTime: Date
    var travelMinutes: Int
    var timeline: [(order: Int, name: String, arrival: Date, dwell: Int)]
}

// MARK: - Location Fetcher

private final class LocationFetcher: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?

    func fetchCurrentLocation() async -> CLLocation? {
        await withCheckedContinuation { cont in
            continuation = cont
            manager.delegate = self
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedAlways, .authorizedWhenInUse:
                manager.requestLocation()
            case .denied, .restricted:
                resume(nil)
            @unknown default:
                resume(nil)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        resume(locations.last)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        resume(nil)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            resume(nil)
        case .notDetermined:
            break
        @unknown default:
            resume(nil)
        }
    }

    private func resume(_ location: CLLocation?) {
        continuation?.resume(returning: location)
        continuation = nil
    }
}
