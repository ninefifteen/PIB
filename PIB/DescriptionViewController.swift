//
//  DescriptionViewController.swift
//  PIB
//
//  Created by Shawn Seals on 2/6/15.
//  Copyright (c) 2015 Scoutly. All rights reserved.
//

import UIKit

class DescriptionViewController: UIViewController {

    
    // MARK: - Properties
    
    @IBOutlet weak var descriptionTextView: UITextView!
    
    var company: Company!
    
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        title = company.name
        
        updateLabels()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillLayoutSubviews() {
    
        super.viewWillLayoutSubviews()
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.descriptionTextView.setContentOffset(CGPointZero, animated: false)
        })
    }
    
    
    // MARK: - Populate Labels
    
    func updateLabels() {
        
        if company != nil {
            descriptionTextView.text = company.companyDescription
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
