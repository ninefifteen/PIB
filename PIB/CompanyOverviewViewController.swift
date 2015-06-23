//
//  CompanyOverviewViewController.swift
//  PIB
//
//  Created by Shawn Seals on 2/5/15.
//  Copyright (c) 2015 Scoutly. All rights reserved.
//

import UIKit

class CompanyOverviewViewController: UIViewController {
    
    
    // MARK: - Types
    
    struct MainStoryboard {
        
        struct SegueIdentifiers {
            static let kShowPeersTable = "showPeersTable"
            static let kShowPeersTableEditMode = "showPeersTableEditMode"
            static let kShowDescriptionView = "showDescriptionView"
        }
        
        struct TableViewCellIdentifiers {
            static let kPeerTableCell = "peerTableCell"
        }
    }
    
    struct GoogleAnalytics {
        static let kCompanyOverviewScreenName = "Company Overview"
    }
    
    
    // MARK: - Properties
    
    @IBOutlet weak var descriptionTextView: UITextView!
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var revenueLabel: UILabel!
    @IBOutlet weak var employeeCountLabel: UILabel!
    @IBOutlet weak var profitMarginLabel: UILabel!
    @IBOutlet weak var marketCapLabel: UILabel!
    
    var company: Company!
    var managedObjectContext: NSManagedObjectContext!

    var peers = [Company]()
    var peersTableCellCount = 0
    
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        if logAnalytics {
            let tracker = GAI.sharedInstance().defaultTracker
            tracker.set(kGAIScreenName, value: GoogleAnalytics.kCompanyOverviewScreenName)
            let build = GAIDictionaryBuilder.createAppView().build() as [NSObject : AnyObject]
            tracker.send(build)
        }
        
        updateLabels()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Calculate tableview height based on screen height.
    /*override func viewWillLayoutSubviews() {
        
        var maxCellsToDisplay = 0
        let rowHeight = peersTableView.rowHeight
        let buffer: CGFloat = 46.0
        
        if let screenHeight = view.window?.bounds.height {
            
            if screenHeight >= 1024 {
                maxCellsToDisplay = 7
            } else if screenHeight >= 736 {
                maxCellsToDisplay = 5
            } else if screenHeight >= 667 {
                maxCellsToDisplay = 4
            } else if screenHeight >= 568 {
                maxCellsToDisplay = 3
            } else if screenHeight >= 480 {
                maxCellsToDisplay = 2
            } else {
                maxCellsToDisplay = 1
            }
            
            peersTableContainerHeightConstraint.constant = CGFloat(maxCellsToDisplay) * rowHeight + buffer
            peersTableCellCount = maxCellsToDisplay < peers.count ? maxCellsToDisplay : peers.count
        }
    }*/
    
    
    // MARK: - Populate Labels
    
    func updateLabels() {
        
        if company != nil {
            
            if company.city != "" {
                if company.country != "" && company.state != "" {
                    addressLabel.text = company.city.capitalizedString + ", " + company.state.uppercaseString + " " + company.country.capitalizedString
                } else if company.country != "" {
                    addressLabel.text = company.city.capitalizedString + " " + company.country.capitalizedString
                } else {
                    addressLabel.text = company.city.capitalizedString
                }
            } else {
                addressLabel.text = ""
            }
            
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
            
            /*println("\n\(company.name) Targets:")
            for target in company.targets {
                if let targetCompany = target as? Company {
                    println("tickerSymbol: \(targetCompany.tickerSymbol), companyName: \(targetCompany.name), exchangeDisplayName: \(targetCompany.exchangeDisplayName)")
                }
            }*/
        }
    }
    
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == MainStoryboard.SegueIdentifiers.kShowPeersTable {
            
            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! PeersTableViewController
            controller.company = company
            controller.managedObjectContext = managedObjectContext
            controller.isEditMode = false
            controller.navigationItem.leftItemsSupplementBackButton = true
            
        } else if segue.identifier == MainStoryboard.SegueIdentifiers.kShowDescriptionView {
            
            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DescriptionViewController
            controller.company = company
            controller.navigationItem.leftItemsSupplementBackButton = true
        }
    }
    
    
    // MARK: - Helper Methods
    
    func ebitdaLabelStringForCompany(company: Company) -> String {
        
        var ebitdaArray = Array<FinancialMetric>()
        var financialMetrics: [FinancialMetric] = company.financialMetrics.allObjects as! [FinancialMetric]
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
        var financialMetrics: [FinancialMetric] = company.financialMetrics.allObjects as! [FinancialMetric]
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
        var financialMetrics: [FinancialMetric] = company.financialMetrics.allObjects as! [FinancialMetric]
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
        var financialMetrics: [FinancialMetric] = company.financialMetrics.allObjects as! [FinancialMetric]
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