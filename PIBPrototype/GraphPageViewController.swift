//
//  GraphPageViewController.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/31/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//

import UIKit

class GraphPageViewController: UIPageViewController, UIPageViewControllerDataSource {
    
    // MARK: - Properties
    
    var pageIndices = Array<Int>()
    var pageIdentifiers = Array<String>()
    var company: Company!
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let graphContentViewController = self.viewControllerAtIndex(0, storyboard: storyboard!)
        
        if graphContentViewController != nil {
            self.dataSource = self
            setViewControllers([graphContentViewController!], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
        }
    }
    
    
    // MARK: - General Methods
    
    
    func viewControllerAtIndex(index: Int, storyboard: UIStoryboard) -> GraphContentViewController? {

        if pageIndices.count == 0 || index >= pageIndices.count {
            return nil
        }
        
        // Create a new view controller and pass suitable data.
        if  company != nil {
            let graphContentViewController = storyboard.instantiateViewControllerWithIdentifier("GraphContentViewController") as GraphContentViewController
            graphContentViewController.pageIdentifier = pageIdentifiers[index]
            graphContentViewController.pageIndex = index
            graphContentViewController.company = company
            return graphContentViewController
        } else {
            return nil
        }
    }
    
    func scrollToViewControllerAtIndex(index: Int) {
        let graphContentViewController = self.viewControllerAtIndex(index, storyboard: storyboard!)
        if graphContentViewController != nil {
            setViewControllers([graphContentViewController!], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)
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
        if index == self.pageIndices.count {
            return nil
        }
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }

}
