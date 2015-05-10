//
//  MasterTableContainerViewController.swift
//  PIB
//
//  Created by Shawn Seals on 5/10/15.
//  Copyright (c) 2015 Scoutly. All rights reserved.
//

import UIKit

class MasterTableContainerViewController: UIViewController {
    
    
    // MARK: - Types
    
    struct MainStoryboard {
        
        struct SegueIdentifiers {
            static let kAddCompany = "addCompany"
            static let kShowDetail = "showDetail"
            static let kEmbedTable = "embedTable"
        }
    }
    
    struct GoogleAnalytics {
        static let kMasterScreenName = "Master"
        static let kEventCategoryUserAction = "User Action"
        static let kEventActionAddCompany = "Add Company"
    }
    
    
    // MARK: - Properties
    
    var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext!
    
    let masterViewTitle = "Companies"
        
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if logAnalytics {
            let tracker = GAI.sharedInstance().defaultTracker
            tracker.set(kGAIScreenName, value: GoogleAnalytics.kMasterScreenName)
            let builder = GAIDictionaryBuilder.createScreenView()
            builder.set("start", forKey: kGAISessionControl)
            tracker.set(kGAIScreenName, value: GoogleAnalytics.kMasterScreenName)
            let build = builder.build() as [NSObject : AnyObject];
            tracker.send(build)
        }
        
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        title = masterViewTitle
        let backButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButtonItem
        
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = controllers[controllers.count-1].topViewController as? DetailViewController
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - General Methods
    
    func sendAddedCompanyNameToGoogleAnalytics(companyName: String) {
        
        if logAnalytics {
            let tracker = GAI.sharedInstance().defaultTracker
            let build = GAIDictionaryBuilder.createEventWithCategory(GoogleAnalytics.kEventCategoryUserAction, action: GoogleAnalytics.kEventActionAddCompany, label: companyName, value: nil).build() as [NSObject : AnyObject]
            tracker.send(build)
        }
    }
    
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == MainStoryboard.SegueIdentifiers.kEmbedTable {
            let masterTableViewController = segue.destinationViewController as! MasterViewController
            masterTableViewController.managedObjectContext = managedObjectContext
        }
    }

}
