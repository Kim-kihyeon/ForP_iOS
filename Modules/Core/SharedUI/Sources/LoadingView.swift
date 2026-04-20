import SwiftUI

public struct LoadingView: View {
    public init() {}

    public var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .scaleEffect(1.5)
        }
    }
}

public struct CourseLoadingView: View {
    @State private var phase = 0
    @State private var messageIndex = 0
    @State private var dotCount = 0

    private let messages = [
        "맛집 찾는 중",
        "동선 그리는 중",
        "코스 짜는 중",
        "설레는 날 준비 중",
        "딱 맞는 장소 고르는 중",
    ]

    public init() {}

    public var body: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
                .background(.ultraThinMaterial)

            VStack(spacing: 20) {
                heartsRow

                VStack(spacing: 6) {
                    Text(messages[messageIndex] + String(repeating: ".", count: dotCount + 1))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: messageIndex)

                    Text("잠깐만 기다려줘요 💕")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 28)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 8)
        }
        .onAppear {
            startAnimations()
        }
    }

    private var heartsRow: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { i in
                Text("🩷")
                    .font(.system(size: 28))
                    .scaleEffect(phase == i ? 1.35 : 0.85)
                    .opacity(phase == i ? 1.0 : 0.45)
                    .animation(
                        .spring(response: 0.35, dampingFraction: 0.5),
                        value: phase
                    )
            }
        }
    }

    private func startAnimations() {
        Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
            phase = (phase + 1) % 3
        }
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            dotCount = (dotCount + 1) % 3
        }
        Timer.scheduledTimer(withTimeInterval: 2.2, repeats: true) { _ in
            withAnimation {
                messageIndex = (messageIndex + 1) % messages.count
            }
        }
    }
}
