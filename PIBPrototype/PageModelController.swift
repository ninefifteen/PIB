//
//  PageModelController.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/21/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

import UIKit

class PageModelController: NSObject, UIPageViewControllerDataSource {
    
    
    // MARK: - Properties
    
    var pages = NSArray()
    var company: Company!
    
    
    // MARK: - Initializers
    
    override init() {
        super.init()
        
        // Create the data model.
        pages = [0, 1, 2, 3, 4]
    }
    
    
    // MARK: - General Methods
    
    func viewControllerAtIndex(index: Int, storyboard: UIStoryboard) -> PageContentViewController? {
    
        if pages.count == 0 || index >= pages.count {
            return nil
        }
        
        // Create a new view controller and pass suitable data.
        
        if  index == 0 {
            
            let pageContentViewController = storyboard.instantiateViewControllerWithIdentifier("CompanyPageViewController") as CompanyPageViewController
            pageContentViewController.pageIndex = index
            pageContentViewController.company = company
            return pageContentViewController
            
        } else {
            
            if  company != nil {
                let pageContentViewController = storyboard.instantiateViewControllerWithIdentifier("GraphPageViewController") as GraphPageViewController
                pageContentViewController.pageIndex = index
                pageContentViewController.company = company
                return pageContentViewController
            } else {
                return nil
            }
            
        }
        
    }
    
    
    // MARK: - Page View Controller Data Source
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        var index = (viewController as PageContentViewController).pageIndex
        if (index == 0) || (index == NSNotFound) {
            return nil
        }
        
        index--
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        var index = (viewController as PageContentViewController).pageIndex
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
