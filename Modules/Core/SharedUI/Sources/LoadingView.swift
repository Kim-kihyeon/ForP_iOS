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
        "너무 뻔한 곳은 살짝 빼고 있어요",
        "동선이 꼬이지 않게 맞춰보고 있어요",
        "오늘 분위기에 맞는 곳만 고르는 중이에요",
        "괜찮은 후보만 남겨보고 있어요",
        "마지막 조합을 다듬고 있어요",
    ]

    public init() {}

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.90, green: 0.15, blue: 0.35),
                    Brand.pink,
                    Color(red: 1.0, green: 0.58, blue: 0.38)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 280)
                .blur(radius: 60)
                .offset(x: 100, y: -200)

            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 200)
                .blur(radius: 50)
                .offset(x: -80, y: 200)

            VStack(spacing: 52) {
                ZStack {
                    rippleRing(scale: ring1, size: 140, color: Color.white.opacity(0.12))
                    rippleRing(scale: ring2, size: 108, color: Color.white.opacity(0.18))
                    rippleRing(scale: ring3, size: 84, color: Color.white.opacity(0.25))

                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 74, height: 74)

                    Image(systemName: "sparkles")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(.white)
                        .offset(y: iconOffset)
                        .symbolEffect(.pulse.wholeSymbol)
                }
                .frame(width: 160, height: 160)

                VStack(spacing: 14) {
                    Text(messages[messageIndex])
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .id(messageIndex)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 10)),
                            removal: .opacity.combined(with: .offset(y: -10))
                        ))

                    Text("조건에 맞는 장소를 차분히 고르고 있어요")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.75))

                    HStack(spacing: 7) {
                        ForEach(0..<5, id: \.self) { i in
                            Capsule()
                                .fill(i == messageIndex % 5 ? Color.white : Color.white.opacity(0.3))
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

public struct CourseRegenerationLoadingView: View {
    @State private var messageIndex = 0
    @State private var rotation: Double = 0
    @State private var pulse: CGFloat = 1.0

    private let messages = [
        "고정한 장소는 그대로 둘게요",
        "비슷한 곳은 조용히 피해볼게요",
        "이번엔 조금 다른 분위기로 맞추는 중이에요",
        "동선이 자연스러운지 확인하고 있어요",
    ]

    public init() {}

    public var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .stroke(Brand.pink.opacity(0.16), lineWidth: 14)
                        .frame(width: 112, height: 112)

                    Circle()
                        .trim(from: 0.12, to: 0.72)
                        .stroke(
                            AngularGradient(colors: [Brand.pink, Brand.iconOrange, Brand.pink], center: .center),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .frame(width: 112, height: 112)
                        .rotationEffect(.degrees(rotation))

                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Brand.pink)
                        .scaleEffect(pulse)
                }

                VStack(spacing: 10) {
                    Text(messages[messageIndex])
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .id(messageIndex)
                        .transition(.opacity.combined(with: .offset(y: 8)))

                    Text("고정한 곳은 지키고, 나머지만 새로 보고 있어요")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 36)
        }
        .task {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) { rotation = 360 }
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) { pulse = 1.08 }

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation(.easeInOut(duration: 0.3)) {
                    messageIndex = (messageIndex + 1) % messages.count
                }
            }
        }
    }
}
