import SwiftUI

/// Home dashboard: greeting, day-order hero, stat tiles and today's timeline.
struct HomeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = HomeViewModel()
    @State private var appeared = false
    @State private var drift = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                greetingRow
                    .rise(appeared: appeared, delay: 0, reduceMotion: reduceMotion)
                dayHero
                    .rise(appeared: appeared, delay: 0.08, reduceMotion: reduceMotion)
                statTiles
                    .rise(appeared: appeared, delay: 0.16, reduceMotion: reduceMotion)
                sectionHeader
                    .rise(appeared: appeared, delay: 0.24, reduceMotion: reduceMotion)
                classList
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(HomeBackground(drift: drift, reduceMotion: reduceMotion))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            appeared = true
            guard !reduceMotion else { return }
            drift = true
        }
    }

    // MARK: - Greeting

    private var greetingRow: some View {
        let dashboard = viewModel.dashboard
        return HStack {
            Text(dashboard.dateLine)
                .font(.system(size: 15))
                .foregroundStyle(HomeColors.secondaryText)
            Spacer(minLength: 0)
            Text(dashboard.userInitial)
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(HomeColors.avatarFill, in: Circle())
                .overlay(Circle().strokeBorder(HomeColors.avatarBorder, lineWidth: 1))
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(dashboard.dateLine)
    }

    // MARK: - Day hero

    private var dayHero: some View {
        let dashboard = viewModel.dashboard
        return HStack(alignment: .bottom, spacing: 14) {
            Text(dashboard.dayOrderLabel)
                .font(.system(size: 26, weight: .medium))
                .tracking(-0.8)
                .foregroundStyle(HomeColors.secondaryText)
                .padding(.bottom, 16)
            Text(dashboard.dayOrderNumber)
                .font(.system(size: 140, weight: .heavy))
//                .tracking(-11)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .minimumScaleFactor(0.6)
                .padding(.trailing, 12)
                .foregroundStyle(.white)
                .shadow(color: HomeColors.glowPrimary.opacity(0.55), radius: 60, y: 10)
                .accessibilityLabel("Day order \(dashboard.dayOrderNumber)")
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 4) {
                Text(dashboard.classCountLine)
                    .font(.system(size: 14))
                    .foregroundStyle(HomeColors.secondaryText)
                Text(dashboard.nextUpLine)
                    .font(.system(size: 20, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 14)
        }
        .padding(.horizontal, 6)
        .padding(.top, 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Day order \(dashboard.dayOrderNumber). \(dashboard.classCountLine). \(dashboard.nextUpLine).")
    }

    // MARK: - Stat tiles

    private var statTiles: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            ForEach(viewModel.dashboard.tiles, id: \.title) { tile in
                StatTileCard(tile: tile, animated: appeared, reduceMotion: reduceMotion)
            }
        }
        .padding(.top, 22)
    }

    // MARK: - Section header

    private var sectionHeader: some View {
        let dashboard = viewModel.dashboard
        return HStack(alignment: .lastTextBaseline) {
            Text(dashboard.todayTitle)
                .font(.system(size: 28, weight: .heavy))
                .tracking(-1.1)
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            Text(dashboard.todayTrailing)
                .font(.system(size: 14))
                .foregroundStyle(HomeColors.faintText)
        }
        .padding(.horizontal, 6)
        .padding(.top, 30)
        .padding(.bottom, 12)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Class timeline

    private var classList: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.dashboard.classes) { entry in
                ClassRow(entry: entry, animated: appeared, reduceMotion: reduceMotion)
            }
        }
    }
}

// MARK: - Background

/// Near-black base with a restrained blue ambience: a glow pooled top-right,
/// a faint one mid-left, and dim drifting orbs for depth.
private struct HomeBackground: View {
    var drift: Bool
    var reduceMotion: Bool

    var body: some View {
        ZStack {
            HomeColors.page
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height
                ZStack {
                    RadialGradient(
                        colors: [HomeColors.glowPrimary.opacity(0.42), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: w * 0.62
                    )
                    .frame(width: w * 1.24, height: w * 1.24)
                    .position(x: w * 0.85, y: h * -0.06)
                    RadialGradient(
                        colors: [HomeColors.glowSecondary.opacity(0.16), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: w * 0.4
                    )
                    .frame(width: w * 0.8, height: w * 0.8)
                    .position(x: w * -0.05, y: h * 0.42)
                    ambientOrb(
                        color: HomeColors.orbBright,
                        size: CGSize(width: 340, height: 200),
                        center: CGPoint(x: 230, y: 40),
                        opacity: 0.3,
                        duration: 26
                    )
                    ambientOrb(
                        color: HomeColors.orbBlue,
                        size: CGSize(width: 380, height: 300),
                        center: CGPoint(x: 50, y: 210),
                        opacity: 0.12,
                        duration: 18
                    )
                    ambientOrb(
                        color: HomeColors.orbBlue,
                        size: CGSize(width: 300, height: 340),
                        center: CGPoint(x: w - 20, y: 650),
                        opacity: 0.1,
                        duration: 22
                    )
                    RadialGradient(
                        colors: [.white.opacity(0.07), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: w * 0.4
                    )
                    .frame(width: w * 0.8, height: w * 0.8)
                    .position(x: w * 0.78, y: h * 0.02)
                    .blendMode(.screen)
                }
                .frame(width: w, height: h)
            }
        }
        .ignoresSafeArea()
    }

    private func ambientOrb(
        color: Color,
        size: CGSize,
        center: CGPoint,
        opacity: Double,
        duration: Double
    ) -> some View {
        Ellipse()
            .fill(color)
            .frame(width: size.width, height: size.height)
            .opacity(opacity)
            .blur(radius: 46)
            .position(center)
            .offset(x: drift ? 34 : 0, y: drift ? 26 : 0)
            .scaleEffect(drift ? 1.08 : 1.0)
            .animation(
                reduceMotion
                    ? nil
                    : .easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: drift
            )
    }
}

// MARK: - Stat tile

private struct StatTileCard: View {
    var tile: StatTile
    var animated: Bool
    var reduceMotion: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(tile.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(HomeColors.tileEyebrow)
            StatRing(
                fraction: tile.fraction,
                label: tile.percentLabel,
                color: tile.usesSecondaryRing ? HomeColors.ringSecondary : HomeColors.ringPrimary,
                animated: animated,
                reduceMotion: reduceMotion
            )
            .padding(.vertical, 12)
            Text(caption)
                .font(.system(size: 12.5))
                .lineSpacing(1)
                .foregroundStyle(HomeColors.secondaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 176, alignment: .leading)
        .background(HomeColors.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(HomeColors.cardBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tile.title) \(tile.percentLabel). \(tile.captionLeading)\(tile.captionBold)\(tile.captionTrailing)")
    }

    private var caption: AttributedString {
        var result = AttributedString(tile.captionLeading)
        var bold = AttributedString(tile.captionBold)
        bold.inlinePresentationIntent = .stronglyEmphasized
        bold.foregroundColor = .white
        result += bold
        result += AttributedString(tile.captionTrailing)
        return result
    }
}

private struct StatRing: View {
    var fraction: Double
    var label: String
    var color: Color
    var animated: Bool
    var reduceMotion: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(HomeColors.ringTrack, lineWidth: 8)
            Circle()
                .trim(from: 0, to: animated || reduceMotion ? fraction : 0)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(
                    reduceMotion ? nil : .easeOut(duration: 1.2).delay(0.35),
                    value: animated
                )
            Text(label)
                .font(.system(size: 22, weight: .heavy))
                .tracking(-0.9)
                .foregroundStyle(.white)
        }
        .frame(width: 84, height: 84)
        .accessibilityValue(label)
    }
}

// MARK: - Class rows

private struct ClassRow: View {
    var entry: ClassEntry
    var animated: Bool
    var reduceMotion: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .trailing, spacing: 3) {
                Text(entry.time)
                    .font(.system(size: 15, weight: .semibold))
                Text(entry.period)
                    .font(.system(size: 11.5))
                    .foregroundStyle(HomeColors.secondaryText)
            }
            .frame(width: 52, alignment: .trailing)
            .padding(.top, 16)
            .foregroundStyle(HomeColors.timeText)

            ClassCard(entry: entry, animated: animated, reduceMotion: reduceMotion)
        }
        .opacity(isDone ? 0.55 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.time) \(entry.period), \(entry.title), \(entry.detail)\(statusSuffix)")
    }

    private var isDone: Bool {
        if case .done = entry.status { return true }
        return false
    }

    private var statusSuffix: String {
        switch entry.status {
        case .done: return ", completed"
        case .now: return ", in progress now"
        case .upcoming(let isNext): return isNext ? ", up next" : ""
        case .later: return ""
        }
    }
}

private struct ClassCard: View {
    var entry: ClassEntry
    var animated: Bool
    var reduceMotion: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(entry.title)
                        .font(.system(size: 18, weight: .heavy))
                        .tracking(-0.45)
                        .strikethrough(isDone, color: .white.opacity(0.5))
                    Text(entry.detail)
                        .font(.system(size: 13))
                        .foregroundStyle(isNow ? HomeColors.nowDetail : HomeColors.secondaryText)
                }
                Spacer(minLength: 0)
                statusTag
            }
            if case .now(let progress) = entry.status {
                GeometryReader { proxy in
                    Capsule()
                        .fill(.white.opacity(0.25))
                        .frame(height: 5)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(.white)
                                .frame(width: proxy.size.width * progress, height: 5)
                                .scaleEffect(x: animated || reduceMotion ? 1 : 0, anchor: .leading)
                                .animation(
                                    reduceMotion ? nil : .easeOut(duration: 1.1).delay(0.5),
                                    value: animated
                                )
                        }
                }
                .frame(height: 5)
                .padding(.top, 12)
                .accessibilityValue("\(Int(progress * 100)) percent elapsed")
            }
        }
        .padding(15)
        .padding(.horizontal, 1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(isNow ? AnyShapeStyle(nowGradient) : AnyShapeStyle(HomeColors.card))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(isNow ? HomeColors.nowBorder : HomeColors.cardBorder, lineWidth: 1)
                )
        }
        .shadow(
            color: isNow ? HomeColors.glowPrimary.opacity(0.8) : .clear,
            radius: 30,
            y: 10
        )
    }

    private var isDone: Bool {
        if case .done = entry.status { return true }
        return false
    }

    private var isNow: Bool {
        if case .now = entry.status { return true }
        return false
    }

    private var nowGradient: LinearGradient {
        LinearGradient(
            colors: [HomeColors.nowStart, HomeColors.nowEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    private var statusTag: some View {
        switch entry.status {
        case .now:
            Text("Now")
                .font(.system(size: 11.5, weight: .bold))
                .foregroundStyle(HomeColors.tagBlue)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        case .upcoming(let isNext) where isNext:
            Text("Up next")
                .font(.system(size: 12))
                .foregroundStyle(HomeColors.secondaryText)
                .padding(.top, 1)
        default:
            EmptyView()
        }
    }
}

// MARK: - Staggered entrance

private extension View {
    func rise(appeared: Bool, delay: Double, reduceMotion: Bool) -> some View {
        modifier(RiseIn(appeared: appeared, delay: delay, reduceMotion: reduceMotion))
    }
}

private struct RiseIn: ViewModifier {
    var appeared: Bool
    var delay: Double
    var reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(appeared || reduceMotion ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 10)
            .animation(
                reduceMotion ? nil : .easeOut(duration: 0.55).delay(delay),
                value: appeared
            )
    }
}

#Preview("Home") {
    NavigationStack {
        HomeView()
    }
}
