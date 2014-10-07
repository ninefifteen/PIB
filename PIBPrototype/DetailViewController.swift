//
//  DetailViewController.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/2/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    // MARK: - Properties
    
    //let company: Company!

    @IBOutlet weak var stockNameLabel: UILabel!
    @IBOutlet weak var stockExchangeLabel: UILabel!
    @IBOutlet weak var stockTickerLabel: UILabel!
    
    var company: Company! {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        if let company: Company = self.company {
            if let label = self.stockNameLabel { label.text = company.name }
            if let label = self.stockExchangeLabel { label.text = company.exchange }
            if let label = self.stockTickerLabel { label.text = company.tickerSymbol }
        }
    }
}

