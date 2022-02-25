//
//  MainTabBarController.swift
//  AlphaWallet
//
//  Created by Jan Keller on 08.11.2021.
//

import UIKit
import PeliLibrary

class MainTabBarController: UITabBarController, ScreensPresenting {
    var openUrlObserver: NSObjectProtocol?
    var topTabImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNotifications()
        setupAlphaWallet()
        setupDefaultTokens()
        
        let tabImageView = UIImageView(image: UIImage(named: "middle_tab_background"))
        tabImageView.sizeToFit()
        tabImageView.translatesAutoresizingMaskIntoConstraints = false
    
        tabBar.insertSubview(tabImageView, at: 2)
        tabBar.centerXAnchor.constraint(equalTo: tabImageView.centerXAnchor).isActive = true
        tabBar.topAnchor.constraint(equalTo: tabImageView.centerYAnchor, constant: -30).isActive = true
        
        topTabImageView = tabImageView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationManager.standard.handleDeferredNotification()
    }

    func setupAlphaWallet() {
        do {
            let analyticsService = AnalyticsService()
            let keystore = try EtherKeystore(analyticsCoordinator: analyticsService)
            let navigationController = UINavigationController()
            navigationController.view.backgroundColor = Colors.appWhite
            
            if var controllers = viewControllers {
                navigationController.tabBarItem = UITabBarItem(title: "Wallet", image: UIImage(named: "ic_24_wallet"), selectedImage: nil)
                controllers.insert(navigationController, at: 2)
                self.viewControllers = controllers
                
                if let firstController = controllers.first {
                    firstController.tabBarItem = UITabBarItem(title: "Articles", image: UIImage(named: "ic_24_article"), selectedImage: nil)
                    firstController.navigationItem.rightBarButtonItem = nil
                }
                
                let secondController = controllers[1]
                secondController.tabBarItem = UITabBarItem(title: "Feed", image: UIImage(named: "ic_24_news"), selectedImage: nil)
                secondController.navigationItem.rightBarButtonItem = nil
                
                let fourthController = controllers[3]
                fourthController.tabBarItem = UITabBarItem(title: "Orders", image: UIImage(named: "ic_24_store"), selectedImage: nil)
            }

            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.appCoordinator = try AppCoordinator(window: appDelegate.window!, analyticsService: analyticsService, keystore: keystore, navigationController: navigationController)
                appDelegate.appCoordinator.start()

//                if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem, shortcutItem.type == Constants.launchShortcutKey {
//                    //Delay needed to work because app is launching..
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                        self.appCoordinator.launchUniversalScanner()
//                    }
//                }
            }
            
            navigationController.tabBarItem = UITabBarItem(title: "Wallet", image: UIImage(named: "ic_24_wallet"), selectedImage: nil)
        } catch {

        }
    }
    
    func setupNotifications() {
        //NotificationCenter.default.addObserver(self, selector: #selector(openFlightSearch), name: .flightProductOpened, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onArticleDetailRequested(notification:)), name: .articleDetailRequested, object: nil)
        
        openUrlObserver = NotificationCenter.default.addObserver(OpenUrl.self, sender: nil, queue: nil, using: { (notification) in
            if let controller = UIApplication.shared.delegate?.topMostController {
                KeyoroDeeplinkHelper.shared.handleUrl(notification.url, presentOver: controller, ignoreHomepageUrl: notification.shouldIgnoreHomepage)
            }
        })
    }
    
    func setupDefaultTokens() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        guard let inCoordinator = appDelegate.appCoordinator.inCoordinator else {
            return
        }
    
        inCoordinator.addImported(contract: AlphaWallet.Address(string: "0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359")!, forServer: RPCServer.main)
//
        //let coordinator = appDelegate.appCoordinator.inCoordinator?.tokensCoordinator?.singleChainTokenCoordinators.first { $0.isServer(server) }
//
//        singleChainTokenCoordinators.first { $0.isServer(server) }
    }
    
    @objc func onArticleDetailRequested(notification: Notification) {
        guard let userInfo = notification.userInfo, let articleId = userInfo["articleId"] as? Int else {
            assertionFailure()
            return
        }
        
        showDetailForArticle(withId: articleId)
    }
    
    public var topViewController: UIViewController? {
        return UIApplication.shared.delegate?.topMostController
    }
}
