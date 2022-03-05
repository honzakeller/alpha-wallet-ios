// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import UIKit

class TabBarController: UITabBarController {
    var floatingSwitchView: FloatingSwitchView?
    
    var didShake: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let switchView = FloatingSwitchView()
        switchView.frame = CGRect(x: 16, y: view.frame.height - 160, width: view.frame.width - 32, height: 44)
        switchView.setSegments(with: ["Wallet", "Activity", "Browser", "Settings"])
        switchView.set(target: self, action: #selector(segmentChanged))
        switchView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(switchView)
        view.addConstraints([
            switchView.heightAnchor.constraint(equalToConstant: 44),
            switchView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            switchView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            switchView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)])
        
        floatingSwitchView = switchView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let nvc = selectedViewController as? UINavigationController {
            nvc.delegate = self
        }
    }

    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        didShake?()
    }
    
    @objc func segmentChanged(_ sender: FloatingSwitchView) {
        let shouldPopToFirst = sender.focusedIndex == selectedIndex
        
        selectedIndex = sender.focusedIndex
        
        if let nvc = selectedViewController as? UINavigationController {
            nvc.delegate = self
            
            if shouldPopToFirst {
                nvc.popToRootViewController(animated: true)
            }
        }
        
        tabBar.isHidden = true
        
    }
}

extension TabBarController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if navigationController.viewControllers.count > 1 {
            UIView.animate(withDuration: 0.25) {
                self.floatingSwitchView?.alpha = 0
            } completion: { _ in
                self.floatingSwitchView?.isHidden = true
            }
        } else {
            self.floatingSwitchView?.isHidden = false
            UIView.animate(withDuration: 0.25) {
                self.floatingSwitchView?.alpha = 1
            }
        }
        
        tabBar.isHidden = true
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        tabBar.isHidden = true
        
        if navigationController.viewControllers.count > 1 {
            self.floatingSwitchView?.isHidden = true
        }
    }
}
