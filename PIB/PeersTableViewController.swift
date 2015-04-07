//
//  PeersTableViewController.swift
//  PIB
//
//  Created by Shawn Seals on 2/5/15.
//  Copyright (c) 2015 Scoutly. All rights reserved.
//

import UIKit

class PeersTableViewController: UITableViewController {
    
    
    // MARK: - Types
    
    struct MainStoryboard {
        
        struct SegueIdentifiers {
            static let kAddCompany = "addCompany"
        }
        
        struct TableViewCellIdentifiers {
            static let kPeerTableCell = "peerTableCell"
        }
    }
    
    
    // MARK: - Properties
    
    var company: Company!
    var managedObjectContext: NSManagedObjectContext!

    var peers = [Company]()
    
    var isEditMode = false
    
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        title = company.name
        editButtonItem()
        navigationItem.rightBarButtonItem = editButtonItem()
        tableView.editing = isEditMode
        editing = isEditMode
        
        navigationController?.toolbarHidden = false
        navigationController?.toolbar.barTintColor = UIColor(red: 227.0/255.0, green: 48.0/255.0, blue: 53.0/255.0, alpha: 1.0)
        
        if company.peers.count > 0 {
            peers = company.peers.allObjects as [Company]
            peers.sort({ $0.name < $1.name })
            tableView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Button Functions
    
    @IBAction func addButtonPressed(sender: UIBarButtonItem) {
        
    }
    

    
    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peers.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.kPeerTableCell, forIndexPath: indexPath) as UITableViewCell
        
        let company = peers[indexPath.row] as Company
        
        let nameLabel = cell.viewWithTag(101) as UILabel
        let locationLabel = cell.viewWithTag(102) as UILabel
        let revenueLabel = cell.viewWithTag(103) as UILabel
        
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
        
        revenueLabel.text = company.currencySymbol + company.revenueLabelString()
        
        return cell
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

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            let peerCompany = peers[indexPath.row] as Company
            company.removePeerCompany(peerCompany, inManagedObjectContext: managedObjectContext)
            peers.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == MainStoryboard.SegueIdentifiers.kAddCompany {
            
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
            
            if Company.isSavedCompanyWithTickerSymbol(companyToAdd.tickerSymbol, exchangeDisplayName: companyToAdd.exchangeDisplayName, inManagedObjectContext: managedObjectContext) {
                
                company.addPeerCompanyWithTickerSymbol(companyToAdd.tickerSymbol, withExchangeDisplayName: companyToAdd.exchangeDisplayName, inManagedObjectContext: managedObjectContext)
                
                var error: NSError? = nil
                if !managedObjectContext.save(&error) {
                    println("Save Error in changeFromTargetToPeerInManagedObjectContext(_:) while removing peers.")
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    //println("Unresolved error \(error), \(error.userInfo)")
                    abort()
                }
                
                if self.company.peers.count > 0 {
                    self.peers = self.company.peers.allObjects as [Company]
                    self.peers.sort({ $0.name.lowercaseString < $1.name.lowercaseString })
                    self.tableView.reloadData()
                }
                
            } else {
                
                Company.saveNewPeerCompanyWithName(companyToAdd.name, tickerSymbol: companyToAdd.tickerSymbol, exchangeDisplayName: companyToAdd.exchangeDisplayName, inManagedObjectContext: managedObjectContext, withCompletion: { (success) -> Void in
                    if success {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            var error: NSError? = nil
                            if !self.managedObjectContext.save(&error) {
                                println("Save Error in changeFromTargetToPeerInManagedObjectContext(_:) while removing peers.")
                                // Replace this implementation with code to handle the error appropriately.
                                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                                //println("Unresolved error \(error), \(error.userInfo)")
                                abort()
                            }
                            
                            self.company.addPeerCompanyWithTickerSymbol(companyToAdd.tickerSymbol, withExchangeDisplayName: companyToAdd.exchangeDisplayName, inManagedObjectContext: self.managedObjectContext)
                            
                            error = nil
                            if !self.managedObjectContext.save(&error) {
                                println("Save Error in changeFromTargetToPeerInManagedObjectContext(_:) while removing peers.")
                                // Replace this implementation with code to handle the error appropriately.
                                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                                //println("Unresolved error \(error), \(error.userInfo)")
                                abort()
                            }
                            
                            if self.company.peers.count > 0 {
                                self.peers = self.company.peers.allObjects as [Company]
                                self.peers.sort({ $0.name.lowercaseString < $1.name.lowercaseString })
                                self.tableView.reloadData()
                            }
                        })
                    }
                })
            }
            
        } else {
            controller.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        }
    }

}


















