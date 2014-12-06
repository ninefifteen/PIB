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
    
    @IBOutlet weak var descriptionViewHeightContraint: NSLayoutConstraint!
    
    @IBOutlet weak var pageControl: UIPageControl!
    
    weak var graphPageViewController: GraphPageViewController!
    
    var company: Company!
    
    var fullDescription: String = ""
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        
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
    
    
    // MARK: - Populate Labels
    
    func updateLabels() {
        
        if company != nil {
            
            nameLabel.text = company.name
            
            if company.city != "" {
                if company.country != "" {
                    locationLabel.text = company.city.capitalizedString + ", " + company.state.uppercaseString + " " + company.country.capitalizedString
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
            
            pageControl.hidden = false
            
        } else {
            
            nameLabel.hidden = true
            descriptionView.hidden = true
            pageControl.hidden = true
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
            graphPageViewController = segue.destinationViewController as GraphPageViewController
            graphPageViewController.company = company
            graphPageViewController.delegate = self
        } else if segue.identifier == "showExpandedDescription" {
            let expandedDescriptionViewController = segue.destinationViewController as ExpandedDescriptionViewController
            expandedDescriptionViewController.company = company
        }
    }
}

