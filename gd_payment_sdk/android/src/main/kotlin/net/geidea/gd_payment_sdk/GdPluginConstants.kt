// © 2026 Geidea. Proprietary and confidential.
// Unauthorized copying or redistribution is prohibited.

package net.geidea.gd_payment_sdk

object GdPluginConstants {
    const val CHANNEL_NAME = "gd_payment_sdk"

    object Methods {
        const val START = "start"
    }

    object Arguments {
        const val CONFIGURATION = "configuration"
        const val PRESENTATION_STYLE = "presentationStyle"
        const val THEME = "theme"
        const val MERCHANT_LOGO_PATH = "merchantLogoPath"
    }

    object ErrorCodes {
        const val INVALID_ARGUMENTS = "INVALID_ARGUMENTS"
        const val NO_CONTEXT = "NO_CONTEXT"
        const val SDK_ERROR = "SDK_ERROR"
        const val PAYMENT_IN_PROGRESS = "PAYMENT_IN_PROGRESS"
        const val PLUGIN_DETACHED = "PLUGIN_DETACHED"
    }

    object Defaults {
        const val LOGO_MAX_HEIGHT = 100
    }

    const val LOG_TAG = "GdPaymentSdkPlugin"
}