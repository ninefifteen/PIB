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
            static let kAddPeerTableCell = "addPeerTableCell"
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
        
        //title = company.name
        //editButtonItem()
        //navigationItem.rightBarButtonItem = editButtonItem()
        //tableView.editing = isEditMode
        //editing = isEditMode
        
        //navigationController?.toolbarHidden = false
        //navigationController?.toolbar.barTintColor = UIColor(red: 227.0/255.0, green: 48.0/255.0, blue: 53.0/255.0, alpha: 1.0)
        
        if company.peers.count > 0 {
            peers = company.peers.allObjects as! [Company]
            peers.sort({ $0.name < $1.name })
            tableView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Table View
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.reloadData()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.editing {
            return peers.count + 1
        } else {
            return peers.count
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.row < peers.count {
            
            let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.kPeerTableCell, forIndexPath: indexPath) as! UITableViewCell
            
            let company = peers[indexPath.row] as Company
            
            let nameLabel = cell.viewWithTag(101) as! UILabel
            let locationLabel = cell.viewWithTag(102) as! UILabel
            let revenueLabel = cell.viewWithTag(103) as! UILabel
            let revenueTitleLabel = cell.viewWithTag(104) as! UILabel
            let activityIndicator = cell.viewWithTag(105) as! UIActivityIndicatorView
            let noDataAvailableLabel = cell.viewWithTag(106) as! UILabel
            
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
                    let button = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
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
            
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.kAddPeerTableCell, forIndexPath: indexPath) as! UITableViewCell
            return cell
        }
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
        if indexPath.row < peers.count {
            return true
        } else {
            return false
        }
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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        println("didSelectRowAtIndexPath")

        if indexPath.row == peers.count { }
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
            let navigationController = segue.destinationViewController as! UINavigationController
            navigationController.view.tintColor = UIColor.whiteColor()
            let controller = navigationController.topViewController as! AddCompanyTableViewController
            controller.managedObjectContext = managedObjectContext
        }
    }
    
    @IBAction func unwindFromAddCompanySegue(segue: UIStoryboardSegue) {
        let controller = segue.sourceViewController as! AddCompanyTableViewController
        
        if let companyToAdd = controller.companyToAdd {
            
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
                    self.peers = self.company.peers.allObjects as! [Company]
                    self.peers.sort({ $0.name.lowercaseString < $1.name.lowercaseString })
                    self.tableView.reloadData()
                }
                
            } else {
                
                let newPeerCompany = Company.newUserAddedPeerCompanyWithName(companyToAdd.name, tickerSymbol: companyToAdd.tickerSymbol, exchangeDisplayName: companyToAdd.exchangeDisplayName, inManagedObjectContext: managedObjectContext)
                
                var error: NSError? = nil
                if !self.managedObjectContext.save(&error) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    //println("Unresolved error \(error), \(error.userInfo)")
                    abort()
                }
                
                company.addPeerCompanyWithTickerSymbol(newPeerCompany.tickerSymbol, withExchangeDisplayName: newPeerCompany.exchangeDisplayName, inManagedObjectContext: managedObjectContext)
                
                if self.company.peers.count > 0 {
                    
                    self.peers = self.company.peers.allObjects as! [Company]
                    self.peers.sort({ $0.name.lowercaseString < $1.name.lowercaseString })
                    self.tableView.reloadData()
                    
                    newPeerCompany.addPeerDataForCompanyInManagedObjectContext(managedObjectContext, withCompletion: { (success) -> Void in
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            var error: NSError? = nil
                            if !self.managedObjectContext.save(&error) {
                                // Replace this implementation with code to handle the error appropriately.
                                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                                //println("Unresolved error \(error), \(error.userInfo)")
                                abort()
                            }
                            
                            self.tableView.reloadData()
                        })
                    })
                }
            }
            
        } else {
            controller.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        }
    }

}


















