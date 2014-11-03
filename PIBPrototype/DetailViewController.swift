//
//  DetailViewController.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/2/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    
    // MARK: - Properties
    
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var competitorScrollView: UIScrollView!
    
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
    
    
    /*
    // Used in old design.
    func configureFullSizePageViewController() {
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
    }
    */
    
    override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "embedGraph" {
            let controller = segue.destinationViewController as GraphPageViewController
            controller.company = company
        }
    }
}

