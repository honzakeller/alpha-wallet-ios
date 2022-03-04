// Copyright SIX DAY LLC. All rights reserved.
import UIKit
import AWSSNS
import AWSCore
import PromiseKit

import PeliLibrary
import Firebase
import FirebaseMessaging

import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
    var window: UIWindow?
    var appCoordinator: AppCoordinator!
    private let SNSPlatformApplicationArn = "arn:aws:sns:us-west-2:400248756644:app/APNS/AlphaWallet-iOS"
    private let SNSPlatformApplicationArnSANDBOX = "arn:aws:sns:us-west-2:400248756644:app/APNS_SANDBOX/AlphaWallet-testing"
    private let identityPoolId = "us-west-2:42f7f376-9a3f-412e-8c15-703b5d50b4e2"
    private let SNSSecurityTopicEndpoint = "arn:aws:sns:us-west-2:400248756644:security"
    //This is separate coordinator for the protection of the sensitive information.
    private lazy var protectionCoordinator: ProtectionCoordinator = {
        return ProtectionCoordinator()
    }()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        initPeliModules()
        
        do {
            //NOTE: we move AnalyticsService creation from AppCoordinator.init method to allow easily replace
            let analyticsService = AnalyticsService()
            let keystore = try EtherKeystore(analyticsCoordinator: analyticsService)
            let navigationController = UINavigationController()
            navigationController.view.backgroundColor = Colors.appWhite

            appCoordinator = try AppCoordinator(window: window!, analyticsService: analyticsService, keystore: keystore, navigationController: navigationController)
            appCoordinator.start()

            if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem, shortcutItem.type == Constants.launchShortcutKey {
                //Delay needed to work because app is launching..
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.appCoordinator.launchUniversalScanner()
                }
            }
        } catch {

        }
        
        //customizeAppearence()
        configureNotifications()
        protectionCoordinator.didFinishLaunchingWithOptions()
        
        processLaunchOptions(launchOptions)
        
        protectionCoordinator.didFinishLaunchingWithOptions()
        customizeAppearence()

        return true
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if shortcutItem.type == Constants.launchShortcutKey {
            appCoordinator.launchUniversalScanner()
        }
        completionHandler(true)
    }

    private func processLaunchOptions(_ options: [UIApplication.LaunchOptionsKey: Any]?) {
       guard let options = options else { return }
       
       if let userInfo = options[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
           NotificationManager.standard.shouldDeferHandling = true
           
           Messaging.messaging().appDidReceiveMessage(userInfo)
           
           if let topController = UIApplication.shared.delegate?.topMostController {
               NotificationManager.standard.handleNotification(with: userInfo, presentOver: topController)
           }
       }
   }

   private func initPeliModules() {
       RemoteConfig.shared.projectUid = "74311500-9130-11eb-a8b3-0242ac130003"
       Database.shared.prepare(loadFromBundles: [Bundle(for: Article.self)])
       
       window = UIWindow(frame: UIScreen.main.bounds)
       window?.backgroundColor = .peliBackground
       window?.tintColor = Colors.appTint
       window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
       window?.makeKeyAndVisible()
       
       //SVProgressHUD.setContainerView(window)
       
       configureFonts()
       registerImages()
   }
   
   open func configureFonts() {
       FontManager.shared.setFonts(boldFont: Fonts.bold(size: 20),
                                   semiboldFont: Fonts.semibold(size: 20),
                                   standardFont: Fonts.regular(size: 20))
   }
   
   private func registerImages() {
       let appBundle = Bundle(for: PeliBaseBundle.self)
       
       let manager = ImagesManager.shared
       
       manager.register(image: UIImage(named: "keyoro_logo", in: appBundle, compatibleWith: nil)!, forKey: .loading)
       manager.register(image: UIImage(named: "keyoro_noInternet")!, forKey: .noConnection)
       manager.register(image: UIImage(named: "keyoro_direction")!, forKey: .genericError)
       manager.register(image: UIImage(named: "keyoro_search")!, forKey: .noResults)
       manager.register(image: UIImage(named: "keyoro_bagagge", in: appBundle, compatibleWith: nil)!, forKey: .noFlightsAvailable)
//        manager.register(image: UIImage(named: "keyoro_flight")!, forKey: .noFlightResults)
       manager.register(image: UIImage(namedInArticles: "keyoro_review")!, forKey: .ratingDialog)
//        manager.register(image: UIImage(named: "keyoro_tickets")!, forKey: .paymentSuccess)
//        manager.register(image: UIImage(named: "keyoro_plane")!, forKey: .reservationCreated)
       manager.register(image: UIImage(named: "keyoro_notification", in: appBundle, compatibleWith: nil)!, forKey: .notificationsOnboarding)
       manager.register(image: UIImage(named: "pelican_on_suitcase", in: appBundle, compatibleWith: nil)!, forKey: .noSavedArticles)
       manager.register(image: UIImage(named: "keyoro_notification", in: appBundle, compatibleWith: nil)!, forKey: .noNotifications)
//        manager.register(image: UIImage(named: "pelican_support")!, forKey: .callMeDialog)
       manager.register(image: UIImage(namedInArticles: "keyoro_plane")!, forKey: .creatingReservation)
    }

    private func configureNotifications() {
        NotificationManager.standard.customHandler = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                UNUserNotificationCenter.current().requestAuthorization(
                    options: authOptions,
                    completionHandler: { (success, error) in
                        if error == nil {
                            if success {
                                print("Notification permission granted")
                                DispatchQueue.main.async {
                                    let application = UIApplication.shared
                                    application.registerForRemoteNotifications()
                                }
                            } else {
                                print("Notification permission denied")
                            }
                        } else {
                            print(error)
                        }
                    }
                )
        
        Messaging.messaging().delegate = self
        
        #if DEBUG
        Messaging.messaging().subscribe(toTopic: "/topics/debug") { error in
            if let error = error {
                print(error)
            }
        }
        #endif
        
        Messaging.messaging().subscribe(toTopic: "/topics/keyoro") { error in
            if let error = error {
                print(error)
            }
        }
    }
    
    private func cognitoRegistration() {
        // Override point for customization after application launch.
        /// Setup AWS Cognito credentials
        // Initialize the Amazon Cognito credentials provider
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .USWest2,
                identityPoolId: identityPoolId)
        let configuration = AWSServiceConfiguration(region: .USWest2, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        let defaultServiceConfiguration = AWSServiceConfiguration(
                region: AWSRegionType.USWest2, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = defaultServiceConfiguration
    }

    func applicationWillResignActive(_ application: UIApplication) {
        protectionCoordinator.applicationWillResignActive()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        protectionCoordinator.applicationDidBecomeActive()
        appCoordinator.handleUniversalLinkInPasteboard()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        protectionCoordinator.applicationDidEnterBackground()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        protectionCoordinator.applicationWillEnterForeground()
    }

    func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        if extensionPointIdentifier == .keyboard {
            return false
        }
        return true
    }

    // URI scheme links and AirDrop
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return appCoordinator.handleUniversalLink(url: url)
    }

    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        let hasHandledIntent = appCoordinator.handleIntent(userActivity: userActivity)
        if hasHandledIntent {
            return true
        }

        var handled = false
        if let url = userActivity.webpageURL {
            handled = handleUniversalLink(url: url)
        }
        //TODO: if we handle other types of URLs, check if handled==false, then we pass the url to another handlers
        return handled
    }

    func subscribeToTopicSNS(token: String, topicEndpoint: String) {
        let sns = AWSSNS.default()
        guard let endpointRequest = AWSSNSCreatePlatformEndpointInput() else { return }
        #if DEBUG
            endpointRequest.platformApplicationArn = SNSPlatformApplicationArnSANDBOX
        #else
            endpointRequest.platformApplicationArn = SNSPlatformApplicationArn
        #endif
        endpointRequest.token = token

        sns.createPlatformEndpoint(endpointRequest).continueWith { task in
            guard let response: AWSSNSCreateEndpointResponse = task.result else { return nil }
            guard let subscribeRequest = AWSSNSSubscribeInput() else { return nil }
            subscribeRequest.endpoint = response.endpointArn
            subscribeRequest.protocols = "application"
            subscribeRequest.topicArn = topicEndpoint
            return sns.subscribe(subscribeRequest)
        }
    }

    @discardableResult private func handleUniversalLink(url: URL) -> Bool {
        let handled = appCoordinator.handleUniversalLink(url: url)
        return handled
    }
    
    open func customizeAppearence() {
        let view = UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self])
        view.tintColor = UIColor.peliBlue
        
        window?.tintColor = UIColor.peliPrimary
        
        UITextView.appearance().tintColor = .peliPrimary
        
        UINavigationBar.appearance().tintColor = UIColor.peliLabel
        
        if #available(iOS 15.0, *) {
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.configureWithDefaultBackground()
            navigationBarAppearance.backgroundColor = UIColor.peliAppBar
            UINavigationBar.appearance().standardAppearance = navigationBarAppearance
            UINavigationBar.appearance().compactAppearance = navigationBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
            
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithDefaultBackground()
            tabBarAppearance.backgroundColor = UIColor.peliAppBar
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        } else {
            UINavigationBar.appearance().barTintColor = UIColor.peliAppBar
            UITabBar.appearance().barTintColor = UIColor.peliAppBar
        }
        
        UITabBar.appearance().tintColor = UIColor.peliPrimary
        UITabBar.appearance().unselectedItemTintColor = UIColor.secondaryPeliLabel
        
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: FontManager.shared.regular11], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: FontManager.shared.regular11], for: .selected)
        
        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.peliLabel,
            NSAttributedString.Key.font: FontManager.shared.bold18
        ]
    }
}

extension AppDelegate: MessagingDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        
        /// Attach the device token to the user defaults
        var token = ""
        for i in 0..<deviceToken.count {
            let tokenInfo = String(format: "%02.2hhx", arguments: [deviceToken[i]])
            token.append(tokenInfo)
        }
        UserDefaults.standardOrForTests.set(token, forKey: "deviceTokenForSNS")
        /// Create a platform endpoint. In this case, the endpoint is a
        /// device endpoint ARN
        cognitoRegistration()
        let sns = AWSSNS.default()
        let request = AWSSNSCreatePlatformEndpointInput()
        request?.token = token
        #if DEBUG
            request?.platformApplicationArn = SNSPlatformApplicationArnSANDBOX
        #else
            request?.platformApplicationArn = SNSPlatformApplicationArn
        #endif

        sns.createPlatformEndpoint(request!).continueWith(executor: AWSExecutor.mainThread(), block: { (task: AWSTask!) -> AnyObject? in
            if task.error == nil {
                let createEndpointResponse = task.result! as AWSSNSCreateEndpointResponse
                if let endpointArnForSNS = createEndpointResponse.endpointArn {
                    UserDefaults.standardOrForTests.set(endpointArnForSNS, forKey: "endpointArnForSNS")
                    //every user should subscribe to the security topic
                    self.subscribeToTopicSNS(token: token, topicEndpoint: self.SNSSecurityTopicEndpoint)
//                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
//                        //TODO subscribe to version topic when created
//                    }
                }
            }
            return nil
        })
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            print("FCM token: \(token)")
        }
    }
}


extension PushNotificationsCoordinator: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        print("User notification center notification")
        print(userInfo)
        
        Messaging.messaging().appDidReceiveMessage(userInfo)
            
        if #available(iOS 14.0, *) {
            completionHandler([.sound, .banner])
        } else {
            completionHandler([.sound, .alert])
        }
    }
}

extension AppDelegate: CustomNotificationsHandler {
    public func handleArticleNotification(_ userInfo: [AnyHashable: Any]) {
        let articleId: Int? = (userInfo[NotificationKeys.articleId.rawValue] as? NSString)?.integerValue ?? userInfo[NotificationKeys.articleId.rawValue] as? Int
        
        if let articleId = articleId {
            NotificationCenter.default.post(name: .articleDetailRequested, object: nil, userInfo: [NotificationKeys.articleId.rawValue: articleId])
        }
    }

    public func handleReservation(_ userInfo: [AnyHashable: Any]) {
        guard let reservationId = userInfo[NotificationKeys.reservationId.rawValue] as? String else {
            assertionFailure("Could not get reservationId from userInfo")
            return
        }
        
        NotificationCenter.default.post(name: .reservationDetailRequested, object: nil, userInfo: ["superOrderId": reservationId])
    }

    public func handleToppeckyUrl(_ userInfo: [AnyHashable: Any]) {
        NotificationCenter.default.post(name: .toppeckyRequested, object: nil)
    }
}
