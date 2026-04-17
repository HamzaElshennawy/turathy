// © 2026 Geidea. Proprietary and confidential.
// Unauthorized copying or redistribution is prohibited.

import UIKit
import GeideaPaymentSDK

#if canImport(Flutter)
import Flutter

public class GdPaymentSdkPlugin: NSObject, FlutterPlugin {
    var viewController: UIViewController?
    private var pendingResult: FlutterResult?
    private let configurationParser = GdConfigurationParser()
    private let resultHandler = GdPaymentResultHandler()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "gd_payment_sdk", binaryMessenger: registrar.messenger())
        let instance = GdPaymentSdkPlugin()

        if let window = UIApplication.shared.delegate?.window,
        let rootViewController = window?.rootViewController {
            rootViewController.view.backgroundColor = .clear
            instance.viewController = rootViewController
        }

        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "start":
            handleStart(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleStart(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as?  [String: Any],
        let configDict = args["configuration"] as?  [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                message: "Configuration is required",
                details: nil))
            return
        }

        do {
            let configuration = try configurationParser.parse(configDict)
            pendingResult = result

            DispatchQueue.main.async {
                do {
                    try GDPaymentSDK.sharedInstance().start(
                        configuration: configuration,
                        delegate: self
                    )
                } catch {
                    self.pendingResult = nil
                    result(FlutterError(code: "SDK_ERROR",
                        message: error.localizedDescription,
                        details: nil))
                }
            }
        } catch {
            result(FlutterError(code: "SDK_ERROR",
                message: error.localizedDescription,
                details: nil))
        }
    }
}

extension GdPaymentSdkPlugin: GDSDKProtocol {
    public func onPaymentCompleted(result: GeideaPaymentSDK.GDPaymentResult) {
        guard let flutterResult = pendingResult else {
            return
        }
        resultHandler.handleSuccess(result: result, flutterResult: flutterResult)
        pendingResult = nil
    }

    public func onPaymentFailed(error: GeideaPaymentSDK.GDSDKError) {
        guard let flutterResult = pendingResult else {
            return
        }
        resultHandler.handleFailure(error: error, flutterResult: flutterResult)
        pendingResult = nil
    }

    public func onPaymentCanceled() {
        guard let flutterResult = pendingResult else {
            return
        }
        resultHandler.handleCancellation(flutterResult: flutterResult)
        pendingResult = nil
    }
}

#endif
