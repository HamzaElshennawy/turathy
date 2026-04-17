// © 2026 Geidea. Proprietary and confidential.
// Unauthorized copying or redistribution is prohibited.

package net.geidea.gd_payment_sdk

import android.content.Context
import android.graphics.drawable.Drawable
import com.bumptech.glide.Glide
import com.bumptech.glide.load.engine.DiskCacheStrategy
import com.bumptech.glide.request.target.CustomTarget
import com.bumptech.glide.request.transition.Transition
import io.flutter.embedding.engine.plugins.FlutterPlugin

class GdAssetImageLoader(private val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    fun loadDrawableFromAsset(
        assetPath: String,
        context: Context,
        maxHeight: Int = GdPluginConstants.Defaults.LOGO_MAX_HEIGHT,
        onComplete: (Drawable?) -> Unit
    ) {
        try {
            val assetKey = flutterPluginBinding.flutterAssets.getAssetFilePathByName(assetPath)

            // Load asset as byte array
            val inputStream = context.assets.open(assetKey)
            val bytes = inputStream.readBytes()
            inputStream.close()

            // Load with Glide from byte array
            Glide.with(context)
                .asDrawable()
                .load(bytes)
                .override(com.bumptech.glide.request.target.Target.SIZE_ORIGINAL, maxHeight)
                .diskCacheStrategy(DiskCacheStrategy.RESOURCE)
                .centerInside() // Maintains aspect ratio
                .into(object : CustomTarget<Drawable>() {
                    override fun onResourceReady(
                        resource: Drawable,
                        transition: Transition<in Drawable>?
                    ) {
                        onComplete(resource)
                    }

                    override fun onLoadFailed(errorDrawable: Drawable?) {
                        onComplete(null)
                    }

                    override fun onLoadCleared(placeholder: Drawable?) {}
                })
        } catch (e: Exception) {
            onComplete(null)
        }
    }
}