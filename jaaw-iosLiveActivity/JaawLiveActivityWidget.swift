import ActivityKit
import SwiftUI
import WidgetKit

/// The Live Activity itself: the lock screen banner and the Dynamic Island
/// presentations for a class that is running.
struct JaawLiveActivityWidget: Widget {    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveClassAttributes.self) { context in
            LiveClassLockScreenView(
                subject: context.attributes.subject,
                detail: context.attributes.detail,
                start: context.state.startDate,
                end: context.state.endDate,
                isStale: context.isStale
            )
            .activityBackgroundTint(LiveActivityPalette.field)
            .activitySystemActionForegroundColor(LiveActivityPalette.ink)
        } dynamicIsland: { context in
            LiveClassIslandViews.expanded(context: context)
        }
    }
}

#Preview("Lock screen", as: .content, using: LiveClassAttributes(
    sessionID: "preview",
    subject: "Computer Networks",
    detail: "UB 512 · Dr. Karthik"
)) {
    JaawLiveActivityWidget()
} contentStates: {
    // A class that is already running, so the preview shows a part-filled bar.
    LiveClassAttributes.ContentState(
        startDate: .now.addingTimeInterval(-600),
        endDate: .now.addingTimeInterval(2400)
    )
}
