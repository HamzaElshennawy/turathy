import ActivityKit
import SwiftUI
import WidgetKit

/// Dynamic Island / Live Activities for a live auction lot.
/// The attributes type name must stay `LiveActivitiesAppAttributes` so the
/// `live_activities` plugin can find this widget. Data is read from the App Group.
/// The countdown uses `Text(timerInterval:)` and does not need a push each second.

@main
struct TurathyLiveActivityBundle: WidgetBundle {
  var body: some Widget {
    if #available(iOS 16.1, *) {
      TurathyLiveActivity()
    }
  }
}

struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
  public typealias LiveDeliveryData = ContentState

  public struct ContentState: Codable, Hashable {}

  var id = UUID()
}

extension LiveActivitiesAppAttributes {
  func prefixedKey(_ key: String) -> String {
    "\(id)_\(key)"
  }
}

private let turathyAppGroup = "group.com.deepblue.turathy"
private let turathyBrand = Color(red: 0, green: 93 / 255, blue: 36 / 255)

private func sharedDefaults() -> UserDefaults? {
  UserDefaults(suiteName: turathyAppGroup)
}

private func liveString(_ attributes: LiveActivitiesAppAttributes, _ key: String) -> String {
  sharedDefaults()?.string(forKey: attributes.prefixedKey(key)) ?? ""
}

private func liveEndsAt(_ attributes: LiveActivitiesAppAttributes) -> Date? {
  let raw = sharedDefaults()?.object(forKey: attributes.prefixedKey("endsAt"))
  let milliseconds: Double
  if let number = raw as? NSNumber {
    milliseconds = number.doubleValue
  } else {
    return nil
  }
  guard milliseconds > 0 else { return nil }
  return Date(timeIntervalSince1970: milliseconds / 1000)
}

private struct LotLogo: View {
  var side: CGFloat

  var body: some View {
    Image("AppLogo")
      .renderingMode(.original)
      .resizable()
      .scaledToFit()
      .frame(width: side, height: side)
      .clipShape(RoundedRectangle(cornerRadius: side / 5, style: .continuous))
  }
}

@available(iOS 16.1, *)
private struct LotCountdown: View {
  let endsAt: Date?

  var body: some View {
    if let endsAt, endsAt > Date() {
      Text(timerInterval: Date()...endsAt, countsDown: true)
        .monospacedDigit()
        .multilineTextAlignment(.center)
    }
  }
}

private func lotTitle(_ raw: String) -> String {
  let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
  if trimmed.isEmpty { return "بند" }
  if trimmed.contains("بند") { return trimmed }
  return "بند \(trimmed)"
}

private func bidTitle(_ raw: String) -> String {
  let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
  if trimmed.isEmpty { return "" }
  if trimmed.contains("ر.س") || trimmed.contains("ريال") { return trimmed }
  return "\(trimmed) ر.س"
}

@available(iOS 16.1, *)
private struct EnterAuctionButton: View {
  var body: some View {
    Text("دخول المزاد")
      .font(.headline)
      .frame(maxWidth: .infinity, minHeight: 44)
      .background(Color.white)
      .foregroundStyle(turathyBrand)
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      .accessibilityLabel("دخول المزاد")
      .accessibilityAddTraits(.isButton)
  }
}

@available(iOS 16.1, *)
struct TurathyLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
      TurathyLockScreen(attributes: context.attributes)
    } dynamicIsland: { context in
      let attributes = context.attributes
      let lotNumber = liveString(attributes, "lotNumber")
      let price = bidTitle(liveString(attributes, "bidPrice"))
      let endsAt = liveEndsAt(attributes)

      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          LotLogo(side: 36)
        }
        DynamicIslandExpandedRegion(.trailing) {
          LotCountdown(endsAt: endsAt)
            .font(.headline)
            .foregroundStyle(.white)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 8) {
            Text(lotTitle(lotNumber))
              .font(.headline)
              .lineLimit(1)
            if !price.isEmpty {
              Text(price)
                .font(.subheadline)
                .lineLimit(1)
            }
            EnterAuctionButton()
          }
        }
      } compactLeading: {
        LotLogo(side: 22)
      } compactTrailing: {
        LotCountdown(endsAt: endsAt)
          .font(.caption)
          .fontWeight(.semibold)
          .lineLimit(1)
      } minimal: {
        LotLogo(side: 18)
      }
      .widgetURL(URL(string: "turathy://live"))
    }
  }
}

@available(iOS 16.1, *)
private struct TurathyLockScreen: View {
  let attributes: LiveActivitiesAppAttributes

  var body: some View {
    let lotNumber = liveString(attributes, "lotNumber")
    let price = bidTitle(liveString(attributes, "bidPrice"))
    let endsAt = liveEndsAt(attributes)

    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 12) {
        LotLogo(side: 44)
        Text(lotTitle(lotNumber))
          .font(.headline)
          .lineLimit(1)
        Spacer(minLength: 8)
        LotCountdown(endsAt: endsAt)
          .font(.title2)
          .foregroundStyle(.white)
      }
      if !price.isEmpty {
        Text(price)
          .font(.title3)
          .fontWeight(.semibold)
          .lineLimit(1)
      }
      EnterAuctionButton()
    }
    .padding(14)
    .foregroundStyle(.white)
    .environment(\.layoutDirection, .rightToLeft)
    .activityBackgroundTint(turathyBrand)
    .widgetURL(URL(string: "turathy://live"))
  }
}
