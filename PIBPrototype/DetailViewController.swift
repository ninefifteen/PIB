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
    
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var competitorScrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    weak var graphPageViewController: GraphPageViewController!
    
    var company: Company!
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
                
        if let companyName: String = company?.name {
            title = companyName
            companyNameLabel.text = companyName
        } else {
            title = ""
            companyNameLabel.text = ""
        }
        
        competitorScrollView.contentSize = CGSizeMake(600.0, 71.0)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

