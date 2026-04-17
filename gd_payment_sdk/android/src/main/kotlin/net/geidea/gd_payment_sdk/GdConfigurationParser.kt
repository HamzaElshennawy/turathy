// © 2026 Geidea. Proprietary and confidential.
// Unauthorized copying or redistribution is prohibited.

package net.geidea.gd_payment_sdk

import net.geidea.sdk.sdk.*
import android.graphics.drawable.Drawable

class GdConfigurationParser {
    fun parse(map: Map<String, Any>, merchantLogo: Drawable?): GDPaymentSDKConfiguration {
        val themeMap = map["theme"] as? Map<String, Any>
        val sessionId = map["sessionId"] as String
        val languageStr = map["language"] as? String ?: "ENGLISH"
        val regionStr = map["region"] as? String ?: "EGY"

        val theme = themeMap?.let { parseTheme(it, merchantLogo) } ?: SDKTheme()
        val language = parseLanguage(languageStr)
        val region = parseRegion(regionStr)

        return GDPaymentSDKConfiguration(
            theme = theme,
            sessionId = sessionId,
            language = language,
            region = region
        )
    }

    private fun parseTheme(map: Map<String, Any>, merchantLogo: Drawable?): SDKTheme {
        val primaryColor = map["primaryColor"] as? String
        val secondaryColor = map["secondaryColor"] as? String

        return SDKTheme(
            primaryColor = primaryColor,
            secondaryColor = secondaryColor,
            merchantLogo = merchantLogo
        )
    }

    private fun parseLanguage(languageStr: String): SDKLanguage {
        return when (languageStr.uppercase()) {
            "ARABIC" -> SDKLanguage.ARABIC
            else -> SDKLanguage.ENGLISH
        }
    }

    private fun parseRegion(regionStr: String): REGION {
        return when (regionStr.uppercase()) {
            "KSA" -> REGION.KSA
            "UAE" -> REGION.UAE
            else -> REGION.EGY
        }
    }
}