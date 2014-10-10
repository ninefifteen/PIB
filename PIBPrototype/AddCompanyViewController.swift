//
//  AddCompanyViewController.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/6/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

import UIKit
import CoreData

class AddCompanyViewController: BaseAddCompanyTableViewController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, WebServicesMangerAPIDelegate {

    // MARK: - Properties
    
    let webServicesManagerAPI = WebServicesManagerAPI()
    var managedObjectContext: NSManagedObjectContext? = nil
    var companyToAdd: Company?
    
    // The following 2 properties are set in viewDidLoad(),
    // They an implicitly unwrapped optional because they are used in many other places throughout this view controller
    //
    // Search controller to help us with filtering.
    var searchController: UISearchController!
    
    // Secondary search results table view.
    var addCompanyResultsTableViewController: AddCompanyResultsTableViewController!
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        webServicesManagerAPI.managedObjectContext = managedObjectContext
        webServicesManagerAPI.delegate = self
        
        configureSearchController()
    }
    
    func configureSearchController() {
        
        addCompanyResultsTableViewController = AddCompanyResultsTableViewController()
        
        // We want to be the delegate for our filtered table so didSelectRowAtIndexPath(_:) is called for both tables.
        addCompanyResultsTableViewController.tableView.delegate = self
        
        searchController = UISearchController(searchResultsController: addCompanyResultsTableViewController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.sizeToFit()
        tableView.tableHeaderView = searchController.searchBar
        
        searchController.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        //searchController.active = true
        
        // Search is now just presenting a view controller. As such, normal view controller
        // presentation semantics apply. Namely that presentation will walk up the view controller
        // hierarchy until it finds the root view controller or one that defines a presentation context.
        definesPresentationContext = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        
        let searchTerm = searchController.searchBar.text
        
        webServicesManagerAPI.downloadCompaniesMatchingSearchTerm(searchTerm, withCompletion: { (companies, success) -> Void in
            if success {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let resultsController = searchController.searchResultsController as AddCompanyResultsTableViewController
                    resultsController.searchResultsCompanies = companies
                    resultsController.tableView.reloadData()
                })
            }
        });
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let resultsController = searchController.searchResultsController as AddCompanyResultsTableViewController
        companyToAdd = resultsController.searchResultsCompanies[indexPath.row]
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        performSegueWithIdentifier("unwindFromAddCompany", sender: self)
    }

    // MARK: - Table View Data Source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return 0
    }
    
    // MARK: - Web Services Manager API Delegate
    
    func webServicesManagerAPI(manager: WebServicesManagerAPI, errorAlert alert: UIAlertController) {
        presentViewController(alert, animated: true, completion: nil)
    }
}
