// © 2026 Geidea. Proprietary and confidential.
// Unauthorized copying or redistribution is prohibited.

import UIKit
import Flutter

public class GdAssetImageLoader {

    func loadImageFromAsset(_ assetPath: String) -> UIImage? {
        let key = FlutterDartProject.lookupKey(forAsset: assetPath)
        guard let path = Bundle.main.path(forResource: key, ofType: nil) else {
            return nil
        }
        return UIImage(contentsOfFile: path)
    }
}