// © 2026 Geidea. Proprietary and confidential.
// Unauthorized copying or redistribution is prohibited.

import Flutter
import GeideaPaymentSDK

public class GdPaymentResultHandler {

    func handleSuccess(result: GeideaPaymentSDK.GDPaymentResult, flutterResult: @escaping FlutterResult) {
        let resultMap = buildSuccessMap(from: result)
        flutterResult(resultMap)
    }

    func handleFailure(error: GeideaPaymentSDK.GDSDKError, flutterResult: @escaping FlutterResult) {
        let details = buildErrorDetails(from: error)

        flutterResult(FlutterError(
            code: error.code,
            message: error.message,
            details: details
        ))
    }

    func handleCancellation(flutterResult: @escaping FlutterResult) {
        let resultMap: [String: Any] = ["status": "canceled"]
        flutterResult(resultMap)
    }

    // MARK: - Private Helper Methods

    private func buildSuccessMap(from result: GeideaPaymentSDK.GDPaymentResult) -> [String: Any] {
        var dataMap: [String: Any] = [
            "orderId": result.orderId as Any,
            "tokenId": result.tokenId as Any,
            "agreementId": result.agreementId as Any
        ]

        if let paymentMethod = result.paymentMethod {
            dataMap["paymentMethod"] = buildPaymentMethodMap(from: paymentMethod)
        }

        return [
            "status": "success",
            "data": dataMap
        ]
    }

    private func buildPaymentMethodMap(from paymentMethod: Any) -> [String: Any] {
        // Cast to the actual PayPaymentMethod type from GeideaPaymentSDK
        guard let pm = paymentMethod as? GeideaPaymentSDK.PayPaymentMethod else {
            return [:]
        }

        var paymentMethodMap: [String: Any] = [:]

        // Access properties directly (not via KVO)
        if let type = pm.type {
            paymentMethodMap["type"] = type
        }

        if let brand = pm.brand {
            paymentMethodMap["brand"] = brand
        }

        if let cardholderName = pm.cardholderName {
            paymentMethodMap["cardholderName"] = cardholderName
        }

        if let maskedCardNumber = pm.maskedCardNumber {
            paymentMethodMap["maskedCardNumber"] = maskedCardNumber
        }

        // Handle wallet if it exists
        // paymentMethodMap["wallet"] = pm.wallet // Add this if wallet property exists

        if let expiryDate = pm.expiryDate {
            paymentMethodMap["expiryDate"] = buildExpiryDateMap(from: expiryDate)
        }

        return paymentMethodMap
    }

    private func buildExpiryDateMap(from expiryDate: GeideaPaymentSDK.PayPaymentMethod.ExpiryDate) -> [String: Any] {
        return [
            "month": expiryDate.month,
            "year": expiryDate.year
        ]
    }

    private func buildErrorDetails(from error: GeideaPaymentSDK.GDSDKError) -> [String: Any] {
        return [
            "status": "failure",
            "code": error.code,
            "message": error.message,
            "details": error.details as Any
        ]
    }
}
