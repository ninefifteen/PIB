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
        }
    }
    
    struct GoogleAnalytics {
        static let kAddCompanyScreenName = "Add Company"
    }
    
    
    // MARK: - Properties
    
    var managedObjectContext: NSManagedObjectContext!
    var companyToAdd: Company?
    var searchResultsCompanies = [Company]()
    
    @IBOutlet weak var searchBar: UISearchBar!

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if logAnalytics {
            let tracker = GAI.sharedInstance().defaultTracker
            tracker.set(kGAIScreenName, value: GoogleAnalytics.kAddCompanyScreenName)
            tracker.send(GAIDictionaryBuilder.createAppView().build())
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        searchBar.becomeFirstResponder()
        
        addAllObservers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
                        self.searchResultsCompanies = companies
                        self.tableView.reloadData()
                    })
                }
            });
            
        } else {
            
            searchResultsCompanies.removeAll(keepCapacity: false)
            self.tableView.reloadData()
        }
    }
    
    deinit {
        removeAllObservers()
    }
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        removeAllObservers()
        
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
            
            let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.kAddCompanyViewCompanyCell, forIndexPath: indexPath) as UITableViewCell
            let company = searchResultsCompanies[indexPath.row]
            cell.textLabel!.text = company.name
            cell.detailTextLabel!.text = "(" + company.exchangeDisplayName + ":" + company.tickerSymbol + ")"
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.kAddCompanyViewNoResultsCell, forIndexPath: indexPath) as UITableViewCell
            return cell
        }
    }
    
    
    // MARK: - General Methods
    
    func sendAddedCompanyNameToGoogleAnalytics(companyName: String) {
        
        if logAnalytics {
            let tracker = GAI.sharedInstance().defaultTracker
            tracker.send(GAIDictionaryBuilder.createEventWithCategory("User Action", action: "Add Company", label: companyName, value: nil).build())
        }
    }
    
    func addAllObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showWebServicesManagerAPIGeneralErrorMessage", name: "WebServicesManagerAPIGeneralErrorMessage", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showWebServicesManagerAPIConnectionErrorMessage", name: "WebServicesManagerAPIConnectionErrorMessage", object: nil)
    }
    
    func removeAllObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "WebServicesManagerAPIGeneralErrorMessage", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "WebServicesManagerAPIConnectionErrorMessage", object: nil)
    }
    
    
    // MARK: - Web Services Manager API
    
    func showWebServicesManagerAPIGeneralErrorMessage() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let alert = UIAlertController(title: "Error", message: "Unable to download data", preferredStyle: UIAlertControllerStyle.Alert)
            let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
            alert.addAction(action)
            self.presentViewController(alert, animated: true, completion: nil)
        })
    }
    
    func showWebServicesManagerAPIConnectionErrorMessage() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let alert = UIAlertController(title: "Connection Error", message: "You do not appear to be connected to the internet", preferredStyle: UIAlertControllerStyle.Alert)
            let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
            alert.addAction(action)
            alert.view.tintColor = UIColor.blueColor()
            self.presentViewController(alert, animated: true, completion: nil)
        })
    }

}
