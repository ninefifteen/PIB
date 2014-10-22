//
//  CompanyPageViewController.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/21/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

import UIKit

class CompanyPageViewController: PageContentViewController {

    
    // MARK: - Properties
    
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var exchangeNameLabel: UILabel!
    @IBOutlet weak var tickerSymbolLabel: UILabel!
    
    var company: Company!
    
    
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
        
        if let labelText: String = company?.name {
            companyNameLabel!.text = labelText
        } else {
            companyNameLabel!.text = ""
        }
        
        if let labelText: String = company?.exchangeDisp {
            exchangeNameLabel!.text = labelText
        } else {
            exchangeNameLabel!.text = ""
        }
        
        if let labelText: String = company?.tickerSymbol {
            tickerSymbolLabel!.text = labelText
        } else {
            tickerSymbolLabel!.text = ""
        }
        
        // Test company attributes by outputting to console.
        if let totalRevenue: String = company?.totalRevenue {
            println("totalRevenue: \(totalRevenue)")
        }
        if let netIncome: String = company?.netIncome {
            println("netIncome: \(netIncome)")
        }
        if let grossProfit: String = company?.grossProfit {
            println("grossProfit: \(grossProfit)")
        }
        if let rAndD: String = company?.rAndD {
            println("rAndD: \(rAndD)")
        }
        if let sgAndA: String = company?.sgAndA {
            println("sgAndA: \(sgAndA)")
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
