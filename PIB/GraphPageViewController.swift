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
    var managedObjectContext: NSManagedObjectContext!
    
    weak var graphContentViewControllerDelegate: DetailViewController!
    
    var currentViewController: GraphContentViewController?
    var viewControllerBeforeCurrentViewController: GraphContentViewController?
    var viewControllerAfterCurrentViewController: GraphContentViewController?
    
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        currentViewController = viewControllerAtIndex(0, storyboard: storyboard!)
        viewControllerBeforeCurrentViewController = viewControllerAtIndex(-1, storyboard: storyboard!)
        viewControllerAfterCurrentViewController = viewControllerAtIndex(1, storyboard: storyboard!)
        
        let graphContentViewController = currentViewController
        
        if graphContentViewController != nil {
            self.dataSource = self
            setViewControllers([graphContentViewController!], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
        }
    }
    
    
    // MARK: - General Methods
    
    func viewControllerAtIndex(index: Int, storyboard: UIStoryboard) -> GraphContentViewController? {
        
        println("\nviewControllerAtIndex")

        if pageIndices.count == 0 || index < 0 || index >= pageIndices.count {
            return nil
        }
        
        // Create a new view controller and pass suitable data.
        if  company != nil {
            println("creating \(pageIdentifiers[index]) ViewController")
            let graphContentViewController = storyboard.instantiateViewControllerWithIdentifier("GraphContentViewController") as GraphContentViewController
            graphContentViewController.pageIdentifier = pageIdentifiers[index]
            graphContentViewController.pageIndex = index
            graphContentViewController.company = company
            graphContentViewController.managedObjectContext = managedObjectContext
            graphContentViewController.delegate = graphContentViewControllerDelegate
            return graphContentViewController
        } else {
            return nil
        }
    }
    
    func scrollToViewControllerAtIndex(index: Int) {
        
         println("\nscrollToViewControllerAtIndex")
        
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
        
        viewControllerAfterCurrentViewController = currentViewController
        currentViewController = viewControllerBeforeCurrentViewController
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            self.viewControllerBeforeCurrentViewController = self.viewControllerAtIndex(index - 2, storyboard: self.storyboard!)
        })
        
        return currentViewController
        
        /*index--
        println("\nviewControllerBeforeViewController: \(pageIdentifiers[index])")
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)*/
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
                
        var index = (viewController as GraphContentViewController).pageIndex
        if index == NSNotFound {
            println("\nviewControllerBeforeViewController: nil)")
            return nil
        }
        
        index++
        if index == self.pageIndices.count {
            return nil
        }
        
        viewControllerBeforeCurrentViewController = currentViewController
        currentViewController = viewControllerAfterCurrentViewController
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            self.viewControllerAfterCurrentViewController = self.viewControllerAtIndex(index + 1, storyboard: self.storyboard!)
        })
        
        return currentViewController
        
        /*println("\nviewControllerAfterViewController: \(pageIdentifiers[index])")
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)*/
    }

}
