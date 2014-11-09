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
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var revenueLabel: UILabel!
    @IBOutlet weak var employeeCountLabel: UILabel!
    @IBOutlet weak var marginLabel: UILabel!
    
    
    @IBOutlet weak var competitorScrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    weak var graphPageViewController: GraphPageViewController!
    
    var company: Company!
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        updateTopViewLabels()
        
        competitorScrollView.contentSize = CGSizeMake(600.0, 71.0)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Populate Labels
    
    func updateTopViewLabels() {
        
        if company != nil {
            
            nameLabel.text = company.name
            
            if company.city != "" {
                if company.country != "" {
                    locationLabel.text = company.city.uppercaseString + ", " + company.country.uppercaseString
                } else {
                    locationLabel.text = company.city.uppercaseString
                }
            } else {
                locationLabel.text = ""
            }
            
            if company.companyDescription != "" {
                descriptionTextView.text = company.companyDescription
                descriptionTextView.setContentOffset(CGPointMake(0.0, -20.0), animated: false)
            }
            
            if company.employeeCount > 0 {
                
                var employeeCount: Double = company.employeeCount.doubleValue
                
                let formatter = NSNumberFormatter()
                formatter.usesSignificantDigits = true
                formatter.maximumSignificantDigits = 3
                formatter.minimumSignificantDigits = 3
                formatter.roundingMode = NSNumberFormatterRoundingMode.RoundHalfUp
                
                if employeeCount >= 1000000.0 {
                    employeeCount /= 1000000.0
                    employeeCountLabel.text = formatter.stringFromNumber(employeeCount)! + " M"
                } else if employeeCount >= 1000.0 {
                    employeeCount /= 1000.0
                    employeeCountLabel.text = formatter.stringFromNumber(employeeCount)! + " K"
                } else {
                    employeeCountLabel.text = formatter.stringFromNumber(employeeCount)!
                }
                
            } else {
                employeeCountLabel.text = "NA"
            }
            
        } else {
            
            nameLabel.text = ""
            locationLabel.text = ""
        }
    }
    
    
    // MARK: - Formatting Methods
    
    func roundNumber(number: Double, toSignificantFigures significantFigures: Int) -> Double {
        
        if number == 0.0 { return 0.0 }
        
        let places: Double = ceil(log10(number < 0 ? -number : number))
        let power: Int = significantFigures - Int(places)
        let magnitude: Double = pow(10.0, Double(power))
        
        let shifted: Int = Int(round(number * magnitude))
        
        return Double(shifted)/magnitude
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
        }
    }
}

