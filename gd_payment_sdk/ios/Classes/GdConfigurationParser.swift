// © 2026 Geidea. Proprietary and confidential.
// Unauthorized copying or redistribution is prohibited.

import UIKit
import GeideaPaymentSDK

public class GdConfigurationParser {
    func parse(_ dict: [String: Any]) throws -> GDPaymentSDKConfiguration {
        guard let sessionId = dict["sessionId"] as? String else {
            throw NSError(domain: "GDPaymentSDK", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "sessionId is required"])
        }

        let languageStr = dict["language"] as? String ?? "ENGLISH"
        let language: GeideaPaymentSDK.AppLanguage = languageStr.uppercased() == "ARABIC" ? .arabic: .english
        let regionStr = dict["region"] as? String ?? "EGY"
        let region = parseRegion(regionStr)
        let merchantId = dict["applePayMerchantId"] as? String
        let applePayConfig = merchantId != nil ? ApplePayConfigurations(merchantId: merchantId!) : nil
        let themeMap = dict["theme"] as? [String: Any]
        let merchantLogoPath = themeMap?["merchantLogoPath"] as? String
        let merchantLogo: UIImage? = merchantLogoPath
            .flatMap { GdAssetImageLoader().loadImageFromAsset($0) }

        let theme = themeMap.map { parseTheme(map: $0, merchantLogo: merchantLogo) }

        return GDPaymentSDKConfiguration(
            sessionId: sessionId,
            applePayConfig: applePayConfig,
            language: language,
            region: region,
            theme: theme
        )
    }

    private func parseRegion(_ regionStr: String) -> Region {
        switch regionStr.uppercased() {
        case "KSA":
            return .ksa
        case "UAE":
            return .uae
        default:
            return .egy
        }
    }

    private func parseTheme(
        map: [String: Any],
        merchantLogo: UIImage?
    ) -> SDKTheme {
        let primaryColor = map["primaryColor"] as? String ?? "#0036FF"
        let secondaryColor = map["secondaryColor"] as? String ?? "#F5F5F6"

        return SDKTheme(
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            merchantLogo: merchantLogo ?? UIImage()
        )
    }
}
