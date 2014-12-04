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
            cell.textLabel!.text = company.name
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
    
    
    // MARK: - General Class Methods
    
    func insertNewCompany(newCompany: Company) {
        
        var hud = MBProgressHUD(view: navigationController?.view)
        navigationController?.view.addSubview(hud)
        //hud.delegate = self
        hud.labelText = "Loading"
        hud.show(true)
        
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
            company.employeeCount = 0
            
            // Download fundamentals for newly added company.
            var scrapeSuccessful: Bool = false
            webServicesManagerAPI.downloadGoogleSummaryForCompany(company, withCompletion: { (success) -> Void in
                scrapeSuccessful = success
                self.webServicesManagerAPI.downloadGoogleFinancialsForCompany(company, withCompletion: { (success) -> Void in
                    if scrapeSuccessful { scrapeSuccessful = success }
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if !scrapeSuccessful {
                            self.managedObjectContext.deleteObject(company)
                        }
                        // Save the context.
                        var error: NSError? = nil
                        if !self.managedObjectContext.save(&error) {
                            // Replace this implementation with code to handle the error appropriately.
                            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                            //println("Unresolved error \(error), \(error.userInfo)")
                            abort()
                        }
                        hud.hide(true)
                        hud.removeFromSuperview()
                        if scrapeSuccessful {
                            self.performSegueWithIdentifier("unwindFromAddCompany", sender: self)
                        } else {
                            self.showCompanyDataNotFoundAlert()
                        }
                    })
                })
            })
            
        } else {
            
            self.performSegueWithIdentifier("unwindFromAddCompany", sender: self)
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
    
    func showCompanyDataNotFoundAlert() {
        let alert = UIAlertController(title: "Sorry, we are unable to add the selected company.", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.performSegueWithIdentifier("unwindFromAddCompany", sender: self)
        }
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }

    // MARK: - Web Services Manager API Delegate
    
    func webServicesManagerAPI(manager: WebServicesManagerAPI, errorAlert alert: UIAlertController) {
        presentViewController(alert, animated: true, completion: nil)
    }
}
