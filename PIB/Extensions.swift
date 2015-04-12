//
//  Extensions.swift
//  PIB
//
//  Created by Shawn Seals on 2/5/15.
//  Copyright (c) 2015 Scoutly. All rights reserved.
//

import Foundation
import UIKit


extension Double {
    
    func pibStandardStyleValueString() -> String {
        
        var modifiedValue = self
        var returnString = String()
        
        let formatter = NSNumberFormatter()
        formatter.usesSignificantDigits = true
        formatter.maximumSignificantDigits = 3
        formatter.minimumSignificantDigits = 3
        formatter.roundingMode = NSNumberFormatterRoundingMode.RoundHalfUp
        
        if abs(modifiedValue) >= 1000000000000.0 {
            modifiedValue /= 1000000000000.0
            returnString = formatter.stringFromNumber(modifiedValue)! + "T"
        } else if abs(modifiedValue) >= 1000000000.0 {
            modifiedValue /= 1000000000.0
            returnString = formatter.stringFromNumber(modifiedValue)! + "B"
        } else if abs(modifiedValue) >= 1000000.0 {
            modifiedValue /= 1000000.0
            returnString = formatter.stringFromNumber(modifiedValue)! + "M"
        } else if abs(modifiedValue) >= 1000.0 {
            modifiedValue /= 1000.0
            returnString = formatter.stringFromNumber(modifiedValue)! + "K"
        } else {
            returnString = formatter.stringFromNumber(modifiedValue)!
        }
        
        return returnString
    }
    
    func pibGraphYAxisStyleValueString() -> String {
        
        var modifiedValue = self
        var returnString = String()
        
        let formatter = NSNumberFormatter()
        formatter.usesSignificantDigits = true
        formatter.maximumSignificantDigits = 3
        formatter.minimumSignificantDigits = 3
        formatter.roundingMode = NSNumberFormatterRoundingMode.RoundHalfUp
        
        if abs(modifiedValue) >= 1000000000000.0 {
            modifiedValue /= 1000000000000.0
            returnString = formatter.stringFromNumber(modifiedValue)! + "T"
        } else if abs(modifiedValue) >= 1000000000.0 {
            modifiedValue /= 1000000000.0
            returnString = formatter.stringFromNumber(modifiedValue)! + "B"
        } else if abs(modifiedValue) >= 1000000.0 {
            modifiedValue /= 1000000.0
            returnString = formatter.stringFromNumber(modifiedValue)! + "M"
        } else if abs(modifiedValue) >= 1000.0 {
            modifiedValue /= 1000.0
            returnString = formatter.stringFromNumber(modifiedValue)! + "K"
        } else if abs(modifiedValue) == 0.0 {
            returnString = "0"
        } else {
            returnString = formatter.stringFromNumber(modifiedValue)!
        }
        
        return returnString
    }
    
    func pibPercentageStyleValueString() -> String {
        
        var modifiedValue = self
        var returnString = String()
        
        let formatter = NSNumberFormatter()
        formatter.usesSignificantDigits = true
        formatter.maximumSignificantDigits = 3
        formatter.minimumSignificantDigits = 3
        formatter.roundingMode = NSNumberFormatterRoundingMode.RoundHalfUp
        
        if abs(modifiedValue) >= 1000000000000.0 {
            modifiedValue /= 1000000000000.0
            returnString = formatter.stringFromNumber(modifiedValue)! + "T"
        } else if abs(modifiedValue) >= 1000000000.0 {
            modifiedValue /= 1000000000.0
            returnString = formatter.stringFromNumber(modifiedValue)! + "B"
        } else if abs(modifiedValue) >= 1000000.0 {
            modifiedValue /= 1000000.0
            returnString = formatter.stringFromNumber(modifiedValue)! + "M"
        } else if abs(modifiedValue) >= 1000.0 {
            modifiedValue /= 1000.0
            returnString = formatter.stringFromNumber(modifiedValue)! + "K"
        } else {
            returnString = formatter.stringFromNumber(modifiedValue)!
        }
        
        return returnString + "%"
    }
}


extension UITextView {
    
    func visibleRange() -> NSRange {
        let bounds: CGRect = self.bounds
        let start: UITextPosition = self.beginningOfDocument
        if let textRange: UITextRange = self.characterRangeAtPoint(CGPointMake(CGRectGetMaxX(bounds), CGRectGetMaxY(bounds))) {
            let end: UITextPosition = textRange.end
            return NSMakeRange(0, self.offsetFromPosition(start, toPosition: end))
        } else {
            return NSMakeRange(0, 0)
        }
    }
}


extension Company {
    
    func revenueLabelString() -> String {
        
        var totalRevenueArray = Array<FinancialMetric>()
        var financialMetrics = self.financialMetrics.allObjects as! [FinancialMetric]
        for (index, financialMetric) in enumerate(financialMetrics) {
            if financialMetric.type == "Total Revenue" {
                totalRevenueArray.append(financialMetric)
            }
        }
        
        totalRevenueArray.sort({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })
        
        if totalRevenueArray.count > 0 {
            return Double(totalRevenueArray.last!.value).pibStandardStyleValueString()
        } else {
            return "-"
        }
    }
}


extension UIImage {
    
    func imageByApplyingAlpha(alpha: CGFloat) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        let contextRef = UIGraphicsGetCurrentContext()
        let area = CGRectMake(0.0, 0.0, size.width, size.height)
        
        CGContextScaleCTM(contextRef, 1.0, -1.0)
        CGContextTranslateCTM(contextRef, 0.0, -area.size.height)
        
        CGContextSetBlendMode(contextRef, kCGBlendModeMultiply)
        
        CGContextSetAlpha(contextRef, alpha)
        
        CGContextDrawImage(contextRef, area, CGImage)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage
    }
}


extension UISplitViewController {
    
    func toggleMasterView() {
        let barButtonItem = self.displayModeButtonItem()
        UIApplication.sharedApplication().sendAction(barButtonItem.action, to: barButtonItem.target, from: nil, forEvent: nil)
    }
}











