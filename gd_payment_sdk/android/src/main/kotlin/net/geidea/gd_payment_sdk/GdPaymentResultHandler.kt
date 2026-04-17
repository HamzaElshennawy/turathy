// © 2026 Geidea. Proprietary and confidential.
// Unauthorized copying or redistribution is prohibited.

package net.geidea.gd_payment_sdk

import io.flutter.plugin.common.MethodChannel.Result
import net.geidea.sdk.sdk.GDPaymentError
import net.geidea.sdk.sdk.GDPaymentResult

class GdPaymentResultHandler {

    fun handleSuccess(paymentResult: GDPaymentResult, result: Result) {
        val resultMap = buildSuccessMap(paymentResult)
        result.success(resultMap)
    }

    fun handleFailure(error: GDPaymentError, result: Result) {
        val details = buildErrorDetails(error)
        result.error(error.code, error.message, details)
    }

    fun handleCancellation(result: Result) {
        val resultMap = mapOf("status" to "canceled")
        result.success(resultMap)
    }

    private fun buildSuccessMap(paymentResult: GDPaymentResult): Map<String, Any?> {
        return mapOf(
            "status" to "success",
            "data" to mapOf(
                "orderId" to paymentResult.orderId,
                "tokenId" to paymentResult.tokenId,
                "agreementId" to paymentResult.agreementId,
                "paymentMethod" to paymentResult.paymentMethod?.let { buildPaymentMethodMap(it) }
            )
        )
    }

    private fun buildPaymentMethodMap(paymentMethod: Any): Map<String, Any?> {
        // Cast to the actual PaymentMethodResult type
        val pm = paymentMethod as? net.geidea.sdk.sdk.PaymentMethodResult ?: return emptyMap()

        return mapOf(
            "type" to pm.type,
            "brand" to pm.brand,
            "cardholderName" to pm.cardholderName,
            "maskedCardNumber" to pm.maskedCardNumber,
            "wallet" to pm.wallet,
            "expiryDate" to pm.expiryDate?.let { buildExpiryDateMap(it) }
        )
    }

    private fun buildExpiryDateMap(expiryDate: Any): Map<String, Any?> {
        val exp = expiryDate as? net.geidea.sdk.sdk.ExpiryDateResult ?: return emptyMap()

        return mapOf(
            "month" to exp.month,
            "year" to exp.year
        )
    }

    private fun buildErrorDetails(error: GDPaymentError): Map<String, Any?> {
        return mapOf(
            "status" to "failure",
            "code" to error.code,
            "message" to error.message,
            "details" to error.details
        )
    }
}