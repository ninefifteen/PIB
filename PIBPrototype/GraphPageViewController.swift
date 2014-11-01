//
//  GraphPageViewController.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/31/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

import UIKit

class GraphPageViewController: UIPageViewController, UIPageViewControllerDataSource {
    
    // MARK: - Properties
    
    var pages = NSArray()
    var company: Company!
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Create the data model.
        pages = [0, 1, 2, 3]
        
        let graphContentViewController = self.viewControllerAtIndex(0, storyboard: storyboard!)
        
        if graphContentViewController != nil {
            self.dataSource = self
            setViewControllers([graphContentViewController!], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
        }
    }
    
    
    // MARK: - General Methods
    
    func viewControllerAtIndex(index: Int, storyboard: UIStoryboard) -> GraphContentViewController? {

        if pages.count == 0 || index >= pages.count {
            return nil
        }
        
        // Create a new view controller and pass suitable data.
        if  company != nil {
            let graphContentViewController = storyboard.instantiateViewControllerWithIdentifier("GraphContentViewController") as GraphContentViewController
            graphContentViewController.pageIndex = index
            graphContentViewController.company = company
            return graphContentViewController
        } else {
            return nil
        }
    }
    
    
    // MARK: - Page View Controller Data Source
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        var index = (viewController as GraphContentViewController).pageIndex
        if (index == 0) || (index == NSNotFound) {
            return nil
        }
        
        index--
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        var index = (viewController as GraphContentViewController).pageIndex
        if index == NSNotFound {
            return nil
        }
        
        index++
        if index == self.pages.count {
            return nil
        }
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }

}
