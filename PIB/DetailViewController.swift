//
//  DetailViewController.swift
//  PIB
//
//  Created by Shawn Seals on 12/18/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UIViewController, UIPageViewControllerDelegate, GraphContentViewControllerDelegate {
    
    
    // MARK: - Types
    
    struct MainStoryboard {
        struct SegueIdentifiers {
            static let kShowCompanyOverView = "showCompanyOverview"
            static let kEmbedGraph = "embedGraph"
            static let kEmbedPeersTable = "embedPeersTable"
        }
    }
    
    struct GoogleAnalytics {
        static let kDetailScreenName = "Detail"
    }
    
    
    // MARK: - Properties
    
    @IBOutlet weak var nameView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var companyNameLocationView: UIView!
    @IBOutlet weak var valueView: UIView!
    @IBOutlet weak var valueViewTypeLabel: UILabel!
    @IBOutlet weak var valueViewLabel: UILabel!
    
    @IBOutlet weak var valueViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var pageControl: UIPageControl!
    
    weak var graphPageViewController: GraphPageViewController!
    
    var pageIndices = Array<Int>()
    var pageIdentifiers = Array<String>()
    
    var company: Company!
    var managedObjectContext: NSManagedObjectContext!
    
    var fullDescription: String = ""
    
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        if logAnalytics {
            let tracker = GAI.sharedInstance().defaultTracker
            tracker.set(kGAIScreenName, value: GoogleAnalytics.kDetailScreenName)
            let build = GAIDictionaryBuilder.createAppView().build() as [NSObject : AnyObject]
            tracker.send(build)
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleManagedObjectModelChangeNotification:", name: NSManagedObjectContextObjectsDidChangeNotification, object: managedObjectContext)
        
        let backButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButtonItem
        
        if company != nil {
            self.splitViewController?.toggleMasterView()
        }
        
        navigationController!.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        navigationController!.navigationBar.shadowImage = UIImage()
        navigationController!.navigationBar.translucent = true
        
        updateLabels()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    // MARK: - Subview Size Modification
    
    /*override func viewWillLayoutSubviews() {
        
        super.viewWillLayoutSubviews()
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            
            let orientation = UIApplication.sharedApplication().statusBarOrientation
            
            if !valueView.hidden && UIInterfaceOrientationIsLandscape(orientation) {
                valueViewTypeLabel.text = ""
                valueViewLabel.text = ""
                valueView.hidden = true
            }
            descriptionView.hidden = UIInterfaceOrientationIsLandscape(orientation) ? true : false
            descriptionViewHeightConstraint.constant = UIInterfaceOrientationIsLandscape(orientation) ? 0.0 : 94.0
            view.layoutIfNeeded()
            
            pageControl.hidden = false
        }
    }*/
    
    
    // MARK: - Managed Object Model Change
    
    func handleManagedObjectModelChangeNotification(notification: NSNotification!) {
        
        if company == nil { return }
        
        if let deletedObjects = notification.userInfo?[NSDeletedObjectsKey] as? NSSet {
            for deletedObject in deletedObjects {
                if let deletedCompany = deletedObject as? Company {
                    if deletedCompany == company {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.company = nil
                            self.updateLabels()
                            self.containerView.hidden = true
                        })
                    }
                }
            }
        }
    }
    
    
    // MARK: - Display Data Methods
    
    func updateLabels() {
        
        if company != nil {
            
            nameLabel.text = company.name
            
            if company.city != "" {
                if company.country != "" && company.state != "" {
                    locationLabel.text = company.city.capitalizedString + ", " + company.state.uppercaseString + " " + company.country.capitalizedString
                } else if company.country != "" {
                    locationLabel.text = company.city.capitalizedString + " " + company.country.capitalizedString
                } else {
                    locationLabel.text = company.city.capitalizedString
                }
            } else {
                locationLabel.text = ""
            }
            
            pageControl.hidden = false
            
        } else {
            
            nameLabel.hidden = true
            locationLabel.hidden = true
            pageControl.hidden = true
        }
    }
    
    
    func determineGraphsToBeDisplayed() {
        
        if company != nil {
            
            //pageIdentifiers.append("CompanyOverview")
            
            let entityDescription = NSEntityDescription.entityForName("FinancialMetric", inManagedObjectContext: managedObjectContext)
            let request = NSFetchRequest()
            request.entity = entityDescription
            
            let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
            request.sortDescriptors = [sortDescriptor]
            
            var error: NSError? = nil
            
            let totalRevenuePredicate = NSPredicate(format: "(company == %@) AND (type == 'Total Revenue')", company)
            request.predicate = totalRevenuePredicate
            var totalRevenueArray = managedObjectContext.executeFetchRequest(request, error: &error) as! [FinancialMetric]
            if error != nil {
                println("Fetch request error: \(error?.description)")
            }
            
            let profitMarginPredicate = NSPredicate(format: "(company == %@) AND (type == 'Profit Margin')", company)
            request.predicate = profitMarginPredicate
            var profitMarginArray = managedObjectContext.executeFetchRequest(request, error: &error) as! [FinancialMetric]
            if error != nil {
                println("Fetch request error: \(error?.description)")
            }
            
            let revenueGrowthPredicate = NSPredicate(format: "(company == %@) AND (type == 'Revenue Growth')", company)
            request.predicate = revenueGrowthPredicate
            var revenueGrowthArray = managedObjectContext.executeFetchRequest(request, error: &error) as! [FinancialMetric]
            if error != nil {
                println("Fetch request error: \(error?.description)")
            }
            
            /*let netIncomeGrowthPredicate = NSPredicate(format: "(company == %@) AND (type == 'Net Income Growth')", company)
            request.predicate = netIncomeGrowthPredicate
            var netIncomeGrowthArray = managedObjectContext.executeFetchRequest(request, error: &error) as [FinancialMetric]
            if error != nil {
                println("Fetch request error: \(error?.description)")
            }*/
            
            let grossMarginPredicate = NSPredicate(format: "(company == %@) AND (type == 'Gross Margin')", company)
            request.predicate = grossMarginPredicate
            var grossMarginArray = managedObjectContext.executeFetchRequest(request, error: &error) as! [FinancialMetric]
            if error != nil {
                println("Fetch request error: \(error?.description)")
            }
            
            let rAndDPredicate = NSPredicate(format: "(company == %@) AND (type == 'R&D As Percent Of Revenue')", company)
            request.predicate = rAndDPredicate
            var rAndDArray = managedObjectContext.executeFetchRequest(request, error: &error) as! [FinancialMetric]
            if error != nil {
                println("Fetch request error: \(error?.description)")
            }
            
            let sgAndAPredicate = NSPredicate(format: "(company == %@) AND (type == 'SG&A As Percent Of Revenue')", company)
            request.predicate = sgAndAPredicate
            var sgAndAArray = managedObjectContext.executeFetchRequest(request, error: &error) as! [FinancialMetric]
            if error != nil {
                println("Fetch request error: \(error?.description)")
            }
            
            if minimumValueInFinancialMetricArray(totalRevenueArray) != 0.0 || maximumValueInFinancialMetricArray(totalRevenueArray) != 0.0 {
                pageIdentifiers.append("Revenue")
            }
            
            if minimumValueInFinancialMetricArray(revenueGrowthArray) != 0.0 || maximumValueInFinancialMetricArray(revenueGrowthArray) != 0.0 {
                pageIdentifiers.append("Growth")
            }
            
            if minimumValueInFinancialMetricArray(grossMarginArray) != 0.0 || maximumValueInFinancialMetricArray(grossMarginArray) != 0.0 {
                pageIdentifiers.append("GrossMargin")
            }
            
            if minimumValueInFinancialMetricArray(sgAndAArray) != 0.0 || maximumValueInFinancialMetricArray(sgAndAArray) != 0.0 {
                pageIdentifiers.append("SG&A")
            }
            
            if minimumValueInFinancialMetricArray(rAndDArray) != 0.0 || maximumValueInFinancialMetricArray(rAndDArray) != 0.0 {
                pageIdentifiers.append("R&D")
            }
            
            for (index, pageIdentifier) in enumerate(pageIdentifiers) {
                pageIndices.append(index)
            }
            
            pageControl.numberOfPages = pageIndices.count
        }
    }
    
    func removeValueView() {
        valueViewTypeLabel.text = ""
        valueViewLabel.text = ""
        valueView.hidden = true
        companyNameLocationView.hidden = false
    }
    
    
    // MARK: - Helper Methods
    
    func minimumValueInFinancialMetricArray(financialMetrics: Array<FinancialMetric>) -> Double {
        
        var minimumValue: Double = 0.0
        
        for (index, financialMetric) in enumerate(financialMetrics) {
            let currentValue: Double = Double(financialMetric.value)
            if currentValue < minimumValue { minimumValue = currentValue }
        }
        
        return minimumValue
    }
    
    func maximumValueInFinancialMetricArray(financialMetrics: Array<FinancialMetric>) -> Double {
        
        var maximumValue: Double = 0.0
        
        for (index, financialMetric) in enumerate(financialMetrics) {
            let currentValue: Double = Double(financialMetric.value)
            if currentValue > maximumValue { maximumValue = currentValue }
        }
        
        return maximumValue
    }
    
    
    // MARK: - UIPageControl
    
    @IBAction func pageControlValueChanged(sender: UIPageControl) {
        let newPageIndex = sender.currentPage
        graphPageViewController.scrollToViewControllerAtIndex(newPageIndex)
    }
    
    
    // MARK: - UIPageViewControllerDelegate
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [AnyObject], transitionCompleted completed: Bool) {
        let currentContentPage = graphPageViewController.viewControllers.last as! GraphContentViewController
        let currentPageIndex = currentContentPage.pageIndex
        removeValueView()
        pageControl.currentPage = currentPageIndex
    }
    
    
    // MARK: - GraphContentViewControllerDelegate
    
    func userSelectedGraphPointOfType(type: String, forDate date: String, withValue value: String) {
        
        let valueViewLabelString = date + "  " + value
        
        if valueViewLabelString == valueViewLabel.text && type == valueViewTypeLabel.text {
            valueViewTypeLabel.text = ""
            valueViewLabel.text = ""
            valueView.hidden = true
            companyNameLocationView.hidden = false
        } else {
            valueViewTypeLabel.text = type
            valueViewLabel.text = valueViewLabelString
            valueView.hidden = false
            companyNameLocationView.hidden = true
        }
    }
    
    @IBAction func cancelValueViewButtonPressed(sender: UIButton) {
        removeValueView()
    }
    
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == MainStoryboard.SegueIdentifiers.kEmbedGraph {
            determineGraphsToBeDisplayed()
            graphPageViewController = segue.destinationViewController as! GraphPageViewController
            graphPageViewController.company = company
            graphPageViewController.managedObjectContext = managedObjectContext
            graphPageViewController.pageIndices = pageIndices
            graphPageViewController.pageIdentifiers = pageIdentifiers
            graphPageViewController.delegate = self
            graphPageViewController.graphContentViewControllerDelegate = self
        } else if segue.identifier == MainStoryboard.SegueIdentifiers.kShowCompanyOverView {
            let companyOverviewViewController = segue.destinationViewController as! CompanyOverviewViewController
            companyOverviewViewController.company = company
        } else if segue.identifier == MainStoryboard.SegueIdentifiers.kEmbedPeersTable {
            let peersTableViewController = segue.destinationViewController as! PeersTableViewController
            peersTableViewController.company = company
            peersTableViewController.managedObjectContext = managedObjectContext
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if identifier == MainStoryboard.SegueIdentifiers.kEmbedPeersTable {
            if company != nil {
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }
}