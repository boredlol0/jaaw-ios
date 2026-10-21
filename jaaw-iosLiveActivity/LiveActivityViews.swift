import SwiftUI
import WidgetKit

// MARK: - Shared pieces
//
// Everything time-dependent here is handed to a system timer view
// (`Text(timerInterval:)`, `ProgressView(timerInterval:)`) — the only views
// iOS keeps ticking inside a Live Activity once the app is gone.
//
// They are also fussy about the space they are given, and the Dynamic Island
// hands out some very small spaces, so every view here gets a definite size
// and a range that can never collapse.

/// The wordmark, in the same heavy, tightly-tracked face the landing page uses.
struct LiveActivityWordmark: View {
    var size: CGFloat = 13

    var body: some View {
        Text("jaaw")
            .font(.system(size: size, weight: .heavy))
            // The landing page sets -6.6pt at 102pt; keep the same ratio.
            .tracking(size * -0.065)
            .foregroundStyle(LiveActivityPalette.ink)
            .lineLimit(1)
            .fixedSize()
    }
}

/// The window a class runs over, in a form the system timer views can always
/// measure. The lower bound is pulled a minute earlier so the bar is never
/// asked for a negative width, and the range is never empty.
enum LiveClassInterval {
    static func range(start: Date, end: Date) -> ClosedRange<Date> {
        let lower = min(start, end).addingTimeInterval(-60)
        let upper = max(start, end)
        return lower...max(upper, lower.addingTimeInterval(1))
    }
}

/// The bar that fills as the class runs. A date-relative progress view lays
/// itself out — it does not take a custom style — so this stays on the
/// default style with the labels emptied out, which leaves just the bar.
struct LiveActivityProgressBar: View {
    let start: Date
    let end: Date
    var height: CGFloat = 5

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(LiveActivityPalette.track)
            ProgressView(timerInterval: LiveClassInterval.range(start: start, end: end), countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .tint(LiveActivityPalette.live)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        // The activity is black whatever the phone is doing, so the system's
        // own track colour has to be pinned to the dark one.
        .environment(\.colorScheme, .dark)
        .accessibilityLabel("Class progress")
    }
}

/// "Finishing in 23:41" — the label plus the live countdown.
///
/// The countdown gets a box of its own so the row can be centred as a whole:
/// the system's timer text fills whatever width it is handed.
struct LiveActivityCountdown: View {
    let start: Date
    let end: Date
    var font: Font = .system(size: 13, weight: .semibold)
    var timerWidth: CGFloat = 64

    var body: some View {
        HStack(spacing: 6) {
            Text("Finishing in")
                .font(font)
                .foregroundStyle(LiveActivityPalette.inkSoft)
            Text(timerInterval: start...end, countsDown: true)
                .font(font)
                .fontWeight(.bold)
                .monospacedDigit()
                .foregroundStyle(LiveActivityPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
                .frame(width: timerWidth)
        }
    }
}

/// The Dynamic Island's smallest slot. It is far too little for the system's
/// timer views, so this is the one piece of the activity that does not move.
struct LiveActivityMinimalDot: View {
    var body: some View {
        Circle()
            .fill(LiveActivityPalette.live)
            .frame(width: 7, height: 7)
            .overlay {
                Circle()
                    .strokeBorder(LiveActivityPalette.live.opacity(0.35), lineWidth: 3)
                    .frame(width: 15, height: 15)
            }
            .accessibilityLabel("Live")
    }
}

// MARK: - Lock screen

/// The lock screen banner: the wordmark top-left, the class being taught, the
/// time left and a bar underneath it.
///
/// It takes plain values rather than an activity context, so the layout can
/// be previewed on its own as well as through the Live Activity.
struct LiveClassLockScreenView: View {
    var subject: String
    var detail: String
    var start: Date
    var end: Date
    var isStale: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 7) {
            header
            Text(subject)
                .font(.system(size: 17, weight: .bold))
                .tracking(-0.3)
                .foregroundStyle(LiveActivityPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
            if !detail.isEmpty {
                Text(detail)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(LiveActivityPalette.inkFaint)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
            }
            if isStale {
                endedLabel
            } else {
                LiveActivityCountdown(start: start, end: end)
            }
            LiveActivityProgressBar(start: start, end: end)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(LiveActivityPalette.field)
    }

    /// The wordmark stays in the corner; everything the class has to say sits
    /// centred under it.
    private var header: some View {
        HStack(spacing: 6) {
            LiveActivityWordmark()
            Spacer(minLength: 0)
        }
    }

    /// Shown once the class has run out and the system marks the activity
    /// stale.
    private var endedLabel: some View {
        Text("Class ended")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(LiveActivityPalette.inkSoft)
    }
}

#Preview("Lock screen layout") {
    LiveClassLockScreenView(
        subject: "Computer Networks",
        detail: "UB 512 · Dr. Karthik",
        start: .now.addingTimeInterval(-600),
        end: .now.addingTimeInterval(2400)
    )
    .frame(width: 360)
    .background(LiveActivityPalette.field)
}

// MARK: - Dynamic Island

/// The Dynamic Island: the wordmark on the left, the countdown on the right,
/// and the class itself across the bottom.
struct LiveClassIslandViews {
    static func expanded(
        context: ActivityViewContext<LiveClassAttributes>
    ) -> DynamicIsland {
        let start = context.state.startDate
        let end = context.state.endDate
        return DynamicIsland {
            DynamicIslandExpandedRegion(.leading) {
                LiveActivityWordmark(size: 13)
            }
            DynamicIslandExpandedRegion(.trailing) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(timerInterval: start...end, countsDown: true)
                        .font(.system(size: 17, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(LiveActivityPalette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .multilineTextAlignment(.trailing)
                    Text("left")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(LiveActivityPalette.inkFaint)
                }
            }
            DynamicIslandExpandedRegion(.bottom) {
                VStack(alignment: .center, spacing: 6) {
                    Text(context.attributes.subject)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(LiveActivityPalette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .multilineTextAlignment(.center)
                    LiveActivityProgressBar(start: start, end: end)
                    if !context.attributes.detail.isEmpty {
                        Text(context.attributes.detail)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(LiveActivityPalette.inkFaint)
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        } compactLeading: {
            LiveActivityWordmark(size: 11)
        } compactTrailing: {
            Text(timerInterval: start...end, countsDown: true)
                .font(.system(size: 12, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(LiveActivityPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.trailing)
        } minimal: {
            LiveActivityMinimalDot()
        }
    }
}
