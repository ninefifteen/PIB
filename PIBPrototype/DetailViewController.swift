//
//  DetailViewController.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/2/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController, UIPageViewControllerDelegate {
    
    
    // MARK: - Properties
    
    @IBOutlet weak var nameView: UIView!
    @IBOutlet weak var descriptionView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var revenueLabel: UILabel!
    @IBOutlet weak var employeeCountLabel: UILabel!
    @IBOutlet weak var profitMarginLabel: UILabel!
    @IBOutlet weak var marketCapLabel: UILabel!
    
    @IBOutlet weak var descriptionViewHeightContraint: NSLayoutConstraint!
    
    @IBOutlet weak var pageControl: UIPageControl!
    
    weak var graphPageViewController: GraphPageViewController!
    
    var pageIndices = Array<Int>()
    var pageIdentifiers = Array<String>()
    
    var company: Company!
    
    var fullDescription: String = ""
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        let backButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButtonItem
        
        updateLabels()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Subview Size Modification
    
    override func viewWillLayoutSubviews() {
        
        super.viewWillLayoutSubviews()
        
        if descriptionViewHeightContraint.constant > 0 && company != nil {
            
            let fullDescription: String = company.companyDescription
            let fullDescriptionCharacterCount = countElements(fullDescription)
            
            descriptionTextView.text = fullDescription
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.descriptionTextView.setContentOffset(CGPointZero, animated: false)
            })
            
            /*let visibleRange: NSRange = visibleRangeOfTextView(descriptionTextView)
            let trimLength = visibleRange.length - 8

            if trimLength > 0 && trimLength < fullDescriptionCharacterCount - 8 {
                let index: String.Index = advance(fullDescription.startIndex, trimLength)
                let shortDescription: String = fullDescription.substringToIndex(index) + "..."
                descriptionTextView.text = shortDescription
            }*/
        }
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            
            let orientation = UIApplication.sharedApplication().statusBarOrientation
            
            descriptionView.hidden = UIInterfaceOrientationIsLandscape(orientation) ? true : false
            descriptionViewHeightContraint.constant = UIInterfaceOrientationIsLandscape(orientation) ? 0.0 : 128.0
            view.layoutIfNeeded()
            
            pageControl.hidden = false
        }
    }
    
    
    // MARK: - Display Data Methods
    
    func updateLabels() {
        
        if company != nil {
            
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
                locationLabel.text = ""
            }
            
            if company.companyDescription != "" {
                descriptionTextView.text = company.companyDescription
            }
            
            if company.employeeCount > 0 {
                employeeCountLabel.text = PIBHelper.pibStandardStyleValueStringFromDoubleValue(company.employeeCount.doubleValue)
            } else {
                employeeCountLabel.text = "NA"
            }
            
            revenueLabel.text = company.currencySymbol + revenueLabelStringForCompany(company)
            profitMarginLabel.text = profitMarginLabelStringForCompany(company)
            marketCapLabel.text = company.currencySymbol + marketCapLabelStringForCompany(company)
            
            pageControl.hidden = false
            
        } else {
            
            nameLabel.hidden = true
            descriptionView.hidden = true
            pageControl.hidden = true
        }
    }
    
    
    func determineGraphsToBeDisplayed() {
        
        if company != nil {
            
            var financialMetrics: [FinancialMetric] = company.financialMetrics.allObjects as [FinancialMetric]
            
            var totalRevenueArray = Array<FinancialMetric>()
            var profitMarginArray = Array<FinancialMetric>()
            var revenueGrowthArray = Array<FinancialMetric>()
            var netIncomeGrowthArray = Array<FinancialMetric>()
            var grossProfitArray = Array<FinancialMetric>()
            var grossMarginArray = Array<FinancialMetric>()
            var rAndDArray = Array<FinancialMetric>()
            var sgAndAArray = Array<FinancialMetric>()
            
            for (index, financialMetric) in enumerate(financialMetrics) {
                switch financialMetric.type {
                case "Revenue":
                    totalRevenueArray.append(financialMetric)
                case "Profit Margin":
                    profitMarginArray.append(financialMetric)
                case "Revenue Growth":
                    revenueGrowthArray.append(financialMetric)
                case "Net Income Growth":
                    netIncomeGrowthArray.append(financialMetric)
                case "Gross Margin":
                    grossMarginArray.append(financialMetric)
                case "SG&A As Percent Of Revenue":
                    sgAndAArray.append(financialMetric)
                case "R&D As Percent Of Revenue":
                    rAndDArray.append(financialMetric)
                default:
                    break
                }
            }
            
            if minimumValueInFinancialMetricArray(totalRevenueArray) != 0.0 || maximumValueInFinancialMetricArray(totalRevenueArray) != 0.0 {
                pageIdentifiers.append("Revenue")
            }
            
            if minimumValueInFinancialMetricArray(revenueGrowthArray) != 0.0 || maximumValueInFinancialMetricArray(revenueGrowthArray) != 0.0 {
                pageIdentifiers.append("Growth")
            }
            
            if minimumValueInFinancialMetricArray(grossMarginArray) != 0.0 || maximumValueInFinancialMetricArray(grossMarginArray) != 0.0 {
                pageIdentifiers.append("GrossMargin")
            }
            
            if minimumValueInFinancialMetricArray(sgAndAArray) != 0.0 || maximumValueInFinancialMetricArray(sgAndAArray) != 0.0 {
                pageIdentifiers.append("SG&A")
            }
            
            if minimumValueInFinancialMetricArray(rAndDArray) != 0.0 || maximumValueInFinancialMetricArray(rAndDArray) != 0.0 {
                pageIdentifiers.append("R&D")
            }
            
            for (index, pageIdentifier) in enumerate(pageIdentifiers) {
                pageIndices.append(index)
            }
            
            pageControl.numberOfPages = pageIndices.count
        }
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
        
        totalRevenueArray.sort({ $0.year < $1.year })
        
        if totalRevenueArray.count > 0 {
            return PIBHelper.pibStandardStyleValueStringFromDoubleValue(Double(totalRevenueArray.last!.value))
        } else {
            return "NA"
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
        
        ebitdaArray.sort({ $0.year < $1.year })
        
        if ebitdaArray.count > 0 {
            return PIBHelper.pibStandardStyleValueStringFromDoubleValue(Double(ebitdaArray.last!.value))
        } else {
            return "NA"
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
        
        ebitdaMarginArray.sort({ $0.year < $1.year })
        
        if ebitdaMarginArray.count > 0 {
            return PIBHelper.pibPercentageStyleValueStringFromDoubleValue(Double(ebitdaMarginArray.last!.value))
        } else {
            return "NA"
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
        
        profitMarginArray.sort({ $0.year < $1.year })
        
        if profitMarginArray.count > 0 {
            return PIBHelper.pibPercentageStyleValueStringFromDoubleValue(Double(profitMarginArray.last!.value))
        } else {
            return "NA"
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
            return "NA"
        }
    }
    
    func visibleRangeOfTextView(textView: UITextView) -> NSRange {
        let bounds: CGRect = textView.bounds
        let start: UITextPosition = textView.beginningOfDocument
        if let textRange: UITextRange = textView.characterRangeAtPoint(CGPointMake(CGRectGetMaxX(bounds), CGRectGetMaxY(bounds))) {
            let end: UITextPosition = textRange.end
            return NSMakeRange(0, textView.offsetFromPosition(start, toPosition: end))
        } else {
            return NSMakeRange(0, 0)
        }
    }
        
    func minimumValueInFinancialMetricArray(financialMetrics: Array<FinancialMetric>) -> Double {
        
        var minimumValue: Double = 0.0
        
        for (index, financialMetric) in enumerate(financialMetrics) {
            let currentValue: Double = Double(financialMetric.value)
            if currentValue < minimumValue { minimumValue = currentValue }
        }
        
        return minimumValue
    }
    
    func maximumValueInFinancialMetricArray(financialMetrics: Array<FinancialMetric>) -> Double {
        
        var maximumValue: Double = 0.0
        
        for (index, financialMetric) in enumerate(financialMetrics) {
            let currentValue: Double = Double(financialMetric.value)
            if currentValue > maximumValue { maximumValue = currentValue }
        }
        
        return maximumValue
    }
    
    
    // MARK: - UIPageControl
    
    @IBAction func pageControlValueChanged(sender: UIPageControl) {
        let newPageIndex = sender.currentPage
        graphPageViewController.scrollToViewControllerAtIndex(newPageIndex)
    }
    
    
    // MARK: - UIPageViewControllerDelegate
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [AnyObject], transitionCompleted completed: Bool) {
        let currentContentPage = graphPageViewController.viewControllers.last as GraphContentViewController
        let currentPageIndex = currentContentPage.pageIndex
        pageControl.currentPage = currentPageIndex
    }
    
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "embedGraph" {
            determineGraphsToBeDisplayed()
            graphPageViewController = segue.destinationViewController as GraphPageViewController
            graphPageViewController.company = company
            graphPageViewController.pageIndices = pageIndices
            graphPageViewController.pageIdentifiers = pageIdentifiers
            graphPageViewController.delegate = self
        } else if segue.identifier == "showExpandedDescription" {
            let expandedDescriptionViewController = segue.destinationViewController as ExpandedDescriptionViewController
            expandedDescriptionViewController.company = company
        }
    }
}

