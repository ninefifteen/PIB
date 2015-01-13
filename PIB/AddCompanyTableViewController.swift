//
//  AddCompanyTableViewController.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/10/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//

import UIKit
import CoreData

class AddCompanyTableViewController: UITableViewController, UISearchBarDelegate, WebServicesMangerAPIDelegate {
    
    
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
    
    let webServicesManagerAPI = WebServicesManagerAPI()
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
        
        webServicesManagerAPI.managedObjectContext = managedObjectContext
        webServicesManagerAPI.delegate = self

        searchBar.becomeFirstResponder()
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
            
            webServicesManagerAPI.downloadCompaniesMatchingSearchTerm(searchText, withCompletion: { (companies, success) -> Void in
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
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let cancelButton = sender as? UIBarButtonItem {
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
    
    
    // MARK: - Table View Delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Add selected company to Core Data.
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        companyToAdd = searchResultsCompanies[indexPath.row]
        if let companyName = companyToAdd?.name {
            sendAddedCompanyNameToGoogleAnalytics(companyName)
        }
        performSegueWithIdentifier(MainStoryboard.SegueIdentifiers.kUnwindFromAddCompany, sender: self)
    }
    
    
    // MARK: - General Class Methods
    
    func sendAddedCompanyNameToGoogleAnalytics(companyName: String) {
        
        if logAnalytics {
            let tracker = GAI.sharedInstance().defaultTracker
            tracker.send(GAIDictionaryBuilder.createEventWithCategory("User Action", action: "Add Company", label: companyName, value: nil).build())
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
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.performSegueWithIdentifier(MainStoryboard.SegueIdentifiers.kUnwindFromAddCompany, sender: self)
        }
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }

    // MARK: - Web Services Manager API Delegate
    
    func webServicesManagerAPI(manager: WebServicesManagerAPI, errorAlert alert: UIAlertController) {
        presentViewController(alert, animated: true, completion: nil)
    }
}
