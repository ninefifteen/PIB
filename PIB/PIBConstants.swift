//
//  PIBConstants.swift
//  PIB
//
//  Created by Shawn Seals on 12/22/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//


import Foundation


struct MainStoryboard {
    
    struct SegueIdentifiers {
        static let kAddCompany = "addCompany"
        static let kShowDetail = "showDetail"
        static let kShowExpandedDescription = "showExpandedDescription"
        static let kEmbedGraph = "embedGraph"
        static let kUnwindFromAddCompany = "unwindFromAddCompany"
    }
    
    struct TableViewCellIdentifiers {
        static let kMasterViewTableCell = "masterViewCell"
        static let kAddCompanyViewCompanyCell = "companyCell"
        static let kAddCompanyViewNoResultsCell = "noResultsCell"
    }
}


struct GraphContent {
    
    struct Axis {
        struct Y {
            static let kNumberOfIntervals: Double = 4.0
        }
    }
    
    struct Color {
        
        // Base CPTColors used in Graphs.
        private static let kRedColor = CPTColor(componentRed: 237.0/255.0, green: 68.0/255.0, blue: 4.0/255.0, alpha: 1.0)
        private static let kDarkGreenColor = CPTColor(componentRed: 23.0/255.0, green: 98.0/255.0, blue: 55.0/255.0, alpha: 1.0)
        private static let kTealColor = CPTColor(componentRed: 44.0/255.0, green: 146.0/255.0, blue: 172.0/255.0, alpha: 1.0)
        private static let kMagentaColor = CPTColor(componentRed: 233.0/255.0, green: 31.0/255.0, blue: 100.0/255.0, alpha: 1.0)
        
        static let kGridLineColor = CPTColor(componentRed: 200.0/255.0, green: 200.0/255.0, blue: 200.0/255.0, alpha: 1.0)
        
        static let kXAxisLabelColor = kDarkGreenColor
        static let kYAxisLabelColor = kRedColor
        
        static let kRevenuePlotColor = kTealColor
        static let kProfitMarginPlotColor = kMagentaColor
        static let kGrossMarginPlotColor = kMagentaColor
        static let kRAndDPlotColor = kTealColor
        static let kSgAndAPlotColor = kTealColor
        
        static let kPlotSymbolFillColor = CPTColor.whiteColor()
    }
    
    struct Font {
        
        struct Size {
            
            static let kXAxisLabelFontSize: CGFloat = 14.0
            static let kYAxisLabelFontSize: CGFloat = 14.0
            static let kLegendFontSize: CGFloat = 12.0
            static let kAnnotationFontSize: CGFloat = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? 18.0 : 13.0
            static let kTitleFontSize: CGFloat = 15.0
        }
    }
}


struct GoogleAnalytics {
    
    static let kTrackerId = "UA-35969227-1"
    static let kMasterScreenName = "Master"
    static let kDetailScreenName = "Detail"
    static let kExpandedDescriptionScreenName = "Expanded Description"
    static let kAddCompanyScreenName = "Add Company"
    static let kEventCategoryUserAction = "User Action"
    static let kEventActionAddCompany = "Add Company"
}
