//
//  AppDelegate.swift
//  PIB
//
//  Created by Shawn Seals on 12/18/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//

import UIKit
import CoreData

let logAnalytics: Bool = false

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
    
    struct GoogleAnalytics {
        static let kTrackerId = "UA-35969227-1"
    }
    
    var window: UIWindow?
    
    func customizeAppearance() {
        //UINavigationBar.appearance().barTintColor = UIColor(red: 227.0/255.0, green: 48.0/255.0, blue: 53.0/255.0, alpha: 1.0)
        //UINavigationBar.appearance().setBackgroundImage(UIImage(contentsOfFile: "navBarBackground"), forBarMetrics: UIBarMetrics.Default)
        
        /*if let backgroundImage = UIImage(named: "navBarBackground") {
        UINavigationBar.appearance().setBackgroundImage(backgroundImage.resizableImageWithCapInsets(UIEdgeInsetsMake(0, 0, 0, 0), resizingMode: .Stretch), forBarMetrics: .Default)
        }*/
        
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Override point for customization after application launch.
        let defaults = NSUserDefaults.standardUserDefaults()
        if defaults.objectForKey("firstRun") == nil {
            defaults.setObject("true", forKey: "firstRun")
        }
        
        if logAnalytics {
            GAI.sharedInstance().trackUncaughtExceptions = true
            GAI.sharedInstance().logger.logLevel = GAILogLevel.Verbose
            GAI.sharedInstance().dispatchInterval = 10
            GAI.sharedInstance().dryRun = false
            let tracker = GAI.sharedInstance().trackerWithTrackingId(GoogleAnalytics.kTrackerId)
            let version = NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey as String) as! String
            tracker.set(kGAIAppVersion, value: version)
            tracker.allowIDFACollection = true
        }
        
        WebServicesManagerAPI.sharedInstance.managedObjectContext = managedObjectContext
        
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
        splitViewController.delegate = self
        
        let masterNavigationController = splitViewController.viewControllers[0] as! UINavigationController
        let controller = masterNavigationController.topViewController as! MasterTableContainerViewController
        
        controller.managedObjectContext = managedObjectContext
        
        splitViewController.preferredDisplayMode = UISplitViewControllerDisplayMode.AllVisible
        splitViewController.view.tintColor = UIColor.whiteColor()
        
        customizeAppearance()
        
        checkForCompaniesWithoutMostRecentRevenueValue()
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    
    // MARK: - Split view
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController!, ontoPrimaryViewController primaryViewController:UIViewController!) -> Bool {
        if let secondaryAsNavController = secondaryViewController as? UINavigationController {
            if let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController {
                if topAsDetailController.company == nil {
                    // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
                    return true
                }
            }
        }
        return false
    }
    
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.scoutly.PIB" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as! NSURL
        }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("PIB", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("PIB_v1_0.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: options, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict as [NSObject : AnyObject])
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return coordinator
        }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }
    
    
    // MARK: - Maintenance
    
    func checkForCompaniesWithoutMostRecentRevenueValue() {
        
        let entityDescription = NSEntityDescription.entityForName("Company", inManagedObjectContext: managedObjectContext!)
        let request = NSFetchRequest()
        request.entity = entityDescription
        
        let predicate = NSPredicate(format: "mostRecentRevenue == 0")
        request.predicate = predicate
        var error: NSError? = nil
        
        let noMostRecentRevenueCompanies = managedObjectContext!.executeFetchRequest(request, error: &error) as! [Company]
        println(noMostRecentRevenueCompanies.count)
        
        if error != nil {
            println("Fetch request error: \(error?.description)")
        }
        
        for company in noMostRecentRevenueCompanies {
            
            var totalRevenueArray = Array<FinancialMetric>()
            var financialMetrics = company.financialMetrics.allObjects as! [FinancialMetric]
            for (index, financialMetric) in enumerate(financialMetrics) {
                if financialMetric.type == "Total Revenue" {
                    totalRevenueArray.append(financialMetric)
                }
            }
            
            totalRevenueArray.sort({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })
            
            if totalRevenueArray.count > 0 {
                company.mostRecentRevenue = totalRevenueArray.last!.value
            }
        }
        
        var saveError: NSError? = nil
        if !managedObjectContext!.save(&saveError) {
            println("Save Error in setDataStatusForCompanyInManagedObjectContext(_:).")
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //println("Unresolved error \(saveError), \(saveError.userInfo)")
            abort()
        }
    }
    
}

