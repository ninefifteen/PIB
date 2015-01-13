//
//  MasterViewController.swift
//  PIB
//
//  Created by Shawn Seals on 12/18/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate, WebServicesMangerAPIDelegate {
    
    
    // MARK: - Types
    
    struct MainStoryboard {
        
        struct SegueIdentifiers {
            static let kAddCompany = "addCompany"
            static let kShowDetail = "showDetail"
        }
        
        struct TableViewCellIdentifiers {
            static let kMasterViewTableCell = "masterViewCell"
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
    
    lazy var webServicesManagerAPI: WebServicesManagerAPI = {
        let webServicesManagerAPI = WebServicesManagerAPI()
        webServicesManagerAPI.managedObjectContext = self.managedObjectContext
        return webServicesManagerAPI
    }()

    let masterViewTitle = "Companies"
    
    var isFirstAppearanceOfView: Bool = true
    
    
    // MARK: - View Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        if logAnalytics {
            let tracker = GAI.sharedInstance().defaultTracker
            tracker.set(kGAIScreenName, value: GoogleAnalytics.kMasterScreenName)
            let builder = GAIDictionaryBuilder.createScreenView()
            builder.set("start", forKey: kGAISessionControl)
            tracker.set(kGAIScreenName, value: GoogleAnalytics.kMasterScreenName)
            tracker.send(builder.build())
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
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if let firstRunValueString = NSUserDefaults.standardUserDefaults().objectForKey("firstRun") as? String {
            if firstRunValueString == "true" {
                webServicesManagerAPI.checkConnectionToGoogleFinanceWithCompletion({ (success) -> Void in
                    if success {
                        self.loadSampleCompaniesForFirstRun()
                    }
                })
            } else if isFirstAppearanceOfView {
                removeIncompleteDataCompanies()
            }
        }
        
        isFirstAppearanceOfView = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == MainStoryboard.SegueIdentifiers.kShowDetail {
            
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let company = self.fetchedResultsController.objectAtIndexPath(indexPath) as Company
                let controller = (segue.destinationViewController as UINavigationController).topViewController as DetailViewController
                controller.company = company
                controller.managedObjectContext = managedObjectContext
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
            
        } else if segue.identifier == MainStoryboard.SegueIdentifiers.kAddCompany {
            
            let navigationController = segue.destinationViewController as UINavigationController
            navigationController.view.tintColor = UIColor.whiteColor()
            let controller = navigationController.topViewController as AddCompanyTableViewController
            controller.managedObjectContext = managedObjectContext
        }
    }
    
    @IBAction func unwindFromAddCompanySegue(segue: UIStoryboardSegue) {
        let controller = segue.sourceViewController as AddCompanyTableViewController
        if let companyToAdd = controller.companyToAdd? {
            controller.navigationController?.dismissViewControllerAnimated(true, completion: nil)
            insertNewCompany(companyToAdd)
        } else {
            controller.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    // MARK: - General Class Methods
    
    func removeIncompleteDataCompanies() {
        
        // Delete companies with incomplete data (download interrupted).
        
        let entityDescription = NSEntityDescription.entityForName("Company", inManagedObjectContext: managedObjectContext)
        let request = NSFetchRequest()
        request.entity = entityDescription
        
        var requestError: NSError? = nil
        
        let incompleteCompaniesPredicate = NSPredicate(format: "dataDownloadComplete == 0")
        request.predicate = incompleteCompaniesPredicate
        var incompleteCompaniesArray = managedObjectContext.executeFetchRequest(request, error: &requestError) as [Company]
        if requestError != nil {
            println("Fetch request error: \(requestError?.description)")
        }
        
        for company in incompleteCompaniesArray {
            managedObjectContext.deleteObject(company)
        }
        
        // Save the context.
        var saveError: NSError? = nil
        if !managedObjectContext.save(&saveError) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //println("Unresolved error \(saveError), \(saveError.userInfo)")
            abort()
        }
    }
    
    func sendAddedCompanyNameToGoogleAnalytics(companyName: String) {
        
        if logAnalytics {
            let tracker = GAI.sharedInstance().defaultTracker
            tracker.send(GAIDictionaryBuilder.createEventWithCategory(GoogleAnalytics.kEventCategoryUserAction, action: GoogleAnalytics.kEventActionAddCompany, label: companyName, value: nil).build())
        }
    }
    
    func insertNewCompany(newCompany: Company) {
        
        /*var hud = MBProgressHUD(view: navigationController?.view)
        navigationController?.view.addSubview(hud)
        //hud.delegate = self
        hud.labelText = "Loading"
        hud.show(true)*/
        
        if !persistentStorageContainsCompany(newCompany) {
            
            // Create new company managed object.
            let entity = NSEntityDescription.entityForName("Company", inManagedObjectContext: managedObjectContext)
            let company: Company! = Company(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
            
            // Set attributes.
            company.name = newCompany.name
            company.exchange = newCompany.exchange
            company.exchangeDisplayName = newCompany.exchangeDisplayName
            company.tickerSymbol = newCompany.tickerSymbol
            company.street = ""
            company.city = ""
            company.state = ""
            company.zipCode = ""
            company.country = ""
            company.companyDescription = ""
            company.webLink = ""
            company.currencySymbol = ""
            //company.currencyCode = ""
            company.employeeCount = 0
            
            let companyName = newCompany.name   // Used for error message in the event financial data is not found.
            
            // Download fundamentals for newly added company.
            var scrapeSuccessful: Bool = false
            webServicesManagerAPI.downloadGoogleSummaryForCompany(company, withCompletion: { (success) -> Void in
                scrapeSuccessful = success
                self.webServicesManagerAPI.downloadGoogleFinancialsForCompany(company, withCompletion: { (success) -> Void in
                    if scrapeSuccessful { scrapeSuccessful = success }
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if !scrapeSuccessful {
                            self.managedObjectContext.deleteObject(company)
                        } else {
                            company.dataDownloadComplete = true
                        }
                        // Save the context.
                        var error: NSError? = nil
                        if !self.managedObjectContext.save(&error) {
                            // Replace this implementation with code to handle the error appropriately.
                            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                            //println("Unresolved error \(error), \(error.userInfo)")
                            abort()
                        }
                        //hud.hide(true)
                        //hud.removeFromSuperview()
                        if !scrapeSuccessful {
                            self.showCompanyDataNotFoundAlert(companyName)
                        }
                    })
                })
            })
        } else {
            //hud.hide(true)
            //hud.removeFromSuperview()
        }
    }
    
    func persistentStorageContainsCompany(company: Company) -> Bool {
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName("Company", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        let predicate = NSPredicate(format: "name == %@ AND exchange == %@", company.name, company.exchange)
        fetchRequest.predicate = predicate
        
        var error: NSError? = nil
        let result: [AnyObject]? = self.managedObjectContext!.executeFetchRequest(fetchRequest, error: &error)
        
        return result!.count == 0 ? false : true
    }
    
    func showCompanyDataNotFoundAlert(companyName: String) {
        let title = "We are sorry, our database does not contain financial information for " + companyName + ". Please try a different company."
        let alert = UIAlertController(title: title, message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func loadSampleCompaniesForFirstRun() {
        
        let sampleCompaniesDictionaryArray = [
            ["name": "Apple Inc.", "exchange": "NMS", "exchangeDisplayName": "NASDAQ", "symbol": "AAPL"],
            ["name": "salesforce.com, inc", "exchange": "NYQ", "exchangeDisplayName": "NYSE", "symbol": "CRM"],
            ["name": "Google Inc.", "exchange": "NMS", "exchangeDisplayName": "NASDAQ", "symbol": "GOOG"],
            ["name": "Workday, Inc.", "exchange": "NYQ", "exchangeDisplayName": "NYSE", "symbol": "WDAY"],
            ["name": "NetSuite Inc.", "exchange": "NYQ", "exchangeDisplayName": "NYSE", "symbol": "N"]
        ]
        
        let sampleCompanies = companiesFromDictionaryArray(sampleCompaniesDictionaryArray)
        
        for sampleCompany in sampleCompanies {
            insertNewCompany(sampleCompany)
        }
        
        NSUserDefaults.standardUserDefaults().setObject("false", forKey: "firstRun")
    }
    
    func companiesFromDictionaryArray(sampleCompaniesDictionaryArray: Array<Dictionary<String, String>>) -> [Company] {
        
        var companies = [Company]()
        let entity = NSEntityDescription.entityForName("Company", inManagedObjectContext: managedObjectContext)
        
        for companyDictionary in sampleCompaniesDictionaryArray {
            
            var company: Company! = Company(entity: entity!, insertIntoManagedObjectContext: nil)
            
            company.name = companyDictionary["name"]!
            company.exchange = companyDictionary["exchange"]!
            company.exchangeDisplayName = companyDictionary["exchangeDisplayName"]!
            company.tickerSymbol = companyDictionary["symbol"]!
            
            companies.append(company)
        }
        
        return companies
    }
    
    
    // MARK: - Table View
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.kMasterViewTableCell, forIndexPath: indexPath) as UITableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            let context = self.fetchedResultsController.managedObjectContext
            context.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath) as NSManagedObject)
            
            var error: NSError? = nil
            if !context.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                //println("Unresolved error \(error), \(error.userInfo)")
                abort()
            }
        }
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        
        let company = self.fetchedResultsController.objectAtIndexPath(indexPath) as Company
        
        let nameLabel = cell.viewWithTag(101) as UILabel
        nameLabel.text = company.name
        
        let locationLabel = cell.viewWithTag(102) as UILabel
        if company.city != "" {
            if company.country != "" && company.state != "" {
                locationLabel.text = company.city.capitalizedString + ", " + company.state.uppercaseString + " " + company.country.capitalizedString
            } else if company.country != "" {
                locationLabel.text = company.city.capitalizedString + " " + company.country.capitalizedString
            } else {
                locationLabel.text = company.city.capitalizedString
            }
        } else {
            locationLabel.text = " "
        }
        
        let marginLabel = cell.viewWithTag(103) as UILabel
        marginLabel.text = company.currencySymbol + revenueLabelStringForCompany(company)
        
        cell.userInteractionEnabled = company.dataDownloadComplete.boolValue ? true : false
    }
    
    
    // MARK: - Helper Methods
    
    func revenueLabelStringForCompany(company: Company) -> String {
        
        var totalRevenueArray = Array<FinancialMetric>()
        var financialMetrics: [FinancialMetric] = company.financialMetrics.allObjects as [FinancialMetric]
        for (index, financialMetric) in enumerate(financialMetrics) {
            if financialMetric.type == "Revenue" {
                totalRevenueArray.append(financialMetric)
            }
        }
        
        totalRevenueArray.sort({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })
        
        if totalRevenueArray.count > 0 {
            return PIBHelper.pibStandardStyleValueStringFromDoubleValue(Double(totalRevenueArray.last!.value))
        } else {
            return "-"
        }
    }
    
    func ebitdaMarginLabelStringForCompany(company: Company) -> String {
        
        var ebitdaMarginArray = Array<FinancialMetric>()
        var financialMetrics: [FinancialMetric] = company.financialMetrics.allObjects as [FinancialMetric]
        for (index, financialMetric) in enumerate(financialMetrics) {
            if financialMetric.type == "EBITDA Margin" {
                ebitdaMarginArray.append(financialMetric)
            }
        }
        
        ebitdaMarginArray.sort({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })
        
        if ebitdaMarginArray.count > 0 {
            return PIBHelper.pibPercentageStyleValueStringFromDoubleValue(Double(ebitdaMarginArray.last!.value))
        } else {
            return "-"
        }
    }
    
    
    // MARK: - Fetched results controller
    
    var _fetchedResultsController: NSFetchedResultsController? = nil
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
                
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName("Company", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Only fetch companies with complete data downloads.
        //let predicate = NSPredicate(format: "dataDownloadComplete == 1")
        //fetchRequest.predicate = predicate
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true, selector: "caseInsensitiveCompare:")
        let sortDescriptors = [sortDescriptor]
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        var error: NSError? = nil
        if !_fetchedResultsController!.performFetch(&error) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //println("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        
        return _fetchedResultsController!
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        case .Update:
            if let tableCell = tableView.cellForRowAtIndexPath(indexPath) { self.configureCell(tableCell, atIndexPath: indexPath) }
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
    
    /*
    // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
    // In the simplest, most efficient, case, reload the table view.
    self.tableView.reloadData()
    }
    */
    
    
    // MARK: - Web Services Manager API Delegate
    
    func webServicesManagerAPI(manager: WebServicesManagerAPI, errorAlert alert: UIAlertController) {
        presentViewController(alert, animated: true, completion: nil)
    }
    
}

