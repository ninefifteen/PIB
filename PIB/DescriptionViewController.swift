//
//  DescriptionViewController.swift
//  PIB
//
//  Created by Shawn Seals on 2/6/15.
//  Copyright (c) 2015 Scoutly. All rights reserved.
//

import UIKit

class DescriptionViewController: UIViewController, UITextViewDelegate {

    
    // MARK: - Properties
    
    @IBOutlet weak var descriptionView: UIView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var descriptionViewBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var descriptionTextViewBottomLayoutConstraint: NSLayoutConstraint!
    
    var descriptionTextViewOriginalFrame: CGRect!
    var descriptionViewBottomLayoutConstraintOriginalValue: CGFloat!
    
    var company: Company!
    
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //title = company.name
        
        descriptionTextView.delegate = self
        descriptionTextViewOriginalFrame = CGRectMake(descriptionTextView.frame.origin.x, descriptionTextView.frame.origin.y, descriptionTextView.frame.width, descriptionTextView.frame.height)
        
        descriptionViewBottomLayoutConstraintOriginalValue = descriptionViewBottomLayoutConstraint.constant
        
        descriptionView.layer.cornerRadius = 5.0
        descriptionView.layer.masksToBounds = true
        
        updateLabels()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        println("viewDidAppear descriptionTextView width: \(descriptionTextView.frame.width) height: \(descriptionTextView.frame.height)")
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
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        let textViewStartingHeight: CGFloat = descriptionTextView.frame.height
        let descriptionViewBottomConstraintStartingValue: CGFloat = descriptionViewBottomLayoutConstraint.constant
        let descriptionTextViewBottomConstraintStartingValue: CGFloat = descriptionTextViewBottomLayoutConstraint.constant
        
        let fixedWidth = descriptionTextView.frame.size.width
        let newSize = descriptionTextView.sizeThatFits(CGSizeMake(fixedWidth, CGFloat.max))
        var newFrame = descriptionTextView.frame
        newFrame.size = CGSizeMake(fmax(newSize.width, fixedWidth), newSize.height)
        let newTextViewHeight = newFrame.size.height
        //descriptionTextView.frame = newFrame
        
        let textViewHeightDelta = textViewStartingHeight - newFrame.size.height
        let newDescriptionViewBottomConstraintValue = descriptionViewBottomConstraintStartingValue + textViewHeightDelta
        let newDescriptionTextViewBottomConstraintValue = descriptionTextViewBottomConstraintStartingValue + textViewHeightDelta
        descriptionViewBottomLayoutConstraint.constant = newDescriptionViewBottomConstraintValue > 74.0 ? newDescriptionViewBottomConstraintValue : 74.0
        descriptionTextViewBottomLayoutConstraint.constant = newDescriptionTextViewBottomConstraintValue > 82.0 ? newDescriptionTextViewBottomConstraintValue : 82.0
    }
    
    
    // MARK: - Populate Labels
    
    func updateLabels() {
        
        if company != nil {
            companyNameLabel.text = company.name
            
            if company.city != "" {
                if company.country != "" && company.state != "" {
                    locationLabel.text = company.city.capitalizedString + ", " + company.state.uppercaseString + " " + company.country.capitalizedString
                } else if company.country != "" {
                    locationLabel.text = company.city.capitalizedString + " " + company.country.capitalizedString
                } else {
                    locationLabel.text = company.city.capitalizedString
                }
            } else {
                locationLabel.text = ""
            }
            
            descriptionTextView.text = company.companyDescription
        }
    }
    
    
    // MARK: - Text View Delegate
    
    func textViewDidChange(textView: UITextView) {
        
        println("textViewDidChange")
        
        let fixedWidth = descriptionTextView.frame.size.width
        let newSize = descriptionTextView.sizeThatFits(CGSizeMake(fixedWidth, CGFloat.max))
        var newFrame = descriptionTextView.frame
        newFrame.size = CGSizeMake(fmax(newSize.width, fixedWidth), newSize.height)
        descriptionTextView.frame = newFrame
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
