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
    
    // MARK: - Properties
    
    let webServicesManagerAPI = WebServicesManagerAPI()
    var managedObjectContext: NSManagedObjectContext!
    var companyToAdd: Company?
    var searchResultsCompanies = [Company]()
    
    @IBOutlet weak var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()

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
            
            let cell = tableView.dequeueReusableCellWithIdentifier("companyCell", forIndexPath: indexPath) as UITableViewCell
            let company = searchResultsCompanies[indexPath.row]
            cell.textLabel.text = company.name
            cell.detailTextLabel!.text = company.exchange
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCellWithIdentifier("noResultsCell", forIndexPath: indexPath) as UITableViewCell
            return cell
        }
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Add selected company to Core Data.
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        companyToAdd = searchResultsCompanies[indexPath.row]
        insertNewCompany(companyToAdd!)
    }
    
    func insertNewCompany(newCompany: Company) {
        
        var hud = MBProgressHUD(view: navigationController?.view)
        navigationController?.view.addSubview(hud)
        //hud.delegate = self
        hud.labelText = "Loading"
        hud.show(true)
        
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
        company.employeeCount = 0
        
        // Save the context.
        var error: NSError? = nil
        if !managedObjectContext.save(&error) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //println("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        
        // Download fundamentals for newly added company.
        webServicesManagerAPI.downloadGoogleSummaryForCompany(company, withCompletion: { (success) -> Void in
            self.webServicesManagerAPI.downloadGoogleFinancialsForCompany(company, withCompletion: { (success) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    hud.hide(true)
                    hud.removeFromSuperview()
                    self.performSegueWithIdentifier("unwindFromAddCompany", sender: self)
                })
            })
        })
    }

    // MARK: - Web Services Manager API Delegate
    
    func webServicesManagerAPI(manager: WebServicesManagerAPI, errorAlert alert: UIAlertController) {
        presentViewController(alert, animated: true, completion: nil)
    }
}
