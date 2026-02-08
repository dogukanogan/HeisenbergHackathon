//
//  EmergencyWidgetExtensionLiveActivity.swift
//  EmergencyWidgetExtension
//
//  Created by Doğukan Ogan on 3.02.2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct EmergencyWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct EmergencyWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EmergencyWidgetExtensionAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension EmergencyWidgetExtensionAttributes {
    fileprivate static var preview: EmergencyWidgetExtensionAttributes {
        EmergencyWidgetExtensionAttributes(name: "World")
    }
}

extension EmergencyWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: EmergencyWidgetExtensionAttributes.ContentState {
        EmergencyWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: EmergencyWidgetExtensionAttributes.ContentState {
         EmergencyWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: EmergencyWidgetExtensionAttributes.preview) {
   EmergencyWidgetExtensionLiveActivity()
} contentStates: {
    EmergencyWidgetExtensionAttributes.ContentState.smiley
    EmergencyWidgetExtensionAttributes.ContentState.starEyes
}
