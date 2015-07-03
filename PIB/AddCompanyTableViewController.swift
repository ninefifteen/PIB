//
//  AddCompanyTableViewController.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/10/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//

import UIKit
import CoreData

class AddCompanyTableViewController: UITableViewController, UISearchBarDelegate {
    
    
    // MARK: - Types
    
    struct MainStoryboard {
        
        struct SegueIdentifiers {
            static let kUnwindFromAddCompany = "unwindFromAddCompany"
        }
        
        struct TableViewCellIdentifiers {
            static let kAddCompanyViewCompanyCell = "companyCell"
            static let kAddCompanyViewNoResultsCell = "noResultsCell"
            static let kAddCompanyViewErrorMessageCell = "errorMessageCell"
        }
    }
    
    struct GoogleAnalytics {
        static let kAddCompanyScreenName = "Add Company"
    }
    
    
    // MARK: - Properties
    
    var managedObjectContext: NSManagedObjectContext!
    var companyToAdd: Company?
    var searchResultsCompanies = [Company]()
    var webServicesManagerAPIMessages = [String]()
    
    @IBOutlet weak var searchBar: UISearchBar!

    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if logAnalytics {
            let tracker = GAI.sharedInstance().defaultTracker
            tracker.set(kGAIScreenName, value: GoogleAnalytics.kAddCompanyScreenName)
            let build = GAIDictionaryBuilder.createAppView().build() as [NSObject : AnyObject]
            tracker.send(build)
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        searchBar.becomeFirstResponder()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showWebServicesManagerAPIGeneralErrorMessage", name: "WebServicesManagerAPIGeneralErrorMessage", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showWebServicesManagerAPIConnectionErrorMessage", name: "WebServicesManagerAPIConnectionErrorMessage", object: nil)
        
        if let backgroundImage = UIImage(named: "navBarBackground") {
            if let navigationController = navigationController {
                navigationController.navigationBar.setBackgroundImage(backgroundImage, forBarMetrics:UIBarMetrics.Default)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "WebServicesManagerAPIGeneralErrorMessage", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "WebServicesManagerAPIConnectionErrorMessage", object: nil)
    }
    
    
    // MARK: - UISearchBarDelegate
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {

        if !searchText.isEmpty {
            
            WebServicesManagerAPI.sharedInstance.downloadCompaniesMatchingSearchTerm(searchText, withCompletion: { (companies, success) -> Void in
                if success {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.webServicesManagerAPIMessages.removeAll(keepCapacity: false)
                        self.searchResultsCompanies = companies
                        self.tableView.reloadData()
                    })
                }
            });
            
        } else {
            
            webServicesManagerAPIMessages.removeAll(keepCapacity: false)
            searchResultsCompanies.removeAll(keepCapacity: false)
            self.tableView.reloadData()
        }
    }
    
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        navigationController?.presentTransparentNavigationBar()
        
        if let tableViewCell = sender as? UITableViewCell {
            if let indexPath = tableView.indexPathForSelectedRow() {
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
                companyToAdd = searchResultsCompanies[indexPath.row]
                if let companyName = companyToAdd?.name {
                    sendAddedCompanyNameToGoogleAnalytics(companyName)
                }
            }
        } else if let cancelButton = sender as? UIBarButtonItem {
            companyToAdd = nil
        }
    }

    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchBar.text.isEmpty {
            return 0
        } else {
            if searchResultsCompanies.count > 0 {
                return searchResultsCompanies.count
            } else {
                return 1
            }
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        if searchResultsCompanies.count > 0 {
            
            let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.kAddCompanyViewCompanyCell, forIndexPath: indexPath) as! UITableViewCell
            let company = searchResultsCompanies[indexPath.row]
            cell.textLabel!.text = company.name
            cell.detailTextLabel!.text = "(" + company.exchangeDisplayName + ":" + company.tickerSymbol + ")"
            return cell
            
        } else if webServicesManagerAPIMessages.count > 0 {
            
            let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.kAddCompanyViewErrorMessageCell, forIndexPath: indexPath) as! UITableViewCell
            let message = webServicesManagerAPIMessages[0]
            cell.textLabel?.text = message
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.kAddCompanyViewNoResultsCell, forIndexPath: indexPath) as! UITableViewCell
            return cell
        }
    }
    
    
    // MARK: - General Methods
    
    func sendAddedCompanyNameToGoogleAnalytics(companyName: String) {
        
        if logAnalytics {
            let tracker = GAI.sharedInstance().defaultTracker
            let build = GAIDictionaryBuilder.createEventWithCategory("User Action", action: "Add Company", label: companyName, value: nil).build() as [NSObject : AnyObject]
            tracker.send(build)
        }
    }
    
    
    // MARK: - Web Services Manager API
    
    func showWebServicesManagerAPIGeneralErrorMessage() {
        let message = "Error. Try Again Later."
        displayErrorMessage(message)
    }
    
    func showWebServicesManagerAPIConnectionErrorMessage() {
        let message = "No Internet Connection"
        displayErrorMessage(message)
    }
    
    func displayErrorMessage(message: String) {
        searchResultsCompanies.removeAll(keepCapacity: false)
        webServicesManagerAPIMessages.removeAll(keepCapacity: true)
        webServicesManagerAPIMessages.append(message)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableView.reloadData()
        })
    }

}
