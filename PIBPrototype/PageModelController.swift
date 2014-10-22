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
    
    var pageContent = NSArray()
    
    
    // MARK: - Initializers
    
    override init() {
        super.init()
        
        // Create the data model.
        pageContent = ["Page 1", "Page 2", "Page 3"]
    }
    
    
    // MARK: - General Methods
    
    func viewControllerAtIndex(index: Int, storyboard: UIStoryboard) -> PageContentViewController? {
    
        if pageContent.count == 0 || index >= pageContent.count {
            return nil
        }
        
        // Create a new view controller and pass suitable data.
        let pageContentViewController = storyboard.instantiateViewControllerWithIdentifier("PageContentViewController") as PageContentViewController
        pageContentViewController.dataObject = pageContent[index]
        return pageContentViewController
    }
    
    func indexOfViewController(viewController: PageContentViewController) -> Int {
        // Return the index of the given data view controller.
        // For simplicity, this implementation uses a static array of model objects and the view controller stores the model object; you can therefore use the model object to identify the index.
        if let dataObject: AnyObject = viewController.dataObject {
            return self.pageContent.indexOfObject(dataObject)
        } else {
            return NSNotFound
        }
    }
    
    // MARK: - Page View Controller Data Source
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        var index = self.indexOfViewController(viewController as PageContentViewController)
        if (index == 0) || (index == NSNotFound) {
            return nil
        }
        
        index--
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        var index = self.indexOfViewController(viewController as PageContentViewController)
        if index == NSNotFound {
            return nil
        }
        
        index++
        if index == self.pageContent.count {
            return nil
        }
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }
}
