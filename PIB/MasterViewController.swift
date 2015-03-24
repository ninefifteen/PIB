//
//  MasterViewController.swift
//  PIB
//
//  Created by Shawn Seals on 12/18/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating {
    
    
    // MARK: - Types
    
    struct MainStoryboard {
        
        struct SegueIdentifiers {
            static let kAddCompany = "addCompany"
            static let kShowDetail = "showDetail"
        }
        
        struct TableViewCellIdentifiers {
            static let kMasterViewTableCell = "masterViewCell"
            static let kMasterViewErrorTableCell = "masterViewErrorCell"
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
    
    var isFirstAppearanceOfView = true
    
    var searchController: UISearchController?
    var searchResultsController: UITableViewController?
    
    var filteredCompanies = Array<Company>()
    
    
    // MARK: - View Lifecycle
    
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
        
        searchResultsController = UITableViewController()
        searchResultsController!.tableView.dataSource = self
        searchResultsController!.tableView.delegate = self
        
        searchController = UISearchController(searchResultsController: searchResultsController!)
        searchController!.searchResultsUpdater = self
        searchController!.searchBar.sizeToFit()
        self.tableView.tableHeaderView = searchController!.searchBar
        
        definesPresentationContext = true
        
        tableView.contentOffset = CGPointMake(0.0, searchController!.searchBar.bounds.height);
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if let firstRunValueString = NSUserDefaults.standardUserDefaults().objectForKey("firstRun") as? String {
            if firstRunValueString == "true" {
                WebServicesManagerAPI.sharedInstance.checkConnectionToGoogleFinanceWithCompletion({ (success) -> Void in
                    if success {
                        self.loadSampleCompaniesForFirstRun()
                    }
                })
            } else if isFirstAppearanceOfView {
                Company.removeIncompleteDataCompaniesInManagedObjectContext(managedObjectContext)
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
            
            let searchTableView = (searchController?.searchResultsController as UITableViewController).tableView
            
            if let sender = sender as? UITableViewCell {
                
                if searchTableView.indexPathForSelectedRow() != nil && sender == searchTableView.cellForRowAtIndexPath(searchTableView.indexPathForSelectedRow()!) {
                    
                    let indexPath = searchTableView.indexPathForSelectedRow()!
                    let company = filteredCompanies[indexPath.row] as Company
                    let controller = (segue.destinationViewController as UINavigationController).topViewController as DetailViewController
                    controller.company = company
                    controller.managedObjectContext = managedObjectContext
                    controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                    controller.navigationItem.leftItemsSupplementBackButton = true
                    
                } else {
                    
                    if let indexPath = self.tableView.indexPathForSelectedRow() {
                        let company = self.fetchedResultsController.objectAtIndexPath(indexPath) as Company
                        let controller = (segue.destinationViewController as UINavigationController).topViewController as DetailViewController
                        controller.company = company
                        controller.managedObjectContext = managedObjectContext
                        controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                        controller.navigationItem.leftItemsSupplementBackButton = true
                    }
                }
            }
            
        } else if segue.identifier == MainStoryboard.SegueIdentifiers.kAddCompany {
                        
            let navigationController = segue.destinationViewController as UINavigationController
            navigationController.view.tintColor = UIColor.whiteColor()
            let controller = navigationController.topViewController as AddCompanyTableViewController
            controller.managedObjectContext = managedObjectContext
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        
        if identifier == MainStoryboard.SegueIdentifiers.kShowDetail {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let company = self.fetchedResultsController.objectAtIndexPath(indexPath) as Company
                if company.dataState == .DataDownloadCompleteWithoutError {
                    return true
                } else if company.dataState == .DataDownloadCompleteWithError {
                    if let tableCell = sender as? UITableViewCell {
                        tableCell.setSelected(false, animated: true)
                    }
                    return false
                }
            } else if let indexPath = (searchController?.searchResultsController as UITableViewController).tableView.indexPathForSelectedRow() {
                let company = filteredCompanies[indexPath.row]
                if company.dataState == .DataDownloadCompleteWithoutError {
                    return true
                } else if company.dataState == .DataDownloadCompleteWithError {
                    if let tableCell = sender as? UITableViewCell {
                        tableCell.setSelected(false, animated: true)
                    }
                    return false
                }
            }
        }
        return true
    }
    
    @IBAction func unwindFromAddCompanySegue(segue: UIStoryboardSegue) {
        
        let controller = segue.sourceViewController as AddCompanyTableViewController
        
        if let companyToAdd = controller.companyToAdd? {
            controller.navigationController?.dismissViewControllerAnimated(true, completion: nil)
            Company.saveNewTargetCompanyWithName(companyToAdd.name, tickerSymbol: companyToAdd.tickerSymbol, exchangeDisplayName: companyToAdd.exchangeDisplayName, inManagedObjectContext: managedObjectContext)
        } else {
            controller.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    // MARK: - General Methods
    
    func sendAddedCompanyNameToGoogleAnalytics(companyName: String) {
        
        if logAnalytics {
            let tracker = GAI.sharedInstance().defaultTracker
            tracker.send(GAIDictionaryBuilder.createEventWithCategory(GoogleAnalytics.kEventCategoryUserAction, action: GoogleAnalytics.kEventActionAddCompany, label: companyName, value: nil).build())
        }
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
            Company.saveNewTargetCompanyWithName(sampleCompany.name, tickerSymbol: sampleCompany.tickerSymbol, exchangeDisplayName: sampleCompany.exchangeDisplayName, inManagedObjectContext: managedObjectContext)
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
    
    func removeTargetCompany(company: Company, inManagedObjectContext managedObjectContext: NSManagedObjectContext!) {
        
        if company.targets.count > 0 {
            company.changeFromTargetToPeerInManagedObjectContext(managedObjectContext)
        } else {
            managedObjectContext.deleteObject(company)
            var error: NSError? = nil
            if !managedObjectContext.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                //println("Unresolved error \(error), \(error.userInfo)")
                abort()
            }
        }
    }
    
    
    // MARK: - Table View
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if tableView == (searchController?.searchResultsController as UITableViewController).tableView {
            return 1
        } else {
            return self.fetchedResultsController.sections?.count ?? 1
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == (searchController?.searchResultsController as UITableViewController).tableView {
            return filteredCompanies.count
        } else {
            let sectionInfo = self.fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
            return sectionInfo.numberOfObjects
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.kMasterViewTableCell, forIndexPath: indexPath) as UITableViewCell
        self.configureCell(cell, atIndexPath: indexPath, forTableView: tableView)
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if cell.respondsToSelector("setSeparatorInset:") {
            cell.separatorInset = UIEdgeInsetsZero
        }
        if cell.respondsToSelector("setPreservesSuperviewLayoutMargins:") {
            cell.preservesSuperviewLayoutMargins = false
        }
        if cell.respondsToSelector("setLayoutMargins:") {
            cell.layoutMargins = UIEdgeInsetsMake(0.0, 15.0, 0.0, 0.0)
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            let context = self.fetchedResultsController.managedObjectContext
            let company = self.fetchedResultsController.objectAtIndexPath(indexPath) as Company
            
            removeTargetCompany(company, inManagedObjectContext: context)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath, forTableView tableView: UITableView) {
        
        let nameLabel = cell.viewWithTag(101) as UILabel
        let locationLabel = cell.viewWithTag(102) as UILabel
        let revenueLabel = cell.viewWithTag(103) as UILabel
        let revenueTitleLabel = cell.viewWithTag(104) as UILabel
        let activityIndicator = cell.viewWithTag(105) as UIActivityIndicatorView
        let noDataAvailableLabel = cell.viewWithTag(106) as UILabel
        
        var company: Company?
        
        if tableView == (searchController?.searchResultsController as UITableViewController).tableView {
            company  = self.filteredCompanies[indexPath.row]
        } else {
            company  = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Company
        }
            
        if let company = company {
            
            nameLabel.hidden = false
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
                locationLabel.text = " "
            }
            
            if company.dataState == .DataDownloadCompleteWithoutError {
                
                cell.accessoryView = nil
                cell.contentView.alpha = 1.0
                revenueLabel.hidden = false
                revenueTitleLabel.hidden = false
                revenueLabel.text = company.currencySymbol + company.revenueLabelString()
                locationLabel.hidden = false
                activityIndicator.hidden = true
                noDataAvailableLabel.hidden = true
                
            } else if company.dataState == .DataDownloadCompleteWithError {
                
                cell.contentView.alpha = 0.5
                revenueLabel.hidden = true
                revenueTitleLabel.hidden = true
                activityIndicator.hidden = true
                locationLabel.hidden = true
                noDataAvailableLabel.hidden = false
                
                let rawImage = UIImage(named: "trashCanSmall")
                if let image = rawImage?.imageByApplyingAlpha(0.5) {
                    let button = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
                    let frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height)
                    button.frame = frame
                    button.setBackgroundImage(image, forState: .Normal)
                    button.addTarget(self, action: "checkAccessoryDeleteButtonTapped:event:", forControlEvents: .TouchUpInside)
                    button.backgroundColor = UIColor.clearColor()
                    cell.accessoryView = button
                    cell.accessoryView?.hidden = false
                }
                
            } else {
                
                cell.accessoryView = nil
                cell.contentView.alpha = 1.0
                revenueLabel.hidden = true
                revenueTitleLabel.hidden = true
                locationLabel.hidden = false
                activityIndicator.hidden = false
                activityIndicator.startAnimating()
                noDataAvailableLabel.hidden = true
            }
            
            cell.userInteractionEnabled = company.dataState == .DataDownloadInProgress ? false : true
        }
    }
    
    func checkAccessoryDeleteButtonTapped(sender: UIButton?, event: UIEvent?) {
        
        if let uiEvent = event {
            
            let touches = uiEvent.allTouches()
            
            if let touch = touches?.anyObject() as? UITouch {
                
                let currentTouchPosition = touch.locationInView(tableView)
                
                if let indexPath = tableView.indexPathForRowAtPoint(currentTouchPosition) {
                    
                    let company = self.fetchedResultsController.objectAtIndexPath(indexPath) as Company
                    
                    if company.dataState == .DataDownloadCompleteWithError {
                        
                        let context = self.fetchedResultsController.managedObjectContext
                        context.deleteObject(company)
                        
                        var error: NSError? = nil
                        if !context.save(&error) {
                            // Replace this implementation with code to handle the error appropriately.
                            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                            //println("Unresolved error \(error), \(error.userInfo)")
                            abort()
                        }
                    }
                }
            }
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
        
        // Only fetch target companies.
        let predicate = NSPredicate(format: "isTargetCompany == 1")
        fetchRequest.predicate = predicate
        
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
            if let tableCell = tableView.cellForRowAtIndexPath(indexPath) { self.configureCell(tableCell, atIndexPath: indexPath, forTableView: tableView) }
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
    
    
    // MARK: - Search Results Updating
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let searchString = searchController.searchBar.text
        filterCompaniesForSearchString(searchString)
        (searchController.searchResultsController as UITableViewController).tableView.reloadData()
    }
    
    
    // MARK: - Content Filtering
    
    func filterCompaniesForSearchString(searchString: String) {
        
        filteredCompanies.removeAll(keepCapacity: false)
        
        let keysToSearch = ["name", "exchangeDisplayName"]
        let searchWords = searchString.componentsSeparatedByString(" ")
        
        var predicates = [NSPredicate]()
        
        for searchWord in searchWords {
            if countElements(searchWord) > 0 {
                var predicateBuilder = ""
                
                for key in keysToSearch {
                    let escapedSearchWord = searchWord.stringByReplacingOccurrencesOfString("\'", withString: "\\\'", options: .LiteralSearch, range: nil)
                    
                    if key != keysToSearch.last {
                        predicateBuilder = predicateBuilder + "(" + key + " contains[c] '" + escapedSearchWord + "') OR "
                    } else {
                        predicateBuilder = predicateBuilder + "(" + key + " contains[c] '" + escapedSearchWord + "')"
                    }
                }
                predicates.append(NSPredicate(format: predicateBuilder)!)
            }
        }
        let compoundPredicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: predicates)
        filteredCompanies = (fetchedResultsController.fetchedObjects as [Company]).filter({compoundPredicate.evaluateWithObject($0)})
    }
}









































