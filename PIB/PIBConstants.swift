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

struct GoogleAnalytics {
    
    static let kTrackerId = "UA-35969227-1"
    static let kMasterScreenName = "Master"
    static let kDetailScreenName = "Detail"
    static let kExpandedDescriptionScreenName = "Expanded Description"
    static let kAddCompanyScreenName = "Add Company"
    static let kEventCategoryUserAction = "User Action"
    static let kEventActionAddCompany = "Add Company"
}
