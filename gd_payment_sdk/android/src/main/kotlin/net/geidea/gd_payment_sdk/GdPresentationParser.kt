// © 2026 Geidea. Proprietary and confidential.
// Unauthorized copying or redistribution is prohibited.

package net.geidea.gd_payment_sdk

import android.app.Activity
import androidx.fragment.app.FragmentActivity
import net.geidea.sdk.sdk.SDKPresentationStyle

// © 2026 Geidea. Proprietary and confidential.
// Unauthorized copying or redistribution is prohibited.

class GdPresentationParser {

    fun parse(map: Map<String, Any>?, activity: Activity?): SDKPresentationStyle {
        if (map == null) {
            return SDKPresentationStyle.Push(activity)
        }

        return when (map["type"] as? String) {
            "present" -> parsePresent(activity)
            "bottomSheet" -> parseBottomSheet(map, activity)
            else -> SDKPresentationStyle.Push(activity)
        }
    }

    private fun parsePresent(activity: Activity?): SDKPresentationStyle {
        return if (activity != null) {
            SDKPresentationStyle.Present(
                presentationType = SDKPresentationStyle.Present.PresentationType.Fragment(
                    fragmentManager = (activity as? FragmentActivity)?.supportFragmentManager
                        ?: throw IllegalStateException("Activity must be FragmentActivity"),
                    containerId = android.R.id.content
                ),
                activity = activity
            )
        } else {
            throw IllegalStateException("Activity required for present style")
        }
    }

    private fun parseBottomSheet(map: Map<String, Any>, activity: Activity?): SDKPresentationStyle {
        val maxHeightDp = (map["maxHeightDp"] as? Number)?.toFloat()
        return SDKPresentationStyle.BottomSheet(activity, maxHeightDp)
    }
}