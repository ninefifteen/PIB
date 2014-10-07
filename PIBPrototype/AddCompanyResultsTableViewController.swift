//
//  AddCompanyResultsTableViewController.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/6/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

import UIKit

class AddCompanyResultsTableViewController: BaseAddCompanyTableViewController {
    
    // MARK: - Properties

    var searchResultsCompanies = [Company]()
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchResultsCompanies.count > 0 {
            return searchResultsCompanies.count
        } else {
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if searchResultsCompanies.count > 1 {
            
            let cell = tableView.dequeueReusableCellWithIdentifier(addCompanyTableCellIndentifier) as UITableViewCell
            
            let company = searchResultsCompanies[indexPath.row]
            configureCell(cell, forCompany: company)
            
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCellWithIdentifier(noResultsTableCellIdentifier) as UITableViewCell
            return cell
        }
    }
}
