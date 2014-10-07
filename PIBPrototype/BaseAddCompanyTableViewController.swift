//
//  BaseAddCompanyTableViewController.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/6/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//
//  Base or common view controller to share a common UITableViewCell prototype between subclasses.
//

import UIKit

class BaseAddCompanyTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    let addCompanyTableCellIndentifier = "addCompanyCell"
    let noResultsTableCellIdentifier = "noResultsCell"

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let addCompanyTableCellNib = UINib(nibName: "AddCompanyTableCell", bundle: nil)
        let noResultsTableCellNib = UINib(nibName: "NoResultsTableCell", bundle: nil)
        
        // Required if our subclasses are to use: dequeueReusableCellWithIdentifier:forIndexPath:
        tableView.registerNib(addCompanyTableCellNib, forCellReuseIdentifier: addCompanyTableCellIndentifier)
        tableView.registerNib(noResultsTableCellNib, forCellReuseIdentifier: noResultsTableCellIdentifier)
    }
    
    // MARK: - Helper Methods
    
    func configureCell(cell: UITableViewCell, forCompany company: Company) {
        
        cell.textLabel!.text = company.name
        cell.detailTextLabel!.text = company.exchange
    }

}
