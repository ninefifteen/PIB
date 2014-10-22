//
//  PageContentViewController.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/21/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

import UIKit

class PageContentViewController: UIViewController {
    
    
    // MARK: - Properties
    
    var dataObject: AnyObject?
    
    @IBOutlet weak var nameLabel: UILabel!
    
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let obj: String = dataObject as? String {
            nameLabel!.text = obj
        } else {
            nameLabel!.text = ""
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
