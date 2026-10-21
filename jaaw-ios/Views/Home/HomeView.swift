import SwiftUI

/// Home dashboard, mockup-aligned: the landing backdrop (gradient + `bg1.mp4`)
/// carries the day order and today's date, and a white sheet — its top edge
/// stepping down where the mockup's edit button once sat — rolls to the foot of
/// the screen and holds today's timetable.
struct HomeView: View {
    /// Opens the profile page.
    var onOpenProfile: () -> Void = { }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session = SessionStore.shared
    @State private var viewModel = HomeViewModel()
    @State private var appeared = false
    @State private var drift = false

    var body: some View {
        VStack(spacing: 0) {
            header
                .rise(appeared: appeared, delay: 0, reduceMotion: reduceMotion)
            // The sheet is a direct child of the root stack — not inside a
            // ScrollView — so its background can ignore the bottom safe area
            // and paint under the tab bar. Only the rows scroll, inside it.
            timetableSheet
                .rise(appeared: appeared, delay: 0.1, reduceMotion: reduceMotion)
        }
        .background {
            ZStack {
                JaawBackground(configuration: JaawBackground.home, drift: drift, reduceMotion: reduceMotion)
                JaawVideoBackdrop(
                    resource: JaawEntryVideo.landing,
                    reduceMotion: reduceMotion,
                    isActive: TabActivity.shared.isActive(.home)
                )
            }
            .allowsHitTesting(false)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            appeared = true
            viewModel.reload()
            guard !reduceMotion else { return }
            drift = true
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            greetingRow
            dayOrderHero
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 22)
            dateHeading
                .padding(.top, 2)
        }
        .padding(.horizontal, 26)
        .padding(.top, 10)
        // Room for the sheet's stepped edge to bite into the backdrop.
        .padding(.bottom, 34)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Greeting takes the spot the mockup's back chevron used to hold; the
    /// profile avatar takes the notification bell's.
    private var greetingRow: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(greetingLine)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(JaawColors.ice.opacity(0.88))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            profileButton
        }
        .accessibilityElement(children: .contain)
    }

    /// Opens the profile page.
    private var profileButton: some View {
        Button {
            onOpenProfile()
        } label: {
            Text(viewModel.dashboard.userInitial)
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(JaawColors.ctaTint)
                .frame(width: 42, height: 42)
                .background(.white, in: Circle())
                .shadow(color: Color(red: 0, green: 0, blue: 70 / 255, opacity: 0.5), radius: 14, y: 7)
        }
        .buttonStyle(PressScaleStyle(scale: 0.92))
        .accessibilityLabel("Profile")
    }

    /// The cake illustration's slot: the day order number, big and trailing.
    private var dayOrderHero: some View {
        let dashboard = viewModel.dashboard
        return VStack(alignment: .trailing, spacing: -6) {
            Text(dashboard.dayOrderLabel)
                .font(.system(size: 12, weight: .heavy))
                .tracking(2.1)
                .textCase(.uppercase)
                .foregroundStyle(JaawColors.ice.opacity(0.72))
            if dashboard.isHoliday {
                Text("Holiday")
                    .font(JaawFonts.script(56))
                    .foregroundStyle(.white)
                    .padding(.top, 6)
                    .padding(.trailing, 6)
                    .shadow(color: Color(red: 0, green: 0, blue: 90 / 255, opacity: 0.45), radius: 34, y: 8)
            } else {
                Text(dashboard.dayOrderNumber + " ")
                    .font(.system(size: 104, weight: .heavy))
                    .tracking(-6)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(.white)
                    .shadow(color: Color(red: 0, green: 0, blue: 90 / 255, opacity: 0.5), radius: 40, y: 8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            dashboard.isHoliday
                ? "Holiday, no class order today"
                : "Day order \(dashboard.dayOrderNumber)"
        )
    }

    private var dateHeading: some View {
        let dashboard = viewModel.dashboard
        return VStack(alignment: .leading, spacing: -12) {
            Text(dashboard.monthDayLine)
                .font(.system(size: 58, weight: .heavy))
                .foregroundStyle(.white)
            Text(dashboard.weekdayLine)
                .font(.system(size: 58, weight: .regular))
                .foregroundStyle(JaawColors.ice)
        }
        .tracking(-2.4)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .shadow(color: Color(red: 0, green: 0, blue: 90 / 255, opacity: 0.35), radius: 30, y: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(dashboard.monthDayLine), \(dashboard.weekdayLine)")
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

    // MARK: - Timetable sheet

    private var timetableSheet: some View {
        let dashboard = viewModel.dashboard
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Two lines so the title lives entirely inside the sheet's
                // raised left half — a single line at this size would run past
                // the step and hang over the backdrop.
                VStack(alignment: .leading, spacing: -2) {
                    Text("Today's")
                    Text("timetable")
                }
                .font(.system(size: 26, weight: .heavy))
                .tracking(-1)
                .foregroundStyle(CardPalette.title)
                .accessibilityAddTraits(.isHeader)

                Spacer(minLength: 0)

                Text(dashboard.todayTrailing)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CardPalette.body)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(CardPalette.divider.opacity(0.7), in: Capsule())
                    // Drops the badge clear of the sheet's lowered right half.
                    .padding(.top, TimetableSheetShape.stepDrop - 12)
            }
            .padding(.bottom, 10)

            Text(summaryLine)
                .font(.system(size: 14))
                .foregroundStyle(CardPalette.body)
                .padding(.top, 6)

            hairline
                .padding(.top, 18)

            // Only the rows scroll; the sheet's frame and background stay put.
            ScrollView {
                if dashboard.classes.isEmpty {
                    emptyToday
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(dashboard.classes.enumerated()), id: \.element.id) { index, entry in
                            ClassRowLight(
                                entry: entry,
                                isLast: index == dashboard.classes.count - 1,
                                animated: appeared,
                                reduceMotion: reduceMotion
                            )
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 26)
        // The title sits in the sheet's raised left half, so only a little
        // breathing room is needed here.
        .padding(.top, 24)
        .padding(.bottom, 12)
        // Fill the space the header leaves *before* attaching the background,
        // so the white runs to the bottom rather than just the content height.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            TimetableSheetShape()
                .fill(CardPalette.fill)
                .shadow(color: CardPalette.shadow, radius: 34, y: -16)
                // Not inside a ScrollView, so this reaches under the tab bar.
                .ignoresSafeArea(edges: .bottom)
                // …but a background under the tab bar must not eat its taps.
                .allowsHitTesting(false)
        }
    }

    private var summaryLine: String {
        let dashboard = viewModel.dashboard
        guard !dashboard.classes.isEmpty else {
            return dashboard.isHoliday ? "No class order for today." : "Nothing scheduled today."
        }
        return "\(dashboard.classCountLine) · \(dashboard.nextUpLine)"
    }

    private var hairline: some View {
        Rectangle()
            .fill(CardPalette.divider)
            .frame(height: 1)
    }

    /// The calendar's note for today (e.g. a holiday or event name), falling
    /// back to a plain no-classes line when the calendar has nothing to say.
    private var emptyTodayLine: String {
        let dashboard = viewModel.dashboard
        if let description = dashboard.dayDescription { return description }
        return dashboard.isHoliday ? "No class order for today." : "No classes today."
    }

    /// Scribble state shown when there is nothing on today.
    private var emptyToday: some View {
        VStack(spacing: 6) {
            Text("nothing on today, enjoy! ")
                .font(JaawFonts.script(32))
                .foregroundStyle(CardPalette.accent)
            Text(emptyTodayLine)
                .font(.system(size: 13))
                .foregroundStyle(CardPalette.body)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(emptyTodayLine)
    }
}

// MARK: - Sheet shape

/// The timetable sheet. Its top edge runs straight across the left half, then
/// steps down through a rounded fillet and continues straight along the right
/// half — the shoulder the mockup tucks its round edit button against.
///
/// ```
/// ______
/// |     |
/// |     |________
/// |              |
/// |______________|
/// ```
private struct TimetableSheetShape: Shape {
    static let stepDrop: CGFloat = 68
    private static let cornerRadius: CGFloat = 46
    /// Radius of the two quarter-turns that form the rounded step.
    private static let stepRadius: CGFloat = 28
    /// Cubic control constant for a quarter-circle arc.
    private static let arcK: CGFloat = 0.552_284_75

    func path(in rect: CGRect) -> Path {
        let corner = min(Self.cornerRadius, rect.height / 2)
        let radius = min(Self.stepRadius, Self.stepDrop / 2)
        let k = radius * Self.arcK
        let minX = rect.minX
        let maxX = rect.maxX
        let minY = rect.minY
        let maxY = rect.maxY
        let stepX = minX + rect.width / 2
        let lowY = minY + Self.stepDrop

        var path = Path()
        path.move(to: CGPoint(x: minX, y: minY + corner))
        path.addQuadCurve(
            to: CGPoint(x: minX + corner, y: minY),
            control: CGPoint(x: minX, y: minY)
        )
        // Straight across the raised left half.
        path.addLine(to: CGPoint(x: stepX - radius, y: minY))
        // Quarter turn into the drop.
        path.addCurve(
            to: CGPoint(x: stepX, y: minY + radius),
            control1: CGPoint(x: stepX - radius + k, y: minY),
            control2: CGPoint(x: stepX, y: minY + radius - k)
        )
        // Short vertical run — the steep part of the step.
        path.addLine(to: CGPoint(x: stepX, y: lowY - radius))
        // Quarter turn back out to horizontal.
        path.addCurve(
            to: CGPoint(x: stepX + radius, y: lowY),
            control1: CGPoint(x: stepX, y: lowY - radius + k),
            control2: CGPoint(x: stepX + radius - k, y: lowY)
        )
        // Straight across the lowered right half.
        path.addLine(to: CGPoint(x: maxX - corner, y: lowY))
        path.addQuadCurve(
            to: CGPoint(x: maxX, y: lowY + corner),
            control: CGPoint(x: maxX, y: lowY)
        )
        path.addLine(to: CGPoint(x: maxX, y: maxY))
        path.addLine(to: CGPoint(x: minX, y: maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Class row

/// A single timetable entry on the white sheet: time down the left, course and
/// status to the right, hairline-separated like the mockup's list.
private struct ClassRowLight: View {
    var entry: ClassEntry
    var isLast: Bool
    var animated: Bool
    var reduceMotion: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                timeColumn
                content
            }
            .padding(.vertical, 15)

            if !isLast {
                Rectangle()
                    .fill(CardPalette.divider)
                    .frame(height: 1)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.time) \(entry.period), \(entry.title), \(entry.detail)\(statusSuffix)")
    }

    private var timeColumn: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(entry.time)
                .font(.system(size: 15, weight: .bold))
            Text(entry.period)
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.5)
                .textCase(.uppercase)
                .foregroundStyle(CardPalette.muted)
        }
        .foregroundStyle(isDone ? CardPalette.muted : CardPalette.title)
        .frame(width: 52, alignment: .leading)
        .padding(.top, 1)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(entry.title)
                    .font(.system(size: 16, weight: isNow ? .heavy : .semibold))
                    .tracking(-0.3)
                    .foregroundStyle(isDone ? CardPalette.muted : CardPalette.title)
                    .strikethrough(isDone, color: CardPalette.strike)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                statusTag
            }
            Text(entry.detail)
                .font(.system(size: 13))
                .foregroundStyle(CardPalette.body)

            if case .now(let progress) = entry.status {
                progressBar(progress)
                    .padding(.top, 6)
            }
        }
    }

    @ViewBuilder
    private var statusTag: some View {
        switch entry.status {
        case .now:
            Text("Now")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(CardPalette.accent, in: Capsule())
        case .upcoming(let isNext) where isNext:
            Text("Up next")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(CardPalette.accentInk)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(CardPalette.accent.opacity(0.12), in: Capsule())
        case .done:
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(CardPalette.muted)
                .accessibilityHidden(true)
        default:
            EmptyView()
        }
    }

    private func progressBar(_ progress: Double) -> some View {
        GeometryReader { proxy in
            Capsule()
                .fill(CardPalette.accent.opacity(0.16))
                .frame(height: 5)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(CardPalette.accent)
                        .frame(width: proxy.size.width * progress, height: 5)
                        .scaleEffect(x: animated || reduceMotion ? 1 : 0, anchor: .leading)
                        .animation(
                            reduceMotion ? nil : .easeOut(duration: 1.1).delay(0.4),
                            value: animated
                        )
                }
        }
        .frame(height: 5)
        .accessibilityValue("\(Int(progress * 100)) percent elapsed")
    }

    private var isDone: Bool {
        if case .done = entry.status { return true }
        return false
    }

    private var isNow: Bool {
        if case .now = entry.status { return true }
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
