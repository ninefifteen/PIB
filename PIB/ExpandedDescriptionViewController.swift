//
//  ExpandedDescriptionViewController.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 12/6/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//

import UIKit

class ExpandedDescriptionViewController: UIViewController {
    
    
    // MARK: - Types
    
    struct GoogleAnalytics {
        static let kExpandedDescriptionScreenName = "Expanded Description"
    }
    
    
    // MARK: - Properties
    
    @IBOutlet weak var descriptionTextView: UITextView!
    
    @IBOutlet weak var revenueLabel: UILabel!
    @IBOutlet weak var employeeCountLabel: UILabel!
    @IBOutlet weak var profitMarginLabel: UILabel!
    @IBOutlet weak var marketCapLabel: UILabel!
    
    var company: Company!    
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if logAnalytics {
            let tracker = GAI.sharedInstance().defaultTracker
            tracker.set(kGAIScreenName, value: GoogleAnalytics.kExpandedDescriptionScreenName)
            tracker.send(GAIDictionaryBuilder.createAppView().build())
        }
        
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
                descriptionTextView.text = company.companyDescription
            }
            
            if company.employeeCount > 0 {
                employeeCountLabel.text = PIBHelper.pibStandardStyleValueStringFromDoubleValue(company.employeeCount.doubleValue)
            } else {
                employeeCountLabel.text = "-"
            }
            
            revenueLabel.text = company.currencySymbol + revenueLabelStringForCompany(company)
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
        }
    }
    
    
    // MARK: - Subview Size Modification
    
    override func viewWillLayoutSubviews() {
        
        super.viewWillLayoutSubviews()
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.descriptionTextView.setContentOffset(CGPointZero, animated: false)
        })
    }
    
    
    // MARK: - Helper Methods
    
    func revenueLabelStringForCompany(company: Company) -> String {
        
        var totalRevenueArray = Array<FinancialMetric>()
        var financialMetrics: [FinancialMetric] = company.financialMetrics.allObjects as [FinancialMetric]
        for (index, financialMetric) in enumerate(financialMetrics) {
            if financialMetric.type == "Revenue" {
                totalRevenueArray.append(financialMetric)
            }
        }
        
        totalRevenueArray.sort({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })
        
        if totalRevenueArray.count > 0 {
            return PIBHelper.pibStandardStyleValueStringFromDoubleValue(Double(totalRevenueArray.last!.value))
        } else {
            return "-"
        }
    }
    
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
            return PIBHelper.pibStandardStyleValueStringFromDoubleValue(Double(ebitdaArray.last!.value))
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
            return PIBHelper.pibPercentageStyleValueStringFromDoubleValue(Double(ebitdaMarginArray.last!.value))
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
            return PIBHelper.pibPercentageStyleValueStringFromDoubleValue(Double(profitMarginArray.last!.value))
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
            return PIBHelper.pibStandardStyleValueStringFromDoubleValue(Double(marketCapArray.last!.value))
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
