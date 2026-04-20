import SwiftUI
import ComposableArchitecture
import CoreSharedUI
import Domain

public struct CourseGenerateView: View {
    @Bindable var store: StoreOf<CourseGenerateFeature>

    public init(store: StoreOf<CourseGenerateFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        locationSection
                        dateSection
                        placeCountSection
                        modeSection
                        memoSection
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.sm)
                }

                generateButtonBar
            }

            if store.isGenerating {
                LoadingView()
            }
        }
        .navigationTitle("코스 만들기")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Brand.pink)
        .toolbarBackground(Brand.softPink, for: .navigationBar)
        .alert("오류", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.send(.binding(.set(\.errorMessage, nil))) } }
        )) {
            Button("확인") { store.send(.binding(.set(\.errorMessage, nil))) }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    // MARK: - Location

    private var locationSection: some View {
        FormCard {
            HStack(spacing: Spacing.md) {
                iconBadge("location.fill", color: Brand.pink)
                VStack(alignment: .leading, spacing: 4) {
                    Text("어디서?")
                        .font(Typography.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField("홍대, 강남, 성수동...", text: $store.location)
                        .font(Typography.body.weight(.medium))
                }
            }
        }
    }

    // MARK: - Date

    private var dateSection: some View {
        FormCard {
            HStack(spacing: Spacing.md) {
                iconBadge("calendar", color: Color(red: 0.4, green: 0.6, blue: 1.0))
                Text("언제?")
                    .font(Typography.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                DatePicker("", selection: $store.date, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "ko_KR"))
                    .fixedSize()
            }
            let daysFromNow = Calendar.current.dateComponents([.day], from: Date(), to: store.date).day ?? 0
            HStack(spacing: 4) {
                Image(systemName: daysFromNow <= 4 ? "cloud.sun.fill" : "thermometer.medium")
                    .font(.caption2)
                Text(daysFromNow <= 4 ? "실제 날씨 예보가 코스에 반영돼요" : "계절 기반으로 반영돼요")
                    .font(Typography.caption2)
            }
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    // MARK: - Place Count

    private var placeCountSection: some View {
        FormCard {
            HStack(spacing: Spacing.md) {
                iconBadge("mappin.and.ellipse", color: Color(red: 0.6, green: 0.4, blue: 1.0))
                Text("몇 곳?")
                    .font(Typography.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: Spacing.lg) {
                    Button {
                        if store.placeCount > 2 {
                            store.send(.binding(.set(\.placeCount, store.placeCount - 1)))
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(store.placeCount > 2 ? Brand.pink : Color(.tertiaryLabel))
                    }
                    Text("\(store.placeCount)")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .frame(minWidth: 24)
                    Button {
                        if store.placeCount < 6 {
                            store.send(.binding(.set(\.placeCount, store.placeCount + 1)))
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(store.placeCount < 6 ? Brand.pink : Color(.tertiaryLabel))
                    }
                }
            }
        }
    }

    // MARK: - Mode

    private var modeSection: some View {
        FormCard {
            HStack(spacing: Spacing.md) {
                iconBadge("list.bullet.rectangle", color: Color(red: 0.2, green: 0.78, blue: 0.65))
                Text("코스 타입")
                    .font(Typography.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 8) {
                modeChip("순서형", subtitle: "A → B → C", mode: .ordered)
                modeChip("자유형", subtitle: "원하는 순서로", mode: .list)
            }
            .padding(.leading, 52)
        }
    }

    private func modeChip(_ title: String, subtitle: String, mode: CourseMode) -> some View {
        let selected = store.mode == mode
        return Button {
            store.send(.binding(.set(\.mode, mode)))
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.caption.weight(.semibold))
                Text(subtitle)
                    .font(Typography.caption2)
                    .foregroundStyle(selected ? Brand.pink.opacity(0.8) : Color(.tertiaryLabel))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? Brand.softPink : Color(.tertiarySystemFill))
            .foregroundStyle(selected ? Brand.pink : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                if selected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Brand.pink.opacity(0.4), lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Memo

    private var memoSection: some View {
        FormCard {
            HStack(alignment: .top, spacing: Spacing.md) {
                iconBadge("sparkles", color: Color(red: 1.0, green: 0.6, blue: 0.2))
                VStack(alignment: .leading, spacing: 4) {
                    Text("요청사항")
                        .font(Typography.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField("실내 위주로, 예산 10만원, 프로포즈 예정...", text: $store.memo, axis: .vertical)
                        .font(Typography.body)
                        .lineLimit(2...4)
                }
            }
        }
    }

    // MARK: - Generate Button

    private var generateButtonBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.5)
            Button {
                store.send(.generateTapped)
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                    Text("코스 생성하기")
                        .font(Typography.body.weight(.bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(store.location.isEmpty ? Color(.tertiaryLabel) : Brand.pink)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: store.location.isEmpty ? .clear : Brand.pink.opacity(0.35), radius: 12, x: 0, y: 4)
            }
            .disabled(store.location.isEmpty)
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.lg)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Helpers

    private func iconBadge(_ systemName: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.12))
                .frame(width: 36, height: 36)
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

private struct FormCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            content
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
