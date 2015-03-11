//
//  GraphContentViewController.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 11/1/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//

import UIKit


@objc protocol GraphContentViewControllerDelegate: class {
    optional func userSelectedGraphPointOfType(type: String, forDate date: String, withValue value: String)
}


class GraphContentViewController: UIViewController, CPTPlotDataSource, CPTBarPlotDelegate, CPTScatterPlotDelegate, CPTPlotAreaDelegate {

    
    // MARK: - Types
    
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
                static let kAnnotationSubFontSize: CGFloat = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? 13.0 : 11.0
                static let kTitleFontSize: CGFloat = 15.0
            }
        }
    }
    
    
    // MARK: - Properties
    
    weak var delegate: GraphContentViewControllerDelegate?
    
    @IBOutlet weak var graphView: CPTGraphHostingView!
    @IBOutlet weak var descriptionView: UIView!
    
    @IBOutlet weak var doubleTapGestureRecognizer: UITapGestureRecognizer!
    
    var company: Company!
    var managedObjectContext: NSManagedObjectContext!
    
    let graph = CPTXYGraph()
    var pageIndex: Int = 0
    var pageIdentifier: String = ""
    
    var totalRevenueArray = Array<FinancialMetric>()
    var peersTotalRevenueArray = Array<FinancialMetric>()
    var profitMarginArray = Array<FinancialMetric>()
    var peersProfitMarginArray = Array<FinancialMetric>()
    var revenueGrowthArray = Array<FinancialMetric>()
    var peersRevenueGrowthArray = Array<FinancialMetric>()
    var netIncomeGrowthArray = Array<FinancialMetric>()
    var peersNetIncomeGrowthArray = Array<FinancialMetric>()
    var grossProfitArray = Array<FinancialMetric>()
    var peersGrossProfitArray = Array<FinancialMetric>()
    var grossMarginArray = Array<FinancialMetric>()
    var peersGrossMarginArray = Array<FinancialMetric>()
    var rAndDArray = Array<FinancialMetric>()
    var peersRAndDArray = Array<FinancialMetric>()
    var sgAndAArray = Array<FinancialMetric>()
    var peersSgAndAArray = Array<FinancialMetric>()
    
    var numberOfDataPointPerPlot: Int = 0
    
    var yAxisMin: Double = 0.0
    var yAxisMax: Double = 0.0
    var yAxisInterval: Double = 0.0
    var yAxisRange: Double = 0.0
    var yAxisIntervals: Double = 0.0
    
    var y2AxisMin: Double = 0.0
    var y2AxisMax: Double = 0.0
    var y2AxisInterval: Double = 0.0
    var y2AxisRange: Double = 0.0
    var requiredMajorIntervalsBelowZero: Int = 0
    
    var xAxisLabels = Array<String>()
    var yAxisLabels = Array<String>()
    var y2AxisLabels = Array<String>()
    var plotSpace = CPTXYPlotSpace()
    var plotSpace2 = CPTXYPlotSpace()
    var plotSpaceLength: Double = 0.0
    var axisSet = CPTXYAxisSet()
    var x = CPTXYAxis()
    var y = CPTXYAxis()
    var y2 = CPTXYAxis()
    var xAxisCustomTickLocations = Array<Double>()
    var yAxisCustomTickLocations = Array<Double>()
    var y2AxisCustomTickLocations = Array<Double>()
    var yMajorGridLineStyle = CPTMutableLineStyle()
    var barLineStyle = CPTMutableLineStyle()
    
    let xAxisLabelTextStyle = CPTMutableTextStyle()
    let yAxisLabelTextStyle = CPTMutableTextStyle()
    let y2AxisLabelTextStyle = CPTMutableTextStyle()
    let legendTextStyle = CPTMutableTextStyle()
    let annotationTextStyle = CPTMutableTextStyle()
    let titleTextStyle = CPTMutableTextStyle()
    
    let graphLegendAnchor = CPTRectAnchor.Top
    let graphLegendDisplacement = CGPointMake(0.0, 0.0)
    
    var scatterPlotOffset: Double = 0.5
    let scatterPlotLineWidth: CGFloat = 3.5
    let scatterPlotSymbolSize = CGSizeMake(13.0, 13.0)
    let plotSymbolMarginForHitDetection: CGFloat = 30.0
    
    var plots = Array<CPTPlot>()
    
    var plotLabelState: Int = 0 // 0: All plots labeled, 1: First plot labeled, 2: Second plot labeled, 3: No plots labeled.
    
    let showYAxis: Bool = false
    
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        if pageIdentifier == "CompanyOverview" {
            
            doubleTapGestureRecognizer.enabled = false
            graphView.hidden = true
            
            let companyOverviewViewController = storyboard?.instantiateViewControllerWithIdentifier("CompanyOverviewViewController") as CompanyOverviewViewController
            companyOverviewViewController.company = company
            addChildViewController(companyOverviewViewController)
            companyOverviewViewController.view.frame = descriptionView.frame
            descriptionView.addSubview(companyOverviewViewController.view)
            //companyOverviewViewController.didMoveToParentViewController(self)
            
        } else {
            
            descriptionView.hidden = true
            
            yAxisIntervals = showYAxis ? 4.0 : 8.0
            
            configureTextStyles()
            
            switch pageIdentifier {
                
            case "Revenue":
                
                let entityDescription = NSEntityDescription.entityForName("FinancialMetric", inManagedObjectContext: managedObjectContext)
                let request = NSFetchRequest()
                request.entity = entityDescription
                
                let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
                request.sortDescriptors = [sortDescriptor]
                
                var error: NSError? = nil
                
                let totalRevenuePredicate = NSPredicate(format: "(company == %@) AND (type == 'Total Revenue')", company)
                request.predicate = totalRevenuePredicate
                totalRevenueArray = managedObjectContext.executeFetchRequest(request, error: &error) as [FinancialMetric]
                if error != nil {
                    println("Fetch request error: \(error?.description)")
                }
                
                peersTotalRevenueArray = correspondingPeersAverageArrayForTargetFinancialMetrics(totalRevenueArray)
                
                let profitMarginPredicate = NSPredicate(format: "(company == %@) AND (type == 'Profit Margin')", company)
                request.predicate = profitMarginPredicate
                profitMarginArray = managedObjectContext.executeFetchRequest(request, error: &error) as [FinancialMetric]
                if error != nil {
                    println("Fetch request error: \(error?.description)")
                }
                
                peersProfitMarginArray = correspondingPeersAverageArrayForTargetFinancialMetrics(profitMarginArray)
                
                let revenueGrowthPredicate = NSPredicate(format: "(company == %@) AND (type == 'Revenue Growth')", company)
                request.predicate = revenueGrowthPredicate
                revenueGrowthArray = managedObjectContext.executeFetchRequest(request, error: &error) as [FinancialMetric]
                if error != nil {
                    println("Fetch request error: \(error?.description)")
                }
                
                peersRevenueGrowthArray = correspondingPeersAverageArrayForTargetFinancialMetrics(revenueGrowthArray)
                
                numberOfDataPointPerPlot = totalRevenueArray.count
                
                var minPercentageValue = minimumValueInFinancialMetricArray(profitMarginArray + peersProfitMarginArray)
                var minValue = minimumValueInFinancialMetricArray(totalRevenueArray + peersTotalRevenueArray)
                var maxValue = maximumValueInFinancialMetricArray(totalRevenueArray + peersTotalRevenueArray)
                
                calculateRevenueChartYAndY2AxisForRevenueMaximumValue(maxValue, initialRevenueYAxisMinimum: 0.0, initialRevenueYAxisMaximum: maxValue, profitMarginMinimumPercentageValue: minPercentageValue)
                
                xAxisLabels = xAxisLabelsForFinancialMetrics(totalRevenueArray)
                
                configureRevenueIncomeMarginGraph()
                
            case "Growth":
                
                let entityDescription = NSEntityDescription.entityForName("FinancialMetric", inManagedObjectContext: managedObjectContext)
                let request = NSFetchRequest()
                request.entity = entityDescription
                
                let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
                request.sortDescriptors = [sortDescriptor]
                
                var error: NSError? = nil
                
                let revenueGrowthPredicate = NSPredicate(format: "(company == %@) AND (type == 'Revenue Growth')", company)
                request.predicate = revenueGrowthPredicate
                revenueGrowthArray = managedObjectContext.executeFetchRequest(request, error: &error) as [FinancialMetric]
                if error != nil {
                    println("Fetch request error: \(error?.description)")
                }
                
                peersRevenueGrowthArray = correspondingPeersAverageArrayForTargetFinancialMetrics(revenueGrowthArray)
                
                let profitMarginPredicate = NSPredicate(format: "(company == %@) AND (type == 'Profit Margin')", company)
                request.predicate = profitMarginPredicate
                profitMarginArray = managedObjectContext.executeFetchRequest(request, error: &error) as [FinancialMetric]
                if error != nil {
                    println("Fetch request error: \(error?.description)")
                }
                
                peersProfitMarginArray = correspondingPeersAverageArrayForTargetFinancialMetrics(profitMarginArray)
                
                if profitMarginArray.count > 0 { profitMarginArray.removeAtIndex(0) }
                
                numberOfDataPointPerPlot = revenueGrowthArray.count
                
                var minValue = minimumValueInFinancialMetricArray(revenueGrowthArray + peersRevenueGrowthArray + profitMarginArray + peersProfitMarginArray)
                var maxValue = maximumValueInFinancialMetricArray(revenueGrowthArray + peersRevenueGrowthArray + profitMarginArray + peersProfitMarginArray)
                
                let initialYAxisMinimum = minValue < 0.0 ? minValue : 0.0
                calculateYAxisMinMaxAndIntervalForDataMinimumValue(minValue, dataMaximumValue: maxValue, initialYAxisMinimum: initialYAxisMinimum, initialYAxisMaximum: maxValue)
                
                xAxisLabels = xAxisLabelsForFinancialMetrics(revenueGrowthArray)
                
                configureRevenueGrowthProfitMarginGraph()
                
            case "GrossMargin":
                
                let entityDescription = NSEntityDescription.entityForName("FinancialMetric", inManagedObjectContext: managedObjectContext)
                let request = NSFetchRequest()
                request.entity = entityDescription
                
                let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
                request.sortDescriptors = [sortDescriptor]
                
                var error: NSError? = nil
                
                let grossMarginPredicate = NSPredicate(format: "(company == %@) AND (type == 'Gross Margin')", company)
                request.predicate = grossMarginPredicate
                grossMarginArray = managedObjectContext.executeFetchRequest(request, error: &error) as [FinancialMetric]
                if error != nil {
                    println("Fetch request error: \(error?.description)")
                }
                
                peersGrossMarginArray = correspondingPeersAverageArrayForTargetFinancialMetrics(grossMarginArray)
                
                var minValue = minimumValueInFinancialMetricArray(grossMarginArray + peersGrossMarginArray)
                var maxValue = maximumValueInFinancialMetricArray(grossMarginArray + peersGrossMarginArray)
                
                numberOfDataPointPerPlot = grossMarginArray.count
                
                let initialYAxisMinimum = minValue < 0.0 ? minValue : 0.0
                calculateYAxisMinMaxAndIntervalForDataMinimumValue(minValue, dataMaximumValue: maxValue, initialYAxisMinimum: initialYAxisMinimum, initialYAxisMaximum: maxValue)
                
                xAxisLabels = xAxisLabelsForFinancialMetrics(grossMarginArray)
                
                configureGrossMarginGraph()
                
            case "SG&A":
                
                let entityDescription = NSEntityDescription.entityForName("FinancialMetric", inManagedObjectContext: managedObjectContext)
                let request = NSFetchRequest()
                request.entity = entityDescription
                
                let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
                request.sortDescriptors = [sortDescriptor]
                
                var error: NSError? = nil
                
                let sgAndAPredicate = NSPredicate(format: "(company == %@) AND (type == 'SG&A As Percent Of Revenue')", company)
                request.predicate = sgAndAPredicate
                sgAndAArray = managedObjectContext.executeFetchRequest(request, error: &error) as [FinancialMetric]
                if error != nil {
                    println("Fetch request error: \(error?.description)")
                }
                
                peersSgAndAArray = correspondingPeersAverageArrayForTargetFinancialMetrics(sgAndAArray)
                
                numberOfDataPointPerPlot = sgAndAArray.count
                
                var minValue = minimumValueInFinancialMetricArray(sgAndAArray + peersSgAndAArray)
                var maxValue = maximumValueInFinancialMetricArray(sgAndAArray + peersSgAndAArray)
                
                let initialYAxisMinimum = minValue < 0.0 ? minValue : 0.0
                calculateYAxisMinMaxAndIntervalForDataMinimumValue(minValue, dataMaximumValue: maxValue, initialYAxisMinimum: initialYAxisMinimum, initialYAxisMaximum: maxValue)
                
                xAxisLabels = xAxisLabelsForFinancialMetrics(sgAndAArray)
                
                configureSGAndAGraph()
                
            case "R&D":
                
                let entityDescription = NSEntityDescription.entityForName("FinancialMetric", inManagedObjectContext: managedObjectContext)
                let request = NSFetchRequest()
                request.entity = entityDescription
                
                let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
                request.sortDescriptors = [sortDescriptor]
                
                var error: NSError? = nil
                
                let rAndDPredicate = NSPredicate(format: "(company == %@) AND (type == 'R&D As Percent Of Revenue')", company)
                request.predicate = rAndDPredicate
                rAndDArray = managedObjectContext.executeFetchRequest(request, error: &error) as [FinancialMetric]
                if error != nil {
                    println("Fetch request error: \(error?.description)")
                }
                
                peersRAndDArray = correspondingPeersAverageArrayForTargetFinancialMetrics(rAndDArray)
                
                numberOfDataPointPerPlot = rAndDArray.count
                
                var minValue = minimumValueInFinancialMetricArray(rAndDArray + peersRAndDArray)
                var maxValue = maximumValueInFinancialMetricArray(rAndDArray + peersRAndDArray)
                
                let initialYAxisMinimum = minValue < 0.0 ? minValue : 0.0
                calculateYAxisMinMaxAndIntervalForDataMinimumValue(minValue, dataMaximumValue: maxValue, initialYAxisMinimum: initialYAxisMinimum, initialYAxisMaximum: maxValue)
                
                xAxisLabels = xAxisLabelsForFinancialMetrics(rAndDArray)
                
                configureRAndDGraph()
                
            default:
                break
            }
            
            plotLabelState = 0  // All plots labeled.
            addRemoveAnnotationsAllPlots()
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Graph Configure Methods
    
    func configureTextStyles() {
        
        xAxisLabelTextStyle.color = GraphContent.Color.kXAxisLabelColor
        xAxisLabelTextStyle.fontSize = GraphContent.Font.Size.kXAxisLabelFontSize
        
        yAxisLabelTextStyle.color = GraphContent.Color.kYAxisLabelColor
        yAxisLabelTextStyle.fontSize = GraphContent.Font.Size.kYAxisLabelFontSize
        
        y2AxisLabelTextStyle.color = GraphContent.Color.kYAxisLabelColor
        y2AxisLabelTextStyle.fontSize = GraphContent.Font.Size.kYAxisLabelFontSize
        y2AxisLabelTextStyle.textAlignment = CPTTextAlignment.Left
        
        legendTextStyle.color = CPTColor.darkGrayColor()
        legendTextStyle.fontSize = GraphContent.Font.Size.kLegendFontSize
        
        annotationTextStyle.color = CPTColor.grayColor()
        annotationTextStyle.fontSize = GraphContent.Font.Size.kAnnotationFontSize
        annotationTextStyle.textAlignment = CPTTextAlignment.Center
        
        titleTextStyle.fontName = "Helvetica-Bold"
        titleTextStyle.color = GraphContent.Color.kYAxisLabelColor
        titleTextStyle.fontSize = GraphContent.Font.Size.kTitleFontSize
    }
    
    func legendForGraph() -> CPTLegend {
        
        let legend = CPTLegend(graph: graph)
        legend.fill = CPTFill(color: CPTColor.whiteColor())
        legend.borderLineStyle = nil
        legend.cornerRadius = 10.0
        legend.swatchSize = CGSizeMake(14.0, 14.0)
        legend.textStyle = legendTextStyle
        legend.rowMargin = 10.0
        legend.numberOfRows = 1
        legend.paddingLeft = 4.0
        legend.paddingTop = 4.0
        legend.paddingRight = 4.0
        legend.paddingBottom = 4.0
        
        return legend
    }
    
    func configureTitleForGraph(title: String) {
        
        graph.title = title.uppercaseString
        graph.titleTextStyle = titleTextStyle
        graph.titleDisplacement = CGPointMake(5.0, 0.0)
        graph.titlePlotAreaFrameAnchor = CPTRectAnchor.TopLeft
    }
    
    func configureBaseGraph() {
        
        graph.applyTheme(CPTTheme(named: kCPTPlainWhiteTheme))
        graph.plotAreaFrame.plotArea.delegate = self
        
        // Graph border.
        graph.plotAreaFrame.borderLineStyle = nil
        graph.plotAreaFrame.cornerRadius = 0.0
        graph.plotAreaFrame.masksToBorder = false
        
        // Graph paddings.
        graph.paddingLeft = 0.0
        graph.paddingRight = 0.0
        graph.paddingTop = 5.0
        graph.paddingBottom = 0.0
        
        if showYAxis {
            if pageIdentifier == "Revenue" {
                graph.plotAreaFrame.paddingLeft = 54.0
            } else {
                if yAxisMin <= -1000.0 {
                    graph.plotAreaFrame.paddingLeft = 70.0
                } else if yAxisMax >= 1000.0 {
                    graph.plotAreaFrame.paddingLeft = 64.0
                } else {
                    graph.plotAreaFrame.paddingLeft = 54.0
                }
            }
        } else {
            graph.plotAreaFrame.paddingLeft = 10.0
        }
        graph.plotAreaFrame.paddingTop = 34.0
        graph.plotAreaFrame.paddingRight = 10.0
        graph.plotAreaFrame.paddingBottom = 64.0
    }
    
    func configureBaseBarGraph() {
        
        configureBaseGraph()
        
        // Plot space.
        plotSpace = graph.defaultPlotSpace as CPTXYPlotSpace
        plotSpace.yRange = CPTPlotRange(location: yAxisMin, length: yAxisRange)
        plotSpace.xRange = CPTPlotRange(location: 0.0, length: plotSpaceLength)
        
        axisSet = graph.axisSet as CPTXYAxisSet
        
        x = axisSet.xAxis
        x.axisLineStyle = nil
        x.majorTickLineStyle = nil
        x.minorTickLineStyle = nil
        x.majorIntervalLength = 1.0
        x.orthogonalPosition = yAxisMin
        //x.title = "X Axis"
        //x.titleLocation = 1.5
        //x.titleOffset = 35
        
        // Custom X-axis labels.
        x.labelingPolicy = .None
        x.labelTextStyle = xAxisLabelTextStyle
        
        var xLabelLocation = 0
        let xAxisCustomLabels = NSMutableSet(capacity: xAxisLabels.count)
        for tickLocation in xAxisCustomTickLocations {
            let newLabel = CPTAxisLabel(text: xAxisLabels[xLabelLocation++], textStyle: x.labelTextStyle)
            newLabel.tickLocation = tickLocation
            newLabel.offset = x.labelOffset + x.majorTickLength
            //newLabel.rotation = CGFloat(M_PI_4)
            xAxisCustomLabels.addObject(newLabel)
        }
        
        x.axisLabels = xAxisCustomLabels
        
        // Create y-axis custom tick locations.
        for index in 0...Int(yAxisIntervals) {
            let tickLocation: Double = yAxisMin + (Double(index) * yAxisInterval)
            yAxisCustomTickLocations.append(tickLocation)
        }
        
        // Create y-axis major tick line style.
        yMajorGridLineStyle.lineWidth = 1.0
        yMajorGridLineStyle.lineColor = GraphContent.Color.kGridLineColor
        yMajorGridLineStyle.dashPattern = [2.0, 2.0]
        
        y = axisSet.yAxis
        y.axisLineStyle = nil
        y.majorTickLineStyle = nil
        y.minorTickLineStyle = nil
        y.majorTickLocations = NSSet(array: yAxisCustomTickLocations)
        y.majorGridLineStyle = yMajorGridLineStyle
        y.majorIntervalLength = yAxisInterval
        y.orthogonalPosition = 0.0
        //y.title = "Y Axis"
        //y.titleOffset = 45.0
        //y.titleLocation = yAxisMin + yAxisRange / 2.0
        y.labelingPolicy = .None
        y.labelTextStyle = yAxisLabelTextStyle
        
        // Custom Y Axis Labels
        if showYAxis {
            for (index, value) in enumerate(yAxisCustomTickLocations) {
                var label = Double(value).pibGraphYAxisStyleValueString()
                yAxisLabels.append(label)
            }
            
            var yLabelLocation = 0
            let yAxisCustomLabels = NSMutableSet(capacity: yAxisLabels.count)
            for tickLocation in yAxisCustomTickLocations {
                let newLabel = CPTAxisLabel(text: yAxisLabels[yLabelLocation++], textStyle: y.labelTextStyle)
                newLabel.tickLocation = tickLocation
                newLabel.offset = y.labelOffset + y.majorTickLength - 6.0
                yAxisCustomLabels.addObject(newLabel)
            }
            
            y.axisLabels = yAxisCustomLabels
        }
        
        // Create bar line style.
        barLineStyle.lineWidth = 1.0
        barLineStyle.lineColor = CPTColor.blackColor()
    }
    
    func configureBaseCurvedLineGraph() {
        
        configureBaseGraph()
        
        // Plot space.
        plotSpace = graph.defaultPlotSpace as CPTXYPlotSpace
        plotSpace.yRange = CPTPlotRange(location: yAxisMin, length: yAxisRange)
        plotSpace.xRange = CPTPlotRange(location: 0.0, length: plotSpaceLength)
        
        axisSet = graph.axisSet as CPTXYAxisSet
        
        x = axisSet.xAxis
        x.axisLineStyle = nil
        x.majorTickLineStyle = nil
        x.minorTickLineStyle = nil
        x.majorIntervalLength = 1.0
        x.orthogonalPosition = yAxisMin
        //x.title = "X Axis"
        //x.titleLocation = 1.5
        //x.titleOffset = 35
        
        // Custom X-axis labels.
        x.labelingPolicy = .None
        x.labelTextStyle = xAxisLabelTextStyle
        
        var xLabelLocation = 0
        let xAxisCustomLabels = NSMutableSet(capacity: xAxisLabels.count)
        for tickLocation in xAxisCustomTickLocations {
            let newLabel = CPTAxisLabel(text: xAxisLabels[xLabelLocation++], textStyle: x.labelTextStyle)
            newLabel.tickLocation = tickLocation
            newLabel.offset = x.labelOffset + x.majorTickLength
            //newLabel.rotation = CGFloat(M_PI_4)
            xAxisCustomLabels.addObject(newLabel)
        }
        
        x.axisLabels = xAxisCustomLabels
        
        // Create y-axis custom tick locations.
        for index in 0...Int(yAxisIntervals) {
            let tickLocation: Double = yAxisMin + (Double(index) * yAxisInterval)
            yAxisCustomTickLocations.append(tickLocation)
        }
        
        // Create y-axis major tick line style.
        yMajorGridLineStyle.lineWidth = 1.0
        yMajorGridLineStyle.lineColor = GraphContent.Color.kGridLineColor
        yMajorGridLineStyle.dashPattern = [2.0, 2.0]
        
        y = axisSet.yAxis
        y.axisLineStyle = nil
        y.majorTickLineStyle = nil
        y.minorTickLineStyle = nil
        y.majorTickLocations = NSSet(array: yAxisCustomTickLocations)
        y.majorGridLineStyle = yMajorGridLineStyle
        y.majorIntervalLength = yAxisInterval
        y.orthogonalPosition = 0.0
        //y.title = "Y Axis"
        //y.titleOffset = 45.0
        //y.titleLocation = yAxisMin + yAxisRange / 2.0
        y.labelingPolicy = .None
        y.labelTextStyle = yAxisLabelTextStyle
        
        // Custom Y Axis Labels
        if showYAxis {
            for (index, value) in enumerate(yAxisCustomTickLocations) {
                var label = Double(value).pibGraphYAxisStyleValueString() + "%"
                yAxisLabels.append(label)
            }
            
            var yLabelLocation = 0
            let yAxisCustomLabels = NSMutableSet(capacity: yAxisLabels.count)
            for tickLocation in yAxisCustomTickLocations {
                let newLabel = CPTAxisLabel(text: yAxisLabels[yLabelLocation++], textStyle: y.labelTextStyle)
                newLabel.tickLocation = tickLocation
                newLabel.offset = y.labelOffset + y.majorTickLength - 6.0
                yAxisCustomLabels.addObject(newLabel)
            }
            
            y.axisLabels = yAxisCustomLabels
        }
    }
    
    func configureRevenueIncomeMarginGraph() {
        
        configureBaseBarGraph()
        //let graphTitle = "Revenue (" + company.currencyCode + ")"
        //configureTitleForGraph(graphTitle)
        
        let isDataForProfitMarginPlot: Bool = minimumValueInFinancialMetricArray(profitMarginArray) != 0.0 || maximumValueInFinancialMetricArray(profitMarginArray) != 0.0
        let isDataForPeersProfitMarginPlot: Bool = minimumValueInFinancialMetricArray(peersProfitMarginArray) != 0.0 || maximumValueInFinancialMetricArray(peersProfitMarginArray) != 0.0
        let isDataForPeersTotalRevenuePlot: Bool = minimumValueInFinancialMetricArray(peersTotalRevenueArray) != 0.0 || maximumValueInFinancialMetricArray(peersTotalRevenueArray) != 0.0
        
        if isDataForProfitMarginPlot {
            
            // Change right padding for 2nd Y Axis labels.
            if showYAxis { graph.plotAreaFrame.paddingRight = 46.0 }
            
            // Add 2nd plot space to graph for scatter plot.
            plotSpace2 = CPTXYPlotSpace()
            graph.addPlotSpace(plotSpace2)
            plotSpace2.yRange = CPTPlotRange(location: y2AxisMin, length: y2AxisRange)
            plotSpace2.xRange = CPTPlotRange(location: 0.0, length: plotSpaceLength)
            
            // Configure 2nd Y Axis for scatter plot.
            y2.coordinate = CPTCoordinate.Y
            y2.plotSpace = plotSpace2
            y2.axisLineStyle = nil
            y2.majorTickLineStyle = nil
            y2.minorTickLineStyle = nil
            y2.majorTickLocations = NSSet(array: y2AxisCustomTickLocations)
            y2.majorGridLineStyle = nil
            y2.majorIntervalLength = y2AxisInterval
            y2.orthogonalPosition = plotSpaceLength
            y2.labelingPolicy = .None
            y2.labelTextStyle = y2AxisLabelTextStyle
            y2.tickDirection = CPTSign.Positive
            
            // Custom Labels for 2nd Y Axis.
            if showYAxis {
                for (index, value) in enumerate(y2AxisCustomTickLocations) {
                    var label: String = NSString(format: "%.0f", y2AxisCustomTickLocations[index]) + "%"
                    y2AxisLabels.append(label)
                }
                
                var y2LabelLocation = 0
                let y2AxisCustomLabels = NSMutableSet(capacity: y2AxisLabels.count)
                for tickLocation in y2AxisCustomTickLocations {
                    let newLabel = CPTAxisLabel(text: y2AxisLabels[y2LabelLocation++], textStyle: y2.labelTextStyle)
                    newLabel.tickLocation = tickLocation
                    newLabel.offset = y2.labelOffset + y2.majorTickLength - 6.0
                    newLabel.alignment = CPTAlignment.Left
                    y2AxisCustomLabels.addObject(newLabel)
                }
                y2.axisLabels = y2AxisCustomLabels
            }
            
            graph.axisSet.axes = [x, y2, y]
            
        } else {
            
            graph.axisSet.axes = [x, y]
        }
        
        // First bar plot.
        let revenueBarPlot = CPTBarPlot()
        revenueBarPlot.barsAreHorizontal = false
        revenueBarPlot.lineStyle = nil
        revenueBarPlot.fill = CPTFill(color: GraphContent.Color.kRevenuePlotColor)
        revenueBarPlot.barWidth = 0.30
        revenueBarPlot.baseValue = 0.0
        revenueBarPlot.barOffset = 0.25
        revenueBarPlot.barCornerRadius = 2.0
        let revenueBarPlotIdentifier = "Revenue (" + company.currencyCode + ")"
        revenueBarPlot.identifier = revenueBarPlotIdentifier
        revenueBarPlot.delegate = self
        revenueBarPlot.dataSource = self
        graph.addPlot(revenueBarPlot, toPlotSpace:plotSpace)
        plots.append(revenueBarPlot)
        
        if isDataForPeersTotalRevenuePlot {
            
            println("isDataForPeersTotalRevenuePlot")
            let peersRevenueBarPlot = CPTBarPlot()
            peersRevenueBarPlot.barsAreHorizontal = false
            peersRevenueBarPlot.lineStyle = nil
            peersRevenueBarPlot.fill = CPTFill(color: CPTColor.greenColor())
            peersRevenueBarPlot.barWidth = 0.30
            peersRevenueBarPlot.baseValue = 0.0
            peersRevenueBarPlot.barOffset = 0.75
            peersRevenueBarPlot.barCornerRadius = 2.0
            let peersRevenueBarPlotIdentifier = "Peers Revenue (" + company.currencyCode + ")"
            peersRevenueBarPlot.identifier = peersRevenueBarPlotIdentifier
            peersRevenueBarPlot.delegate = self
            peersRevenueBarPlot.dataSource = self
            graph.addPlot(peersRevenueBarPlot, toPlotSpace:plotSpace)
            plots.append(peersRevenueBarPlot)
        }
        
        if isDataForProfitMarginPlot {
            
            // Profit Margin line plot.
            let profitMarginPlotColor = GraphContent.Color.kProfitMarginPlotColor
            
            let profitMarginPlotLineStyle = CPTMutableLineStyle()
            profitMarginPlotLineStyle.lineWidth = scatterPlotLineWidth
            profitMarginPlotLineStyle.lineColor = profitMarginPlotColor
            
            let profitMarginLinePlot = CPTScatterPlot()
            profitMarginLinePlot.delegate = self
            profitMarginLinePlot.dataSource = self
            profitMarginLinePlot.interpolation = CPTScatterPlotInterpolation.Curved
            profitMarginLinePlot.dataLineStyle = profitMarginPlotLineStyle
            profitMarginLinePlot.plotSymbolMarginForHitDetection = plotSymbolMarginForHitDetection
            profitMarginLinePlot.identifier = "Profit Margin"
            
            let symbolLineStyle = CPTMutableLineStyle()
            symbolLineStyle.lineColor = profitMarginPlotColor
            symbolLineStyle.lineWidth = scatterPlotLineWidth
            let plotSymbol = CPTPlotSymbol.ellipsePlotSymbol()
            //plotSymbol.fill = CPTFill(color: profitMarginPlotColor)
            plotSymbol.fill = CPTFill(color: GraphContent.Color.kPlotSymbolFillColor)
            plotSymbol.lineStyle = symbolLineStyle
            plotSymbol.size = scatterPlotSymbolSize
            profitMarginLinePlot.plotSymbol = plotSymbol
            
            graph.addPlot(profitMarginLinePlot, toPlotSpace:plotSpace2)
            plots.append(profitMarginLinePlot)
            
            if isDataForPeersProfitMarginPlot {
                
                // Peers Profit Margin line plot.
                let peersProfitMarginPlotColor = CPTColor.orangeColor()
                
                let peersProfitMarginPlotLineStyle = CPTMutableLineStyle()
                peersProfitMarginPlotLineStyle.lineWidth = scatterPlotLineWidth
                peersProfitMarginPlotLineStyle.lineColor = peersProfitMarginPlotColor
                
                let peersProfitMarginLinePlot = CPTScatterPlot()
                peersProfitMarginLinePlot.delegate = self
                peersProfitMarginLinePlot.dataSource = self
                peersProfitMarginLinePlot.interpolation = CPTScatterPlotInterpolation.Curved
                peersProfitMarginLinePlot.dataLineStyle = peersProfitMarginPlotLineStyle
                peersProfitMarginLinePlot.plotSymbolMarginForHitDetection = plotSymbolMarginForHitDetection
                peersProfitMarginLinePlot.identifier = "Peers Profit Margin"
                
                let peersSymbolLineStyle = CPTMutableLineStyle()
                peersSymbolLineStyle.lineColor = peersProfitMarginPlotColor
                peersSymbolLineStyle.lineWidth = scatterPlotLineWidth
                let peersPlotSymbol = CPTPlotSymbol.ellipsePlotSymbol()
                //peersPlotSymbol.fill = CPTFill(color: profitMarginPlotColor)
                peersPlotSymbol.fill = CPTFill(color: GraphContent.Color.kPlotSymbolFillColor)
                peersPlotSymbol.lineStyle = peersSymbolLineStyle
                peersPlotSymbol.size = scatterPlotSymbolSize
                peersProfitMarginLinePlot.plotSymbol = peersPlotSymbol
                
                graph.addPlot(peersProfitMarginLinePlot, toPlotSpace:plotSpace2)
                plots.append(peersProfitMarginLinePlot)
            }
        }
        
        // Add legend.
        graph.legend = legendForGraph()
        graph.legendAnchor = graphLegendAnchor
        graph.legendDisplacement = graphLegendDisplacement
        
        self.graphView.hostedGraph = graph
    }
    
    func configureRevenueGrowthProfitMarginGraph() {
        
        configureBaseCurvedLineGraph()
        //configureTitleForGraph("Growth Dynamics")
        
        let isDataForRevenueGrowthPlot: Bool = minimumValueInFinancialMetricArray(revenueGrowthArray) != 0.0 || maximumValueInFinancialMetricArray(revenueGrowthArray) != 0.0
        let isDataForProfitMarginPlot: Bool = minimumValueInFinancialMetricArray(profitMarginArray) != 0.0 || maximumValueInFinancialMetricArray(profitMarginArray) != 0.0
        
        if isDataForRevenueGrowthPlot {
            
            let revenueGrowthPlotColor = GraphContent.Color.kRevenuePlotColor
            
            let revenueGrowthPlotLineStyle = CPTMutableLineStyle()
            revenueGrowthPlotLineStyle.lineWidth = scatterPlotLineWidth
            revenueGrowthPlotLineStyle.lineColor = revenueGrowthPlotColor
            
            let revenueGrowthPlot = CPTScatterPlot()
            revenueGrowthPlot.delegate = self
            revenueGrowthPlot.dataSource = self
            revenueGrowthPlot.interpolation = CPTScatterPlotInterpolation.Curved
            revenueGrowthPlot.dataLineStyle = revenueGrowthPlotLineStyle
            revenueGrowthPlot.plotSymbolMarginForHitDetection = plotSymbolMarginForHitDetection
            revenueGrowthPlot.identifier = "Revenue Growth"
            
            let revenueGrowthSymbolLineStyle = CPTMutableLineStyle()
            revenueGrowthSymbolLineStyle.lineColor = revenueGrowthPlotColor
            revenueGrowthSymbolLineStyle.lineWidth = scatterPlotLineWidth
            let revenueGrowthPlotSymbol = CPTPlotSymbol.ellipsePlotSymbol()
            revenueGrowthPlotSymbol.fill = CPTFill(color: GraphContent.Color.kPlotSymbolFillColor)
            revenueGrowthPlotSymbol.lineStyle = revenueGrowthSymbolLineStyle
            revenueGrowthPlotSymbol.size = scatterPlotSymbolSize
            revenueGrowthPlot.plotSymbol = revenueGrowthPlotSymbol
            
            graph.addPlot(revenueGrowthPlot, toPlotSpace:plotSpace)
            plots.append(revenueGrowthPlot)
        }
        
        if isDataForProfitMarginPlot {
            
            let profitMarginPlotColor = GraphContent.Color.kProfitMarginPlotColor
            
            let profitMarginPlotLineStyle = CPTMutableLineStyle()
            profitMarginPlotLineStyle.lineWidth = scatterPlotLineWidth
            profitMarginPlotLineStyle.lineColor = profitMarginPlotColor
            
            let profitMarginPlot = CPTScatterPlot()
            profitMarginPlot.delegate = self
            profitMarginPlot.dataSource = self
            profitMarginPlot.interpolation = CPTScatterPlotInterpolation.Curved
            profitMarginPlot.dataLineStyle = profitMarginPlotLineStyle
            profitMarginPlot.plotSymbolMarginForHitDetection = plotSymbolMarginForHitDetection
            profitMarginPlot.identifier = "Profit Margin"
            
            let profitMarginSymbolLineStyle = CPTMutableLineStyle()
            profitMarginSymbolLineStyle.lineColor = profitMarginPlotColor
            profitMarginSymbolLineStyle.lineWidth = scatterPlotLineWidth
            let profitMarginPlotSymbol = CPTPlotSymbol.ellipsePlotSymbol()
            profitMarginPlotSymbol.fill = CPTFill(color: GraphContent.Color.kPlotSymbolFillColor)
            profitMarginPlotSymbol.lineStyle = profitMarginSymbolLineStyle
            profitMarginPlotSymbol.size = scatterPlotSymbolSize
            profitMarginPlot.plotSymbol = profitMarginPlotSymbol
            
            graph.addPlot(profitMarginPlot, toPlotSpace:plotSpace)
            plots.append(profitMarginPlot)
        }
        
        // Add legend.
        graph.legend = legendForGraph()
        graph.legendAnchor = graphLegendAnchor
        graph.legendDisplacement = graphLegendDisplacement
        
        self.graphView.hostedGraph = graph
    }
    
    func configureGrossMarginGraph() {
        
        configureBaseCurvedLineGraph()
        //configureTitleForGraph("Gross Margin")
        
        let isDataForPeersGrossMarginPlot: Bool = minimumValueInFinancialMetricArray(peersGrossMarginArray) != 0.0 || maximumValueInFinancialMetricArray(peersGrossMarginArray) != 0.0
        
        let grossMarginPlotColor = GraphContent.Color.kGrossMarginPlotColor
        
        let grossMarginPlotLineStyle = CPTMutableLineStyle()
        grossMarginPlotLineStyle.lineWidth = scatterPlotLineWidth
        grossMarginPlotLineStyle.lineColor = grossMarginPlotColor
        
        let grossMarginPlot = CPTScatterPlot()
        grossMarginPlot.delegate = self
        grossMarginPlot.dataSource = self
        grossMarginPlot.interpolation = CPTScatterPlotInterpolation.Curved
        grossMarginPlot.dataLineStyle = grossMarginPlotLineStyle
        grossMarginPlot.plotSymbolMarginForHitDetection = plotSymbolMarginForHitDetection
        grossMarginPlot.identifier = "Gross Margin"
        
        let symbolLineStyle = CPTMutableLineStyle()
        symbolLineStyle.lineColor = grossMarginPlotColor
        symbolLineStyle.lineWidth = scatterPlotLineWidth
        let grossMarginPlotSymbol = CPTPlotSymbol.ellipsePlotSymbol()
        grossMarginPlotSymbol.fill = CPTFill(color: GraphContent.Color.kPlotSymbolFillColor)
        grossMarginPlotSymbol.lineStyle = symbolLineStyle
        grossMarginPlotSymbol.size = scatterPlotSymbolSize
        grossMarginPlot.plotSymbol = grossMarginPlotSymbol
        
        graph.addPlot(grossMarginPlot, toPlotSpace:plotSpace)
        plots.append(grossMarginPlot)
        
        if isDataForPeersGrossMarginPlot {
            
            let peersGrossMarginPlotColor = CPTColor.orangeColor()
            
            let peersGrossMarginPlotLineStyle = CPTMutableLineStyle()
            peersGrossMarginPlotLineStyle.lineWidth = scatterPlotLineWidth
            peersGrossMarginPlotLineStyle.lineColor = peersGrossMarginPlotColor
            
            let peersGrossMarginPlot = CPTScatterPlot()
            peersGrossMarginPlot.delegate = self
            peersGrossMarginPlot.dataSource = self
            peersGrossMarginPlot.interpolation = CPTScatterPlotInterpolation.Curved
            peersGrossMarginPlot.dataLineStyle = peersGrossMarginPlotLineStyle
            peersGrossMarginPlot.plotSymbolMarginForHitDetection = plotSymbolMarginForHitDetection
            peersGrossMarginPlot.identifier = "Peers Gross Margin"
            
            let symbolLineStyle = CPTMutableLineStyle()
            symbolLineStyle.lineColor = peersGrossMarginPlotColor
            symbolLineStyle.lineWidth = scatterPlotLineWidth
            let peersGrossMarginPlotSymbol = CPTPlotSymbol.ellipsePlotSymbol()
            peersGrossMarginPlotSymbol.fill = CPTFill(color: GraphContent.Color.kPlotSymbolFillColor)
            peersGrossMarginPlotSymbol.lineStyle = symbolLineStyle
            peersGrossMarginPlotSymbol.size = scatterPlotSymbolSize
            peersGrossMarginPlot.plotSymbol = peersGrossMarginPlotSymbol
            
            graph.addPlot(peersGrossMarginPlot, toPlotSpace:plotSpace)
            plots.append(peersGrossMarginPlot)
        }
        
        // Add legend.
        graph.legend = legendForGraph()
        graph.legendAnchor = graphLegendAnchor
        graph.legendDisplacement = graphLegendDisplacement
        
        self.graphView.hostedGraph = graph
    }
    
    func configureRAndDGraph() {
        
        configureBaseCurvedLineGraph()
        //configureTitleForGraph("R & D")
        
        let isDataForPeersRAndDLinePlot: Bool = minimumValueInFinancialMetricArray(peersRAndDArray) != 0.0 || maximumValueInFinancialMetricArray(peersRAndDArray) != 0.0
        
        let rAndDLinePlotColor = GraphContent.Color.kRAndDPlotColor
        
        let rAndDLinePlotLineStyle = CPTMutableLineStyle()
        rAndDLinePlotLineStyle.lineWidth = scatterPlotLineWidth
        rAndDLinePlotLineStyle.lineColor = rAndDLinePlotColor
        
        let rAndDLinePlot = CPTScatterPlot()
        rAndDLinePlot.delegate = self
        rAndDLinePlot.dataSource = self
        rAndDLinePlot.interpolation = CPTScatterPlotInterpolation.Curved
        rAndDLinePlot.dataLineStyle = rAndDLinePlotLineStyle
        rAndDLinePlot.plotSymbolMarginForHitDetection = plotSymbolMarginForHitDetection
        rAndDLinePlot.identifier = "R&D"
        
        let symbolLineStyle = CPTMutableLineStyle()
        symbolLineStyle.lineColor = rAndDLinePlotColor
        symbolLineStyle.lineWidth = scatterPlotLineWidth
        let plotSymbol = CPTPlotSymbol.ellipsePlotSymbol()
        plotSymbol.fill = CPTFill(color: GraphContent.Color.kPlotSymbolFillColor)
        plotSymbol.lineStyle = symbolLineStyle
        plotSymbol.size = scatterPlotSymbolSize
        rAndDLinePlot.plotSymbol = plotSymbol
        
        graph.addPlot(rAndDLinePlot, toPlotSpace:plotSpace)
        plots.append(rAndDLinePlot)
        
        if isDataForPeersRAndDLinePlot {
            
            let peersRAndDLinePlotColor = CPTColor.greenColor()
            
            let peersRAndDLinePlotLineStyle = CPTMutableLineStyle()
            peersRAndDLinePlotLineStyle.lineWidth = scatterPlotLineWidth
            peersRAndDLinePlotLineStyle.lineColor = peersRAndDLinePlotColor
            
            let peersRAndDLinePlot = CPTScatterPlot()
            peersRAndDLinePlot.delegate = self
            peersRAndDLinePlot.dataSource = self
            peersRAndDLinePlot.interpolation = CPTScatterPlotInterpolation.Curved
            peersRAndDLinePlot.dataLineStyle = peersRAndDLinePlotLineStyle
            peersRAndDLinePlot.plotSymbolMarginForHitDetection = plotSymbolMarginForHitDetection
            peersRAndDLinePlot.identifier = "Peers R&D"
            
            let symbolLineStyle = CPTMutableLineStyle()
            symbolLineStyle.lineColor = peersRAndDLinePlotColor
            symbolLineStyle.lineWidth = scatterPlotLineWidth
            let peersRAndDLinePlotSymbol = CPTPlotSymbol.ellipsePlotSymbol()
            peersRAndDLinePlotSymbol.fill = CPTFill(color: GraphContent.Color.kPlotSymbolFillColor)
            peersRAndDLinePlotSymbol.lineStyle = symbolLineStyle
            peersRAndDLinePlotSymbol.size = scatterPlotSymbolSize
            peersRAndDLinePlot.plotSymbol = peersRAndDLinePlotSymbol
            
            graph.addPlot(peersRAndDLinePlot, toPlotSpace:plotSpace)
            plots.append(peersRAndDLinePlot)
        }
        
        // Add legend.
        graph.legend = legendForGraph()
        graph.legendAnchor = graphLegendAnchor
        graph.legendDisplacement = graphLegendDisplacement
        
        self.graphView.hostedGraph = graph
    }
    
    func configureSGAndAGraph() {
        
        configureBaseCurvedLineGraph()
        //configureTitleForGraph("SG & A")
        
        let isDataForPeersSgAndALinePlot: Bool = minimumValueInFinancialMetricArray(peersSgAndAArray) != 0.0 || maximumValueInFinancialMetricArray(peersSgAndAArray) != 0.0
        
        let sgAndAPlotColor = GraphContent.Color.kSgAndAPlotColor
        
        let sgAndAPlotLineStyle = CPTMutableLineStyle()
        sgAndAPlotLineStyle.lineWidth = scatterPlotLineWidth
        sgAndAPlotLineStyle.lineColor = sgAndAPlotColor
        
        let sgAndAPlot = CPTScatterPlot()
        sgAndAPlot.delegate = self
        sgAndAPlot.dataSource = self
        sgAndAPlot.interpolation = CPTScatterPlotInterpolation.Curved
        sgAndAPlot.dataLineStyle = sgAndAPlotLineStyle
        sgAndAPlot.plotSymbolMarginForHitDetection = plotSymbolMarginForHitDetection
        sgAndAPlot.identifier = "SG&A"
        
        let symbolLineStyle = CPTMutableLineStyle()
        symbolLineStyle.lineColor = sgAndAPlotColor
        symbolLineStyle.lineWidth = scatterPlotLineWidth
        let sgAndAPlotSymbol = CPTPlotSymbol.ellipsePlotSymbol()
        sgAndAPlotSymbol.fill = CPTFill(color: GraphContent.Color.kPlotSymbolFillColor)
        sgAndAPlotSymbol.lineStyle = symbolLineStyle
        sgAndAPlotSymbol.size = scatterPlotSymbolSize
        sgAndAPlot.plotSymbol = sgAndAPlotSymbol
        
        graph.addPlot(sgAndAPlot, toPlotSpace:plotSpace)
        plots.append(sgAndAPlot)
        
        if isDataForPeersSgAndALinePlot {
            
            let peersSgAndALinePlotColor = CPTColor.greenColor()
            
            let peersSgAndALinePlotLineStyle = CPTMutableLineStyle()
            peersSgAndALinePlotLineStyle.lineWidth = scatterPlotLineWidth
            peersSgAndALinePlotLineStyle.lineColor = peersSgAndALinePlotColor
            
            let peersSgAndALinePlot = CPTScatterPlot()
            peersSgAndALinePlot.delegate = self
            peersSgAndALinePlot.dataSource = self
            peersSgAndALinePlot.interpolation = CPTScatterPlotInterpolation.Curved
            peersSgAndALinePlot.dataLineStyle = peersSgAndALinePlotLineStyle
            peersSgAndALinePlot.plotSymbolMarginForHitDetection = plotSymbolMarginForHitDetection
            peersSgAndALinePlot.identifier = "Peers SG&A"
            
            let symbolLineStyle = CPTMutableLineStyle()
            symbolLineStyle.lineColor = peersSgAndALinePlotColor
            symbolLineStyle.lineWidth = scatterPlotLineWidth
            let peersSgAndALinePlotSymbol = CPTPlotSymbol.ellipsePlotSymbol()
            peersSgAndALinePlotSymbol.fill = CPTFill(color: GraphContent.Color.kPlotSymbolFillColor)
            peersSgAndALinePlotSymbol.lineStyle = symbolLineStyle
            peersSgAndALinePlotSymbol.size = scatterPlotSymbolSize
            peersSgAndALinePlot.plotSymbol = peersSgAndALinePlotSymbol
            
            graph.addPlot(peersSgAndALinePlot, toPlotSpace:plotSpace)
            plots.append(peersSgAndALinePlot)
        }
        
        // Add legend.
        graph.legend = legendForGraph()
        graph.legendAnchor = graphLegendAnchor
        graph.legendDisplacement = graphLegendDisplacement
        
        self.graphView.hostedGraph = graph
    }
    
    
    // MARK: - Data Convenience Methods
    
    func multipleOfFiveCeilNumber(number: Double, toSignificantFigures significantFigures: Int) -> Double {
        
        if number == 0.0 { return 0.0 }
        
        let places: Double = ceil(log10(number < 0 ? -number : number))
        let power: Int = significantFigures - Int(places)
        let magnitude: Double = pow(10.0, Double(power))
        
        var shifted: Int = 0
        if number > 0.0 {
            shifted = Int(ceil(number * magnitude))
        } else {
            shifted = Int(floor(number * magnitude))
        }
        
        // Round last significant digit up (down, if negative) to next multiple of 5.
        var fiveMultiple: Int = shifted / 5
        if shifted % 5 != 0 {
            if shifted >= 0 {
                fiveMultiple++
            } else {
                fiveMultiple--
            }
        }
        shifted = fiveMultiple * 5
        
        return Double(shifted)/magnitude
    }
    
    func calculateYAxisMinMaxAndIntervalForDataMinimumValue(minimumValue: Double, dataMaximumValue maximumValue: Double, initialYAxisMinimum yAxisMinimum: Double, initialYAxisMaximum yAxisMaximum: Double) {
        
        var minY: Double = yAxisMinimum
        var maxY: Double = yAxisMaximum
        
        var range: Double = yAxisMaximum - yAxisMinimum
                
        var interval: Double = range / yAxisIntervals
        interval = multipleOfFiveCeilNumber(interval, toSignificantFigures: 2)
        
        if minY < 0.0 {
            var intervalMultiple = (minY * 1.05) / interval
            intervalMultiple = floor(intervalMultiple)
            minY = intervalMultiple * interval
        }
        
        maxY = minY + yAxisIntervals * interval
        
        yAxisMin = minY
        yAxisMax = maxY
        yAxisInterval = interval
        yAxisRange = yAxisIntervals * interval
        
        let minimumValueRangePercentage = (minimumValue + abs(yAxisMin)) / yAxisRange
        let maximumValueRangePercentage = (maximumValue + abs(yAxisMin)) / yAxisRange
        
        let minimumAcceptableRangePercentage = 0.05
        let maximumAcceptableRangePercentage = UIDevice.currentDevice().userInterfaceIdiom == .Phone ? 0.87 : 0.95
        
        if minimumValueRangePercentage < minimumAcceptableRangePercentage && maximumValueRangePercentage > maximumAcceptableRangePercentage {
            calculateYAxisMinMaxAndIntervalForDataMinimumValue(minimumValue, dataMaximumValue: maximumValue, initialYAxisMinimum: yAxisMinimum - 0.05 * yAxisRange, initialYAxisMaximum: yAxisMaximum + 0.05 * yAxisRange)
        } else if minimumValueRangePercentage < minimumAcceptableRangePercentage {
            calculateYAxisMinMaxAndIntervalForDataMinimumValue(minimumValue, dataMaximumValue: maximumValue, initialYAxisMinimum: yAxisMinimum - 0.05 * yAxisRange, initialYAxisMaximum: yAxisMaximum)
        } else if maximumValueRangePercentage > maximumAcceptableRangePercentage {
            calculateYAxisMinMaxAndIntervalForDataMinimumValue(minimumValue, dataMaximumValue: maximumValue, initialYAxisMinimum: yAxisMinimum, initialYAxisMaximum: yAxisMaximum + 0.05 * yAxisRange)
        }
    }
    
    func calculateRevenueChartYAndY2AxisForRevenueMaximumValue(maximumValue: Double, initialRevenueYAxisMinimum yAxisMinimum: Double, initialRevenueYAxisMaximum yAxisMaximum: Double, profitMarginMinimumPercentageValue profitMarginMinimumValue: Double) {
        
        var minY: Double = yAxisMinimum
        var maxY: Double = yAxisMaximum
        
        var range: Double = yAxisMaximum - yAxisMinimum
        
        var interval: Double = range / yAxisIntervals
        interval = multipleOfFiveCeilNumber(interval, toSignificantFigures: 3)
        
        if yAxisMinimum >= 0.0 {
            maxY = yAxisIntervals * interval
        } else {
            let intervalsBelowZero = abs(floor(minY / interval))
            let intervalsAboveZero = yAxisIntervals - intervalsBelowZero
            minY = -(intervalsBelowZero * interval)
            maxY = intervalsAboveZero * interval
        }
        
        yAxisMin = minY
        yAxisMax = maxY
        yAxisInterval = interval
        yAxisRange = yAxisIntervals * interval
        
        y2AxisMax = 100.0
        
        while profitMarginMinimumValue < -2.75 * y2AxisMax {
            y2AxisMax *= 2.0
        }
        
        y2AxisMin = (yAxisMin / yAxisMax) * y2AxisMax
        y2AxisRange = y2AxisMax - y2AxisMin
        y2AxisInterval = y2AxisRange / yAxisIntervals
        
        let minimumValueRangePercentageLowerLimit = 0.05
        let minimumValueRangePercentage = (profitMarginMinimumValue + abs(y2AxisMin)) / y2AxisRange
        let maximumValueRangePercentage = (maximumValue + abs(yAxisMin)) / yAxisRange
        
        //let maximumRangePercentageUpperLimit = UIDevice.currentDevice().userInterfaceIdiom == .Phone ? 0.90 : 0.95    // Values to use for 1 line annotations.
        let maximumRangePercentageUpperLimit = UIDevice.currentDevice().userInterfaceIdiom == .Phone ? 0.87 : 0.92  // Values to use for 2 line annotations.
        
        if maximumValueRangePercentage > maximumRangePercentageUpperLimit {
            calculateRevenueChartYAndY2AxisForRevenueMaximumValue(maximumValue, initialRevenueYAxisMinimum: yAxisMinimum, initialRevenueYAxisMaximum: yAxisMaximum + 0.02 * yAxisRange, profitMarginMinimumPercentageValue: profitMarginMinimumValue)
        } else if minimumValueRangePercentage < minimumValueRangePercentageLowerLimit {
            calculateRevenueChartYAndY2AxisForRevenueMaximumValue(maximumValue, initialRevenueYAxisMinimum: yAxisMinimum - 0.02 * yAxisRange, initialRevenueYAxisMaximum: yAxisMaximum, profitMarginMinimumPercentageValue: profitMarginMinimumValue)
        }
    }
    
    
    func minimumOrZeroValueInFinancialMetricArray(financialMetrics: Array<FinancialMetric>) -> Double {
        
        var minimumValue: Double = 0.0
        
        for (index, financialMetric) in enumerate(financialMetrics) {
            let currentValue: Double = Double(financialMetric.value)
            if currentValue < minimumValue { minimumValue = currentValue }
        }
        
        return minimumValue
    }
    
    func minimumValueInFinancialMetricArray(financialMetrics: Array<FinancialMetric>) -> Double {
        
        var minimumValue: Double = 0.0
        
        for (index, financialMetric) in enumerate(financialMetrics) {
            let currentValue: Double = Double(financialMetric.value)
            if index == 0 {
                minimumValue = currentValue
            } else if currentValue < minimumValue {
                minimumValue = currentValue
            }
        }
        
        return minimumValue
    }
    
    func maximumValueInFinancialMetricArray(financialMetrics: Array<FinancialMetric>) -> Double {
        
        var maximumValue: Double = 0.0
        
        for (index, financialMetric) in enumerate(financialMetrics) {
            let currentValue: Double = Double(financialMetric.value)
            if currentValue > maximumValue { maximumValue = currentValue }
        }
        
        return maximumValue
    }
    
    
    func xAxisLabelsForFinancialMetrics(financialMetrics: Array<FinancialMetric>) -> Array<String> {
        
        var xAxisLabels = Array<String>()
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMM yyyy"
        
        for (index, financialMetric) in enumerate(financialMetrics) {
            let label: String = dateFormatter.stringFromDate(financialMetric.date)
            xAxisLabels.append(label)
        }
        
        for index in 0...(numberOfDataPointPerPlot - 1) {
            xAxisCustomTickLocations.append(Double(index) + 0.5)
        }
        
        plotSpaceLength = Double(numberOfDataPointPerPlot)
        
        return xAxisLabels
    }
    
    func averageValueForFinancialMetrics(financialMetrics: Array<FinancialMetric>) -> Double {
        
        var sum = 0.0
        
        for financialMetric in financialMetrics {
            sum += financialMetric.value as Double
        }
        
        return sum / Double(financialMetrics.count)
    }
    
    func correspondingPeersAverageArrayForTargetFinancialMetrics(targetFinancialMetrics: Array<FinancialMetric>) -> Array<FinancialMetric> {
        
        var peersAverageArray = Array<FinancialMetric>()
        
        if targetFinancialMetrics.count > 0 {
            
            let type = targetFinancialMetrics[0].type
            
            var peersAverageCalculationArray = Array<Array<FinancialMetric>>()
            let reversedTargetFinancialMetrics = targetFinancialMetrics.reverse()
            
            let entityDescription = NSEntityDescription.entityForName("FinancialMetric", inManagedObjectContext: managedObjectContext)
            let request = NSFetchRequest()
            request.entity = entityDescription
            
            let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
            request.sortDescriptors = [sortDescriptor]
            
            var error: NSError? = nil
            
            for index in 1...reversedTargetFinancialMetrics.count {
                var metricArray = [FinancialMetric]()
                peersAverageCalculationArray.append(metricArray)
            }
            
            let peerCompanies = company.peers.allObjects as [Company]
            for peerCompany in peerCompanies {
                
                let predicate = NSPredicate(format: "(company == %@) AND (type == %@)", peerCompany, type)
                request.predicate = predicate
                let peerMetricArray = managedObjectContext.executeFetchRequest(request, error: &error) as [FinancialMetric]
                if error != nil {
                    println("Fetch request error: \(error?.description)")
                }
                
                for (index, peerMetric) in enumerate(peerMetricArray) {
                    if index < peersAverageCalculationArray.count {
                        peersAverageCalculationArray[index].append(peerMetric)
                    }
                }
            }
            
            for (index, metricArray) in enumerate(peersAverageCalculationArray) {
                
                let entity = NSEntityDescription.entityForName("FinancialMetric", inManagedObjectContext: managedObjectContext)
                let financialMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: nil)
                financialMetric.date = reversedTargetFinancialMetrics[index].date
                financialMetric.type = reversedTargetFinancialMetrics[index].type
                financialMetric.value = averageValueForFinancialMetrics(peersAverageCalculationArray[index])
                
                peersAverageArray.append(financialMetric)
            }
        }
        
        return peersAverageArray.reverse()
    }
    
    
    // MARK: - CPTPlotDataSource
    
    func numberOfRecordsForPlot(plot: CPTPlot!) -> UInt {
        return UInt(plotSpaceLength)
    }
    
    func numberForPlot(plot: CPTPlot!, field: UInt, recordIndex: UInt) -> NSNumber! {
        
        switch pageIdentifier {
            
        case "Revenue":
            
            let plotID = plot.identifier as String
            let revenuePlotIdentifier = "Revenue (" + company.currencyCode + ")"
            let peersRevenuePlotIdentifier = "Peers Revenue (" + company.currencyCode + ")"
            
            if plotID == revenuePlotIdentifier {
                
                switch CPTBarPlotField(rawValue: Int(field))! {
                    
                case .BarLocation:
                    return recordIndex as NSNumber
                    
                case .BarTip:
                    
                    if plotID == revenuePlotIdentifier {
                        return totalRevenueArray[Int(recordIndex)].value
                    } else {
                        return nil
                    }
                    
                default:
                    return nil
                }
                
            } else if plotID == peersRevenuePlotIdentifier {
                
                switch CPTBarPlotField(rawValue: Int(field))! {
                    
                case .BarLocation:
                    return recordIndex as NSNumber
                    
                case .BarTip:
                    
                    if plotID == peersRevenuePlotIdentifier {
                        return peersTotalRevenueArray[Int(recordIndex)].value
                    } else {
                        return nil
                    }
                    
                default:
                    return nil
                }
                
            } else if plotID == "Profit Margin" {
                
                switch CPTScatterPlotField(rawValue: Int(field))! {
                    
                case .X:
                    let x = Double(recordIndex) + 0.50
                    return x as NSNumber
                    
                case .Y:
                    let plotID = plot.identifier as String
                    
                    if plotID == "Profit Margin" {
                        return profitMarginArray[Int(recordIndex)].value
                    } else {
                        return nil
                    }
                    
                default:
                    return nil
                }
                
            } else if plotID == "Peers Profit Margin" {
                
                switch CPTScatterPlotField(rawValue: Int(field))! {
                    
                case .X:
                    let x = Double(recordIndex) + 0.50
                    return x as NSNumber
                    
                case .Y:
                    let plotID = plot.identifier as String
                    
                    if plotID == "Peers Profit Margin" {
                        return peersProfitMarginArray[Int(recordIndex)].value
                    } else {
                        return nil
                    }
                    
                default:
                    return nil
                }
                
            } else {
                return nil
            }
            
        case "Growth":
            
            switch CPTScatterPlotField(rawValue: Int(field))! {
                
            case .X:
                let x = Double(recordIndex) + scatterPlotOffset
                return x as NSNumber
                
            case .Y:
                let plotID = plot.identifier as String
                
                if plotID == "Revenue Growth" {
                    return revenueGrowthArray[Int(recordIndex)].value
                } else if plotID == "Profit Margin" {
                    return profitMarginArray[Int(recordIndex)].value
                } else {
                    return nil
                }
                
            default:
                return nil
            }
            
        case "GrossMargin":
            
            switch CPTScatterPlotField(rawValue: Int(field))! {
                
            case .X:
                let x = Double(recordIndex) + scatterPlotOffset
                return x as NSNumber
                
            case .Y:
                let plotID = plot.identifier as String
                
                if plotID == "Gross Margin" {
                    return grossMarginArray[Int(recordIndex)].value
                } else if plotID == "Peers Gross Margin" {
                    return peersGrossMarginArray[Int(recordIndex)].value
                } else {
                    return nil
                }
                
            default:
                return nil
            }
            
        case "SG&A":
            
            switch CPTScatterPlotField(rawValue: Int(field))! {
                
            case .X:
                let x = Double(recordIndex) + scatterPlotOffset
                return x as NSNumber
                
            case .Y:
                let plotID = plot.identifier as String
                
                if plotID == "SG&A" {
                    return sgAndAArray[Int(recordIndex)].value
                } else if plotID == "Peers SG&A" {
                    return peersSgAndAArray[Int(recordIndex)].value
                } else {
                    return nil
                }
                
            default:
                return nil
            }
            
        case "R&D":
            
            switch CPTScatterPlotField(rawValue: Int(field))! {
                
            case .X:
                let x = Double(recordIndex) + scatterPlotOffset
                return x as NSNumber
                
            case .Y:
                let plotID = plot.identifier as String
                
                if plotID == "R&D" {
                    return rAndDArray[Int(recordIndex)].value
                } else if plotID == "Peers R&D" {
                    return peersRAndDArray[Int(recordIndex)].value
                } else {
                    return nil
                }
                
            default:
                return nil
            }
            
        default:
            return nil
        }
    }
    

    // MARK: - CPTBarPlotDelegate
    
    func barPlot(plot: CPTBarPlot!, barWasSelectedAtRecordIndex idx: UInt, withEvent event: UIEvent!) {
                
        let value = numberForPlot(plot, field: UInt(CPTBarPlotField.BarTip.rawValue), recordIndex: idx)
        let x: NSNumber = (Double(idx) + plot.barOffset.doubleValue) as NSNumber
        let y: NSNumber = value as NSNumber
        
        let typeString = plot.identifier as String
        var valueString = company.currencySymbol + Double(value).pibStandardStyleValueString()
        var revenueGrowthValueString: String = ""
        
        if idx > 0 {
            let revenueGrowthValue = Double(revenueGrowthArray[idx - 1].value)
            let revenueGrowthValueString = revenueGrowthValue < 0.0 ? "(" + revenueGrowthValue.pibPercentageStyleValueString() + ")" : "(+" + revenueGrowthValue.pibPercentageStyleValueString() + ")"
            valueString = valueString + " " + revenueGrowthValueString
        }
        
        delegate?.userSelectedGraphPointOfType!(typeString, forDate: xAxisLabels[Int(idx)], withValue: valueString)
    }
    
    
    // MARK: - CPTScatterPlotDelegate
    
    func scatterPlot(plot: CPTScatterPlot!, plotSymbolWasSelectedAtRecordIndex idx: UInt, withEvent event: UIEvent!) {
        
        let value = numberForPlot(plot, field: UInt(CPTScatterPlotField.Y.rawValue), recordIndex: idx)
        let x: NSNumber = (Double(idx) + scatterPlotOffset) as NSNumber
        let y: NSNumber = value as NSNumber
        
        //println("index: \(idx), date: \(xAxisLabels[Int(idx)]), type: \(plot.identifier), value: \(value)")
        let typeString = plot.identifier as String
        let valueString = Double(value).pibPercentageStyleValueString()
        delegate?.userSelectedGraphPointOfType!(typeString, forDate: xAxisLabels[Int(idx)], withValue: valueString)
    }
    
    
    // MARK: - Gesture Recognizer Methods
    
    @IBAction func handleDoubleTapGesture(recognizer: UITapGestureRecognizer) {
        
        if plots.count == 1 {
            plotLabelState = plotLabelState == 0 ? plots.count + 1 : 0
        } else {
            plotLabelState++
            if plotLabelState > plots.count + 1 { plotLabelState = 0 }
        }
        
        if plotLabelState == 0 {
            addRemoveAnnotationsAllPlots()
        } else if plotLabelState > plots.count {
            addRemoveAnnotationsAllPlots()
        } else {
            graph.plotAreaFrame.plotArea.removeAllAnnotations()
            addAnnotationsToPlot(plots[plotLabelState - 1])
        }
    }
    
    
    // MARK: - Plot Annotation Methods
    
    func addRemoveAnnotationsAllPlots() {
        
        if plotLabelState > 0 {
            
            graph.plotAreaFrame.plotArea.removeAllAnnotations()
            
        } else {
            
            let maxIndex: Int = Int(plotSpaceLength) - 1
            
            graph.plotAreaFrame.plotArea.removeAllAnnotations()
            
            if let plots = graph.allPlots() as? Array<CPTPlot> {
                
                for plot in plots {
                    
                    if let barPlot = plot as? CPTBarPlot {
                        
                        for index in 0...maxIndex {
                            addAnnotationsToBarPlot(barPlot, atSelectedRecordIndex: UInt(index))
                        }
                        
                    } else if let scatterPlot = plot as? CPTScatterPlot {
                        
                        for index in 0...maxIndex {
                            addAnnotationsToScatterPlot(scatterPlot, atSelectedRecordIndex: UInt(index))
                        }
                    }
                }
            }
        }
    }
    
    func addAnnotationsToPlot(plot: CPTPlot!) {
        
        let maxIndex: Int = Int(plotSpaceLength) - 1
        
        graph.plotAreaFrame.plotArea.removeAllAnnotations()
        
        if let barPlot = plot as? CPTBarPlot {
            
            for index in 0...maxIndex {
                addAnnotationsToBarPlot(barPlot, atSelectedRecordIndex: UInt(index))
            }
            
        } else if let scatterPlot = plot as? CPTScatterPlot {
            
            for index in 0...maxIndex {
                addAnnotationsToScatterPlot(scatterPlot, atSelectedRecordIndex: UInt(index))
            }
        }
    }
    
    func addAnnotationsToBarPlot(plot: CPTBarPlot!, atSelectedRecordIndex idx: UInt) {
        
        let value = numberForPlot(plot, field: UInt(CPTBarPlotField.BarTip.rawValue), recordIndex: idx)
        let x: NSNumber = (Double(idx) + plot.barOffset.doubleValue) as NSNumber
        let y: NSNumber = value as NSNumber
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.Center
        
        let attributesRevenueValueString = [NSFontAttributeName : UIFont.systemFontOfSize(GraphContent.Font.Size.kAnnotationFontSize), NSForegroundColorAttributeName : UIColor.grayColor(), NSParagraphStyleAttributeName : paragraphStyle]
        let revenueValueString = Double(value).pibGraphYAxisStyleValueString()
        var attributedAnnotationString = NSMutableAttributedString(string: revenueValueString, attributes: attributesRevenueValueString)
        
        var attributedRevenueGrowthValueString = NSMutableAttributedString()
        
        if idx > 0 {
            let revenueGrowthValue = Double(revenueGrowthArray[idx - 1].value)
            let revenueGrowthValueString = revenueGrowthValue < 0.0 ? "\n(" + revenueGrowthValue.pibPercentageStyleValueString() + ")" : "\n(+" + revenueGrowthValue.pibPercentageStyleValueString() + ")"
            let attributesRevenueGrowthValueString = [NSFontAttributeName : UIFont.systemFontOfSize(GraphContent.Font.Size.kAnnotationSubFontSize), NSForegroundColorAttributeName : UIColor.grayColor(), NSParagraphStyleAttributeName : paragraphStyle]
            attributedRevenueGrowthValueString = NSMutableAttributedString(string: revenueGrowthValueString, attributes: attributesRevenueGrowthValueString)
            attributedAnnotationString.appendAttributedString(attributedRevenueGrowthValueString)
        }
        
        let textLayer = CPTTextLayer(attributedText: attributedAnnotationString)
        //let textStyle = textLayer.textStyle.mutableCopy() as CPTMutableTextStyle
        //textStyle.color = CPTColor.blackColor()
        //textLayer.textStyle = textStyle
        textLayer.fill = CPTFill(color: CPTColor.whiteColor())
        textLayer.cornerRadius = 5.0
        
        let annotationLineStyle = CPTMutableLineStyle()
        annotationLineStyle.lineWidth = 1.0
        annotationLineStyle.lineColor = CPTColor.darkGrayColor()
        textLayer.borderLineStyle = annotationLineStyle
        
        let newAnnotation = CPTPlotSpaceAnnotation(plotSpace: plot.plotSpace, anchorPlotPoint: [x, y])
        newAnnotation.contentLayer = textLayer
        
        if idx > 0 {
            newAnnotation.displacement = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? CGPointMake(0.0, 24.0) : CGPointMake(0.0, 19.0)
        } else {
            newAnnotation.displacement = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? CGPointMake(0.0, 17.0) : CGPointMake(0.0, 13.0)
        }
        
        graph.plotAreaFrame.plotArea.addAnnotation(newAnnotation)
    }
    
    func addAnnotationsToScatterPlot(plot: CPTScatterPlot!, atSelectedRecordIndex idx: UInt) {
        
        let value = numberForPlot(plot, field: UInt(CPTScatterPlotField.Y.rawValue), recordIndex: idx)
        let x: NSNumber = (Double(idx) + scatterPlotOffset) as NSNumber
        let y: NSNumber = value as NSNumber
        
        let annotationString = Double(value).pibPercentageStyleValueString()
        
        let textLayer = CPTTextLayer(text: annotationString, style: annotationTextStyle)
        //let textStyle = textLayer.textStyle.mutableCopy() as CPTMutableTextStyle
        //textStyle.color = CPTColor.blackColor()
        //textLayer.textStyle = textStyle
        textLayer.fill = CPTFill(color: CPTColor.whiteColor())
        textLayer.cornerRadius = 5.0
        
        let annotationLineStyle = CPTMutableLineStyle()
        annotationLineStyle.lineWidth = 1.0
        annotationLineStyle.lineColor = CPTColor.darkGrayColor()
        textLayer.borderLineStyle = annotationLineStyle
        
        let newAnnotation = CPTPlotSpaceAnnotation(plotSpace: plot.plotSpace, anchorPlotPoint: [x, y])
        newAnnotation.contentLayer = textLayer

        let plotIdentifier = plot.identifier as String
        
        newAnnotation.displacement = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? CGPointMake(0.0, 25.0) : CGPointMake(0.0, 21.0)
        
        graph.plotAreaFrame.plotArea.addAnnotation(newAnnotation)
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
