//
//  KeyoroDeeplinkHelper.swift
//  Keyoro
//
//  Created by Jan Keller on 14.11.2021.
//

import Foundation
import PeliLibrary

class KeyoroDeeplinkHelper: DeeplinkHelper {
    public static let shared = KeyoroDeeplinkHelper()
    
    override func handleFallback(for url: URL, over viewController: UIViewController) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.appCoordinator.didPressOpenWebPage(url, in: viewController)
        }
    }
}
