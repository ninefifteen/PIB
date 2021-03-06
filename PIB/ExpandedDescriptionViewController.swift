//
//  ExpandedDescriptionViewController.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 12/6/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//

import UIKit

class ExpandedDescriptionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    // MARK: - Types
    
    struct MainStoryboard {
        
        struct SegueIdentifiers {
            static let kShowPeersTable = "showPeersTable"
        }
        
        struct TableViewCellIdentifiers {
            static let kPeerTableCell = "peerTableCell"
        }
    }
    
    struct GoogleAnalytics {
        static let kExpandedDescriptionScreenName = "Expanded Description"
    }
    
    
    // MARK: - Properties
    
    @IBOutlet weak var descriptionTextView: UITextView!
    
    @IBOutlet weak var revenueLabel: UILabel!
    @IBOutlet weak var employeeCountLabel: UILabel!
    @IBOutlet weak var profitMarginLabel: UILabel!
    @IBOutlet weak var marketCapLabel: UILabel!
    
    @IBOutlet weak var peersTableView: UITableView!
    
    var company: Company!
    
    var peers = [Company]()
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if logAnalytics {
            let tracker = GAI.sharedInstance().defaultTracker
            tracker.set(kGAIScreenName, value: GoogleAnalytics.kExpandedDescriptionScreenName)
            tracker.send(GAIDictionaryBuilder.createAppView().build())
        }
        
        peersTableView.dataSource = self
        peersTableView.delegate = self
        
        updateLabels()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Populate Labels
    
    func updateLabels() {
        
        if company != nil {
            
            if company.companyDescription != "" {
                descriptionTextView.scrollEnabled = false
                descriptionTextView.textContainer.maximumNumberOfLines = 0
                descriptionTextView.textContainer.lineBreakMode = NSLineBreakMode.ByTruncatingTail
                descriptionTextView.text = company.companyDescription
            }
            
            if company.employeeCount > 0 {
                employeeCountLabel.text = company.employeeCount.doubleValue.pibStandardStyleValueString()
            } else {
                employeeCountLabel.text = "-"
            }
            
            revenueLabel.text = company.currencySymbol + company.revenueLabelString()
            profitMarginLabel.text = profitMarginLabelStringForCompany(company)
            marketCapLabel.text = "$" + marketCapLabelStringForCompany(company)
            
            println("\n\(company.name) Peers:")
            for peer in company.peers {
                if let peerCompany = peer as? Company {
                    println("tickerSymbol: \(peerCompany.tickerSymbol), companyName: \(peerCompany.name), exchangeDisplayName: \(peerCompany.exchangeDisplayName)")
                }
            }
            
            println("\n\(company.name) Targets:")
            for target in company.targets {
                if let targetCompany = target as? Company {
                    println("tickerSymbol: \(targetCompany.tickerSymbol), companyName: \(targetCompany.name), exchangeDisplayName: \(targetCompany.exchangeDisplayName)")
                }
            }
            
            if company.peers.count > 0 {
                peers = company.peers.allObjects as [Company]
                peersTableView.reloadData()
            }
        }
    }
    
    
    // MARK: - Table View
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peers.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
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
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if cell.respondsToSelector("setSeparatorInset:") {
            cell.separatorInset = UIEdgeInsetsZero
        }
        if cell.respondsToSelector("setPreservesSuperviewLayoutMargins:") {
            cell.preservesSuperviewLayoutMargins = false
        }
        if cell.respondsToSelector("setLayoutMargins:") {
            cell.layoutMargins = UIEdgeInsetsMake(0.0, 8.0, 0.0, 0.0)
        }
    }
    
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == MainStoryboard.SegueIdentifiers.kShowPeersTable {
            let controller = (segue.destinationViewController as UINavigationController).topViewController as PeersTableViewController
            controller.peers = peers
            controller.navigationItem.leftItemsSupplementBackButton = true
        }
    }
    
    
    // MARK: - Helper Methods
    
    func ebitdaLabelStringForCompany(company: Company) -> String {
        
        var ebitdaArray = Array<FinancialMetric>()
        var financialMetrics: [FinancialMetric] = company.financialMetrics.allObjects as [FinancialMetric]
        for (index, financialMetric) in enumerate(financialMetrics) {
            if financialMetric.type == "EBITDA" {
                ebitdaArray.append(financialMetric)
            }
        }
        
        ebitdaArray.sort({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })
        
        if ebitdaArray.count > 0 {
            return Double(ebitdaArray.last!.value).pibStandardStyleValueString()
        } else {
            return "-"
        }
    }
    
    func ebitdaMarginLabelStringForCompany(company: Company) -> String {
        
        var ebitdaMarginArray = Array<FinancialMetric>()
        var financialMetrics: [FinancialMetric] = company.financialMetrics.allObjects as [FinancialMetric]
        for (index, financialMetric) in enumerate(financialMetrics) {
            if financialMetric.type == "EBITDA Margin" {
                ebitdaMarginArray.append(financialMetric)
            }
        }
        
        ebitdaMarginArray.sort({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })
        
        if ebitdaMarginArray.count > 0 {
            return Double(ebitdaMarginArray.last!.value).pibPercentageStyleValueString()
        } else {
            return "-"
        }
    }
    
    func profitMarginLabelStringForCompany(company: Company) -> String {
        
        var profitMarginArray = Array<FinancialMetric>()
        var financialMetrics: [FinancialMetric] = company.financialMetrics.allObjects as [FinancialMetric]
        for (index, financialMetric) in enumerate(financialMetrics) {
            if financialMetric.type == "Profit Margin" {
                profitMarginArray.append(financialMetric)
            }
        }
        
        profitMarginArray.sort({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })
        
        if profitMarginArray.count > 0 {
            return Double(profitMarginArray.last!.value).pibPercentageStyleValueString()
        } else {
            return "-"
        }
    }
    
    func marketCapLabelStringForCompany(company: Company) -> String {
        
        var marketCapArray = Array<FinancialMetric>()
        var financialMetrics: [FinancialMetric] = company.financialMetrics.allObjects as [FinancialMetric]
        for (index, financialMetric) in enumerate(financialMetrics) {
            if financialMetric.type == "Market Cap" {
                marketCapArray.append(financialMetric)
            }
        }
        
        if marketCapArray.count > 0 {
            return Double(marketCapArray.last!.value).pibStandardStyleValueString()
        } else {
            return "-"
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
