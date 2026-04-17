// © 2026 Geidea. Proprietary and confidential.
// Unauthorized copying or redistribution is prohibited.

package net.geidea.gd_payment_sdk

import android.app.Activity
import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import net.geidea.sdk.sdk.*
import android.graphics.drawable.Drawable

class GdPaymentSdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var applicationContext: Context? = null
    private var pendingResult: Result? = null
    private val configurationParser = GdConfigurationParser()
    private val presentationStyleParser = GdPresentationParser()
    private val resultHandler = GdPaymentResultHandler()
    private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    private lateinit var assetImageLoader: GdAssetImageLoader

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        this.flutterPluginBinding = flutterPluginBinding
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, GdPluginConstants.CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        applicationContext = flutterPluginBinding.applicationContext
        assetImageLoader = GdAssetImageLoader(flutterPluginBinding)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            GdPluginConstants.Methods.START -> handleStart(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleStart(call: MethodCall, result: Result) {
        try {
            val configMap = call.argument<Map<String, Any>>(GdPluginConstants.Arguments.CONFIGURATION)
            val presentationStyleMap = call.argument<Map<String, Any>>(GdPluginConstants.Arguments.PRESENTATION_STYLE)

            if (configMap == null) {
                result.error(GdPluginConstants.ErrorCodes.INVALID_ARGUMENTS, "Configuration is required", null)
                return
            }

            val context = activity ?: applicationContext
            if (context == null) {
                result.error(GdPluginConstants.ErrorCodes.NO_CONTEXT, "Activity context not available", null)
                return
            }

            getMerchantLogo(configMap, context) { merchantLogo ->
                startPayment(call, result, configMap, context, merchantLogo)
            }
        } catch (e: Exception) {
            result.error(GdPluginConstants.ErrorCodes.SDK_ERROR, e.message, null)
            pendingResult = null
        }
    }

    private fun startPayment(
        call: MethodCall,
        result: Result,
        configMap: Map<String, Any>,
        context: Context,
        merchantLogo: Drawable?
    ) {
        val configuration = configurationParser.parse(configMap, merchantLogo)
        val presentationStyleMap = call.argument<Map<String, Any>>(
            GdPluginConstants.Arguments.PRESENTATION_STYLE
        )
        val presentationStyle = presentationStyleParser.parse(presentationStyleMap, activity)

        pendingResult = result

        val callback = createPaymentCallback()
        GDPaymentSDK.sharedInstance().apply {
            setPaymentCallback(callback)
            start(
                configuration = configuration,
                context = context,
                presentationStyle = presentationStyle
            )
        }
    }

    private fun createPaymentCallback() = object : GDPaymentResultListener {
        override fun onPaymentCompleted(paymentResult: GDPaymentResult) {
            pendingResult?.let { result ->
                resultHandler.handleSuccess(paymentResult, result)
                pendingResult = null
            }
        }

        override fun onPaymentFailure(error: GDPaymentError) {
            pendingResult?.let { result ->
                resultHandler.handleFailure(error, result)
                pendingResult = null
            }
        }

        override fun onPaymentCanceled() {
            pendingResult?.let { result ->
                resultHandler.handleCancellation(result)
                pendingResult = null
            }
        }
    }

    private fun getMerchantLogo(
        configMap: Map<String, Any>,
        context: Context,
        onComplete: (Drawable?) -> Unit
    ) {
        val theme = configMap[GdPluginConstants.Arguments.THEME] as? Map<String, Any>
        val merchantLogoPath = theme?.get(GdPluginConstants.Arguments.MERCHANT_LOGO_PATH) as? String

        if (merchantLogoPath == null) {
            onComplete(null)
            return
        }

        assetImageLoader.loadDrawableFromAsset(merchantLogoPath, context) { drawable ->
            onComplete(drawable)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        pendingResult = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}