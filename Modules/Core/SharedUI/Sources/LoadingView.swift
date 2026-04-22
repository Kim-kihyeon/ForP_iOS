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
    @State private var messageIndex = 0
    @State private var ring1: CGFloat = 1.0
    @State private var ring2: CGFloat = 1.0
    @State private var ring3: CGFloat = 1.0
    @State private var iconOffset: CGFloat = 0

    private let messages = [
        "맛집을 살펴보고 있어요",
        "최적 동선을 그리고 있어요",
        "코스를 완성하고 있어요",
        "설레는 순간을 준비 중이에요",
        "딱 맞는 장소를 고르고 있어요",
    ]

    public init() {}

    public var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 52) {
                ZStack {
                    rippleRing(scale: ring1, size: 140, color: Brand.pink.opacity(0.12))
                    rippleRing(scale: ring2, size: 108, color: Brand.pink.opacity(0.20))
                    rippleRing(scale: ring3, size: 84, color: Brand.pink.opacity(0.30))

                    Circle()
                        .fill(RadialGradient(
                            colors: [Brand.softPink, Brand.pink.opacity(0.06)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 36
                        ))
                        .frame(width: 74, height: 74)
                        .shadow(color: Brand.pink.opacity(0.28), radius: 20, x: 0, y: 6)

                    Image(systemName: "sparkles")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(Brand.pink)
                        .offset(y: iconOffset)
                }
                .frame(width: 160, height: 160)

                VStack(spacing: 14) {
                    Text(messages[messageIndex])
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .id(messageIndex)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 10)),
                            removal: .opacity.combined(with: .offset(y: -10))
                        ))

                    Text("AI가 맞춤 데이트 코스를 만들고 있어요")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 7) {
                        ForEach(0..<5, id: \.self) { i in
                            Capsule()
                                .fill(i == messageIndex % 5 ? Brand.pink : Brand.pink.opacity(0.2))
                                .frame(width: i == messageIndex % 5 ? 22 : 6, height: 6)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: messageIndex)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 40)
        }
        .task {
            withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) { ring1 = 1.55 }
            try? await Task.sleep(nanoseconds: 600_000_000)
            withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) { ring2 = 1.45 }
            try? await Task.sleep(nanoseconds: 600_000_000)
            withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) { ring3 = 1.30 }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { iconOffset = -7 }

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_200_000_000)
                withAnimation(.easeInOut(duration: 0.4)) {
                    messageIndex = (messageIndex + 1) % messages.count
                }
            }
        }
    }

    private func rippleRing(scale: CGFloat, size: CGFloat, color: Color) -> some View {
        Circle()
            .stroke(color, lineWidth: 1.5)
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .opacity(Double(max(0, 1.0 - (scale - 1.0) * 2)))
    }
}
