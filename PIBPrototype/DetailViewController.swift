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

