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
    
    @IBOutlet weak var pageContainerView: UIView!
    
    var pageViewController: UIPageViewController?
    
    var company: Company!
    
    var _pageModelController: PageModelController? = nil
    
    var pageModelController: PageModelController {
        // Return the model controller object, creating it if necessary.
        // In more complex implementations, the model controller may be passed to the view controller.
        if _pageModelController == nil {
            _pageModelController = PageModelController()
            _pageModelController!.company = company
        }
        return _pageModelController!
    }

    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Configure the page view controller and add it as a child view controller.
        pageViewController = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        pageViewController!.delegate = self
        
        let startingViewController: PageContentViewController = pageModelController.viewControllerAtIndex(0, storyboard: storyboard!)!
        let viewControllers: NSArray = [startingViewController]
        pageViewController!.setViewControllers(viewControllers, direction: .Forward, animated: false, completion: { done in })
        
        pageViewController!.dataSource = pageModelController
        
        addChildViewController(pageViewController!)
        pageContainerView.addSubview(pageViewController!.view)
        
        // Set the page view controller's bounds using an inset rect so that self's view is visible around the edges of the pages.
        var pageViewRect = pageContainerView.bounds
        self.pageViewController!.view.frame = pageViewRect
        
        self.pageViewController!.didMoveToParentViewController(self)
        
        // Add the page view controller's gesture recognizers to the book view controller's view so that the gestures are started more easily.
        self.view.gestureRecognizers = self.pageViewController!.gestureRecognizers
        
        //self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        
        /*
        // Update the user interface for the detail item.
        if let company: Company = self.company {
            if let label = self.stockNameLabel { label.text = company.name }
            if let label = self.stockExchangeLabel { label.text = company.exchange }
            if let label = self.stockTickerLabel { label.text = company.tickerSymbol }
            if let label = self.stockTickerLabel { title = company.tickerSymbol }
        }
        */
        
        // Temporary: Log all company properties to console.
        /*if let company: Company = self.company {
            println("CurrentPERatioAsPercentOfFiveYearAveragePERatio: \(company.currentPERatioAsPercentOfFiveYearAveragePERatio)")
            println("EBITDAMargin: \(company.ebitdaMargin)")
            println("EBITMargin: \(company.ebitMargin)")
            println("FiveYearAnnualCapitalSpendingGrowthRate: \(company.fiveYearAnnualCapitalSpendingGrowthRate)")
            println("FiveYearAnnualDividendGrowthRate: \(company.fiveYearAnnualDividendGrowthRate)")
            println("FiveYearAnnualIncomeGrowthRate: \(company.fiveYearAnnualIncomeGrowthRate)")
            println("FiveYearAnnualNormalizedIncomeGrowthRate: \(company.fiveYearAnnualNormalizedIncomeGrowthRate)")
            println("FiveYearAnnualRAndDGrowthRate: \(company.fiveYearAnnualRAndDGrowthRate)")
            println("FiveYearAnnualRevenueGrowthRate: \(company.fiveYearAnnualRevenueGrowthRate)")
            println("FiveYearAverageGrossProfitMargin: \(company.fiveYearAverageGrossProfitMargin)")
            println("FiveYearAverageNetProfitMargin: \(company.fiveYearAverageNetProfitMargin)")
            println("FiveYearAveragePostTaxProfitMargin: \(company.fiveYearAveragePostTaxProfitMargin)")
            println("FiveYearAveragePreTaxProfitMargin: \(company.fiveYearAveragePreTaxProfitMargin)")
            println("FiveYearAverageRAndDAsPercentOfSales: \(company.fiveYearAverageRAndDAsPercentOfSales)")
            println("FiveYearAverageSGAndAAsPercentOfSales: \(company.fiveYearAverageSGAndAAsPercentOfSales)")
            println("GrossMargin: \(company.grossMargin)")
            println("MarketValueAsPercentOfRevenues: \(company.marketValueAsPercentOfRevenues)")
            println("RAndDAsPercentOfSales: \(company.rAndDAsPercentOfSales)")
            println("SGAndAAsPercentOfSales: \(company.sgAndAAsPercentOfSales)")
        }*/
    }
    
    
    // MARK: - UIPageViewController delegate methods
    
    func pageViewController(pageViewController: UIPageViewController, spineLocationForInterfaceOrientation orientation: UIInterfaceOrientation) -> UIPageViewControllerSpineLocation {
        // Set the spine position to "min" and the page view controller's view controllers array to contain just one view controller. Setting the spine position to 'UIPageViewControllerSpineLocationMid' in landscape orientation sets the doubleSided property to true, so set it to false here.
        let currentViewController = self.pageViewController!.viewControllers[0] as UIViewController
        let viewControllers: NSArray = [currentViewController]
        self.pageViewController!.setViewControllers(viewControllers, direction: .Forward, animated: true, completion: {done in })
        
        self.pageViewController!.doubleSided = false
        return .Min
    }
}

