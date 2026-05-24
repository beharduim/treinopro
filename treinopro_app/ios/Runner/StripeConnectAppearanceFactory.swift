import UIKit
import StripeConnect

enum StripeConnectAppearanceFactory {
  static func buildAppearance(from raw: [String: Any]?) -> EmbeddedComponentManager.Appearance {
    var appearance = EmbeddedComponentManager.Appearance()

    appearance.colors.primary = color(from: raw?["primaryColor"], fallback: 0xFF6A00)
    appearance.colors.background = color(from: raw?["backgroundColor"], fallback: 0xFCFDFE)
    appearance.colors.text = color(from: raw?["textColor"], fallback: 0x0F131A)
    appearance.colors.secondaryText = color(from: raw?["secondaryTextColor"], fallback: 0x616161)
    appearance.colors.danger = color(from: raw?["dangerColor"], fallback: 0xE53D00)
    appearance.colors.border = color(from: raw?["borderColor"], fallback: 0xE2E8F0)
    appearance.colors.formBackground = color(from: raw?["formBackgroundColor"], fallback: 0xF3F3F3)
    appearance.colors.formAccent = color(from: raw?["formAccentColor"], fallback: 0xFF6A00)
    appearance.colors.actionPrimaryText = appearance.colors.primary

    let borderRadius = number(from: raw?["borderRadius"], fallback: 12)
    appearance.cornerRadius.base = borderRadius
    appearance.cornerRadius.button = borderRadius
    appearance.cornerRadius.form = borderRadius
    appearance.cornerRadius.overlay = borderRadius
    appearance.cornerRadius.badge = borderRadius
    appearance.spacingUnit = number(from: raw?["spacingUnit"], fallback: 8)

    appearance.buttonPrimary.colorBackground = appearance.colors.primary
    appearance.buttonPrimary.colorBorder = appearance.colors.primary
    appearance.buttonPrimary.colorText = .white

    appearance.buttonSecondary.colorBackground = appearance.colors.formBackground
    appearance.buttonSecondary.colorBorder = appearance.colors.border
    appearance.buttonSecondary.colorText = appearance.colors.text

    return appearance
  }

  static func mergeAppearance(
    local: [String: Any]?,
    remote: [String: Any]?
  ) -> [String: Any] {
    var merged = local ?? [:]

    if let remoteAppearance = remote?["appearance"] as? [String: Any] {
      for (key, value) in remoteAppearance {
        merged[key] = value
      }
    }

    if let onboarding = remote?["onboarding"] as? [String: Any] {
      if let locale = onboarding["locale"] as? String, !locale.isEmpty {
        merged["locale"] = locale
      }
      if let title = onboarding["title"] as? String, !title.isEmpty {
        merged["title"] = title
      }
      if let privacyPolicyUrl = onboarding["privacyPolicyUrl"] as? String, !privacyPolicyUrl.isEmpty {
        merged["privacyPolicyUrl"] = privacyPolicyUrl
      }
      if let termsOfServiceUrl = onboarding["termsOfServiceUrl"] as? String, !termsOfServiceUrl.isEmpty {
        merged["termsOfServiceUrl"] = termsOfServiceUrl
      }
    }

    return merged
  }

  private static func color(from value: Any?, fallback: UInt32) -> UIColor {
    guard let hex = value as? String else {
      return uiColor(from: fallback)
    }

    var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if sanitized.hasPrefix("#") {
      sanitized.removeFirst()
    }

    guard sanitized.count == 6, let intValue = UInt32(sanitized, radix: 16) else {
      return uiColor(from: fallback)
    }

    return uiColor(from: intValue)
  }

  private static func uiColor(from hex: UInt32) -> UIColor {
    UIColor(
      red: CGFloat((hex >> 16) & 0xFF) / 255.0,
      green: CGFloat((hex >> 8) & 0xFF) / 255.0,
      blue: CGFloat(hex & 0xFF) / 255.0,
      alpha: 1.0
    )
  }

  private static func number(from value: Any?, fallback: CGFloat) -> CGFloat {
    if let number = value as? NSNumber {
      return CGFloat(truncating: number)
    }
    if let doubleValue = value as? Double {
      return CGFloat(doubleValue)
    }
    return fallback
  }
}
