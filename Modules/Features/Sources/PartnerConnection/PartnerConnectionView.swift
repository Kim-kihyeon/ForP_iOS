import SwiftUI
import ComposableArchitecture
import CoreSharedUI
import Domain

public struct PartnerConnectionView: View {
    @Bindable var store: StoreOf<PartnerConnectionFeature>
    @State private var showCopied = false
    @Environment(\.dismiss) private var dismiss

    public init(store: StoreOf<PartnerConnectionFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if let user = store.connectedUser {
                        connectedCard(user)
                    } else {
                        myCodeSection
                        inputSection
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
            }

            if store.isLoading { LoadingView() }

            if showCopied {
                VStack {
                    Spacer()
                    Label("코드 복사됨", systemImage: "checkmark.circle.fill")
                        .font(Typography.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.green.opacity(0.9))
                        .clipShape(Capsule())
                        .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("파트너 연동")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Brand.pink)
        .toolbarBackground(Brand.softPink, for: .navigationBar)
        .onAppear { store.send(.onAppear) }
        .alert($store.scope(state: \.alert, action: \.alert))
    }

    // MARK: - Connected

    private func connectedCard(_ user: User) -> some View {
        VStack(spacing: 16) {
            ZStack {
                LinearGradient(
                    colors: [Brand.pink.opacity(0.85), Brand.pink.opacity(0.5), Color(red: 1.0, green: 0.6, blue: 0.4).opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))

                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 160, height: 160)
                    .blur(radius: 40)
                    .offset(x: 60, y: -40)

                VStack(spacing: 20) {
                    HStack(spacing: 0) {
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 64, height: 64)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 26, weight: .medium))
                                    .foregroundStyle(.white)
                            }

                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 32, height: 32)
                            Image(systemName: "heart.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Brand.pink)
                        }
                        .offset(x: 0)
                        .zIndex(1)

                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 64, height: 64)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 26, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                    }

                    VStack(spacing: 6) {
                        Text(user.nickname)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)

                        Text("파트너와 연동되어 있어요")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    if !user.preferredCategories.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(user.preferredCategories.prefix(5), id: \.self) { cat in
                                Text(cat)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(Spacing.lg)
            }
            .frame(maxWidth: .infinity)

            Button {
                store.send(.disconnectTapped)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "link.badge.minus")
                        .font(.system(size: 14, weight: .medium))
                    Text("연동 해제")
                        .font(Typography.body.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color(.systemRed).opacity(0.1))
                .foregroundStyle(Color(.systemRed))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - My Code

    private var myCodeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("내 초대 코드")
                .font(.system(.caption2, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 16) {
                Text("파트너에게 아래 코드를 알려주세요")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text(store.myCode.isEmpty ? "------" : store.myCode)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundStyle(Brand.pink)
                    .tracking(8)

                HStack(spacing: 10) {
                    Button {
                        UIPasteboard.general.string = store.myCode
                        withAnimation(.spring(response: 0.3)) { showCopied = true }
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                            await MainActor.run {
                                withAnimation { showCopied = false }
                            }
                        }
                    } label: {
                        Label("복사", systemImage: "doc.on.doc")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Brand.pink)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(Brand.softPink)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    ShareLink(item: "ForP 앱에서 파트너 연동해요! 코드: \(store.myCode)") {
                        Label("공유", systemImage: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.lg)
            .cardStyle()
        }
    }

    // MARK: - Input

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("파트너 코드 입력")
                .font(.system(.caption2, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 12) {
                TextField("코드 6자리 입력", text: $store.inputCode)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .tracking(4)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(Spacing.md)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    store.send(.connectTapped)
                } label: {
                    Text("연동하기")
                        .font(Typography.body.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(store.inputCode.isEmpty ? Color(.tertiaryLabel) : Brand.pink)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: store.inputCode.isEmpty ? .clear : Brand.pink.opacity(0.3), radius: 10, x: 0, y: 4)
                }
                .disabled(store.inputCode.isEmpty)
                .buttonStyle(.plain)
            }
            .padding(Spacing.md)
            .cardStyle()
        }
    }
}
