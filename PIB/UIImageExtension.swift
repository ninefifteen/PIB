//
//  UIImageExtension.swift
//  PIB
//
//  Created by Shawn Seals on 1/28/15.
//  Copyright (c) 2015 Scoutly. All rights reserved.
//

import UIKit

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
