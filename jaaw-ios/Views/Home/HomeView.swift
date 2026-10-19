import SwiftUI

/// Home dashboard: greeting, day-order hero, stat tiles and today's timeline.
struct HomeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session = SessionStore.shared
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
            viewModel.reload()
            guard !reduceMotion else { return }
            drift = true
        }
    }

    // MARK: - Greeting

    private var greetingRow: some View {
        let dashboard = viewModel.dashboard
        return HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(greetingLine)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(dashboard.dateLine)
                    .font(.system(size: 13))
                    .foregroundStyle(HomeColors.secondaryText)
            }
            Spacer(minLength: 0)
            Menu {
                if !session.profile.name.isEmpty {
                    Section {
                        Text(session.profile.name)
                        if !session.profile.registrationNumber.isEmpty {
                            Text(session.profile.registrationNumber)
                        }
                    }
                }
                Button("Logout", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                    session.logout()
                }
            } label: {
                Text(dashboard.userInitial)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(HomeColors.avatarFill, in: Circle())
                    .overlay(Circle().strokeBorder(HomeColors.avatarBorder, lineWidth: 1))
                    .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
            }
            .accessibilityLabel("Profile menu")
        }
        .padding(.horizontal, 6)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(greetingLine). \(dashboard.dateLine)")
    }

    /// "Good evening, Toshith" when a name is known, else just the greeting.
    private var greetingLine: String {
        let first = session.profile.name.split(separator: " ").first.map(String.init) ?? ""
        return first.isEmpty ? timeOfDayGreeting : "\(timeOfDayGreeting), \(first)"
    }

    private var timeOfDayGreeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Hello"
        }
    }

    // MARK: - Day hero

    private var dayHero: some View {
        let dashboard = viewModel.dashboard
        return heroBody(dashboard)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(heroGradient)
                    .overlay {
                        // Glow anchored to the top-trailing corner and drawn
                        // in-bounds, so its falloff decreases smoothly from the
                        // corner to zero. The previous overflowing blob was
                        // centred *inside* the card, so the rounded clip sliced
                        // it along the top/right edges — an obvious cut on the
                        // shorter holiday card.
                        RadialGradient(
                            colors: [HomeColors.glowPrimary.opacity(0.36), .clear],
                            center: .topTrailing,
                            startRadius: 0,
                            endRadius: 300
                        )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(HomeColors.nowBorder, lineWidth: 1)
            )
            .shadow(color: HomeColors.glowPrimary.opacity(0.32), radius: 30, y: 14)
            .padding(.top, 18)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                dashboard.isHoliday
                    ? "Holiday. No classes today."
                    : "Day order \(dashboard.dayOrderNumber). \(dashboard.classCountLine). \(dashboard.nextUpLine)."
            )
    }

    @ViewBuilder
    private func heroBody(_ dashboard: HomeDashboard) -> some View {
        if dashboard.isHoliday {
            // No class order today: a Caveat scribble instead of the day
            // number (which would otherwise be a meaningless blank glyph).
            VStack(spacing: 2) {
                Text("Holiday! ")
                    .font(JaawFonts.script(62))
                    .foregroundStyle(.white)
                    .shadow(color: HomeColors.glowPrimary.opacity(0.55), radius: 44, y: 8)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                Text("no classes")
                    .font(JaawFonts.script(28))
                    .foregroundStyle(HomeColors.secondaryText)
            }
            // Room for Caveat's flourishes, which overhang the line box.
            .padding(.horizontal, 10)
            .padding(.top, 24)
            .padding(.bottom, 30)
            .frame(maxWidth: .infinity)
        } else {
            HStack(alignment: .bottom, spacing: 14) {
                VStack(alignment: .leading, spacing: -10) {
                    Text(dashboard.dayOrderLabel.replacingOccurrences(of: "\n", with: " "))
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(1.8)
                        .textCase(.uppercase)
                        .foregroundStyle(HomeColors.tileEyebrow)
                    Text(dashboard.dayOrderNumber)
                        .font(.system(size: 112, weight: .heavy))
                        .tracking(-6)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.white)
                        .shadow(color: HomeColors.glowPrimary.opacity(0.55), radius: 50, y: 10)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 8) {
                    Text(dashboard.nextUpLine)
                        .font(.system(size: 18, weight: .heavy))
                        .tracking(0.6)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.trailing)
                    Text(dashboard.classCountLine)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(HomeColors.secondaryText)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.08), in: Capsule())
                        .overlay(Capsule().strokeBorder(HomeColors.cardBorder, lineWidth: 1))
                }
                .padding(.bottom, 10)
            }
        }
    }

    private var heroGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0x181A2C), Color(hex: 0x0C0D15)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Stat tiles

    private var statTiles: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
            spacing: 14
        ) {
            ForEach(viewModel.dashboard.tiles, id: \.title) { tile in
                StatTileCard(tile: tile, animated: appeared, reduceMotion: reduceMotion)
            }
        }
        .padding(.top, 24)
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
        .padding(.top, 34)
        .padding(.bottom, 14)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Class timeline

    private var classList: some View {
        VStack(spacing: 0) {
            if viewModel.dashboard.classes.isEmpty {
                emptyTodayCard
            } else {
                ForEach(viewModel.dashboard.classes) { entry in
                    ClassRow(entry: entry, animated: appeared, reduceMotion: reduceMotion)
                }
            }
        }
    }

    /// Scribble card shown when there is nothing on today.
    private var emptyTodayCard: some View {
        let dashboard = viewModel.dashboard
        return VStack(spacing: 4) {
            Text("nothing on today, enjoy! ")
                .font(JaawFonts.script(32))
                .foregroundStyle(HomeColors.tileEyebrow)
            Text(dashboard.isHoliday ? "No class order for today." : "No classes today.")
                .font(.system(size: 13))
                .foregroundStyle(HomeColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal, 20)
        .background(HomeColors.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(HomeColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(dashboard.isHoliday ? "No class order for today." : "No classes today.")
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
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            StatRing(
                fraction: tile.fraction,
                label: tile.percentLabel,
                color: tile.usesSecondaryRing ? HomeColors.ringSecondary : HomeColors.ringPrimary,
                animated: animated,
                reduceMotion: reduceMotion
            )
            .padding(.vertical, 14)
            Text(caption)
                .font(.system(size: 12.5))
                .lineSpacing(1.5)
                .foregroundStyle(HomeColors.secondaryText)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 186, alignment: .leading)
        .background(HomeColors.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(HomeColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
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
                .font(.system(size: 23, weight: .heavy))
                .tracking(-0.9)
                .foregroundStyle(.white)
        }
        .frame(width: 92, height: 92)
        .accessibilityValue(label)
    }
}

// MARK: - Class rows

private struct ClassRow: View {
    var entry: ClassEntry
    var animated: Bool
    var reduceMotion: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.time)
                    .font(.system(size: 15, weight: .semibold))
                Text(entry.period)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(HomeColors.secondaryText)
            }
            .frame(width: 58, alignment: .trailing)
            .padding(.top, 28)
            .foregroundStyle(HomeColors.timeText)

            railDot

            ClassCard(entry: entry, animated: animated, reduceMotion: reduceMotion)
                .padding(.vertical, 10)
        }
        .background(alignment: .leading) { railLine }
        .opacity(isDone ? 0.55 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.time) \(entry.period), \(entry.title), \(entry.detail)\(statusSuffix)")
    }

    /// Continuous timeline rail, shared with the Timetable tab. The line is a
    /// row background so it always spans the full row height (a `maxHeight`
    /// frame can't stretch inside a `ScrollView`).
    private var railLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.10))
            .frame(width: 2)
            .padding(.leading, 76)
    }

    private var railDot: some View {
        Circle()
            .fill(isDone ? Color.white.opacity(0.20) : Color.white.opacity(0.30))
            .frame(width: 10, height: 10)
            .overlay(Circle().strokeBorder(HomeColors.page, lineWidth: 3))
            .padding(.top, 32)
            .frame(width: 14)
            .accessibilityHidden(true)
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
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.title)
                        .font(.system(size: 18, weight: .heavy))
                        .tracking(-0.45)
                        .strikethrough(isDone, color: .white.opacity(0.5))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
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
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(isNow ? AnyShapeStyle(nowGradient) : AnyShapeStyle(HomeColors.card))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(isNow ? HomeColors.nowBorder : HomeColors.cardBorder, lineWidth: 1)
                )
        }
        .shadow(color: .black.opacity(isNow ? 0 : 0.35), radius: 18, y: 8)
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
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.white, in: Capsule())
        case .upcoming(let isNext) where isNext:
            Text("Up next")
                .font(.system(size: 11.5, weight: .bold))
                .foregroundStyle(HomeColors.secondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.08), in: Capsule())
                .overlay(Capsule().strokeBorder(HomeColors.cardBorder, lineWidth: 1))
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
