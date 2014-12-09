//
//  GraphContentViewController.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 11/1/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//

import UIKit

class GraphContentViewController: UIViewController, CPTPlotDataSource, CPTBarPlotDelegate, CPTScatterPlotDelegate, CPTPlotAreaDelegate {

    // MARK: - Properties
    
    @IBOutlet weak var graphView: CPTGraphHostingView!
    
    var company: Company!
    
    let graph = CPTXYGraph()
    var pageIndex: Int = 0
    
    var totalRevenueArray = Array<FinancialMetric>()
    var profitMarginArray = Array<FinancialMetric>()
    var revenueGrowthArray = Array<FinancialMetric>()
    var netIncomeGrowthArray = Array<FinancialMetric>()
    var netIncomeArray = Array<FinancialMetric>()
    var grossProfitArray = Array<FinancialMetric>()
    var grossMarginArray = Array<FinancialMetric>()
    var rAndDArray = Array<FinancialMetric>()
    var sgAndAArray = Array<FinancialMetric>()
    
    var yAxisMin: Double = 0.0
    var yAxisMax: Double = 0.0
    var yAxisInterval: Double = 0.0
    var yAxisRange: Double = 0.0
    let numberOfYAxisIntervals: Double = 4.0
    
    var y2AxisMin: Double = 0.0
    var y2AxisMax: Double = 0.0
    var y2AxisInterval: Double = 0.0
    var y2AxisRange: Double = 0.0
    let numberOfY2AxisIntervals: Double = 4.0
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
    
    let xAxisLabelColor = CPTColor(componentRed: 23.0/255.0, green: 98.0/255.0, blue: 55.0/255.0, alpha: 1.0)
    let yAxisLabelColor = CPTColor(componentRed: 237.0/255.0, green: 68.0/255.0, blue: 4.0/255.0, alpha: 1.0)
    let y2AxisLabelColor = CPTColor(componentRed: 237.0/255.0, green: 68.0/255.0, blue: 4.0/255.0, alpha: 1.0)
    
    let xAxisLabelTextStyle = CPTMutableTextStyle()
    let yAxisLabelTextStyle = CPTMutableTextStyle()
    let y2AxisLabelTextStyle = CPTMutableTextStyle()
    let legendTextStyle = CPTMutableTextStyle()
    let annotationTextStyle = CPTMutableTextStyle()
    let titleTextStyle = CPTMutableTextStyle()
    
    var scatterPlotOffset: Double = 0.0
    let scatterPlotLineWidth: CGFloat = 3.5
    let scatterPlotSymbolSize = CGSizeMake(13.0, 13.0)
    
    var allAnnotationsShowing: Bool = false
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        configureTextStyles()
        
        switch pageIndex {
            
        case 0:
            var financialMetrics: [FinancialMetric] = company.financialMetrics.allObjects as [FinancialMetric]
            
            for (index, financialMetric) in enumerate(financialMetrics) {
                switch financialMetric.type {
                case "Revenue":
                    totalRevenueArray.append(financialMetric)
                case "Profit Margin":
                    profitMarginArray.append(financialMetric)
                default:
                    break
                }
            }
            
            totalRevenueArray.sort({ $0.year < $1.year })
            netIncomeArray.sort({ $0.year < $1.year })
            profitMarginArray.sort({ $0.year < $1.year })
            
            var minPercentageValue = minimumValueInFinancialMetricArray(profitMarginArray)
            
            var minValue = minimumValueInFinancialMetricArray(totalRevenueArray)
            var maxValue = maximumValueInFinancialMetricArray(totalRevenueArray)
            
            calculateyYAxisMinMaxAndIntervalForDataMinimumValue(minValue, dataMaximumValue: maxValue, percentageDataMinimumValue: minPercentageValue)
            
            xAxisLabels = xAxisLabelsForFinancialMetrics(totalRevenueArray)
            
            scatterPlotOffset = 0.5
            
            configureRevenueIncomeMarginGraph()
            
        case 1:
            var financialMetrics: [FinancialMetric] = company.financialMetrics.allObjects as [FinancialMetric]
            
            for (index, financialMetric) in enumerate(financialMetrics) {
                switch financialMetric.type {
                case "Revenue Growth":
                    revenueGrowthArray.append(financialMetric)
                case "Net Income Growth":
                    netIncomeGrowthArray.append(financialMetric)
                default:
                    break
                }
            }
            
            revenueGrowthArray.sort({ $0.year < $1.year })
            netIncomeGrowthArray.sort({ $0.year < $1.year })
            
            var minValue = minimumValueInFinancialMetricArray(revenueGrowthArray) < minimumValueInFinancialMetricArray(netIncomeGrowthArray) ? minimumValueInFinancialMetricArray(revenueGrowthArray) : minimumValueInFinancialMetricArray(netIncomeGrowthArray)
            var maxValue = maximumValueInFinancialMetricArray(revenueGrowthArray) > maximumValueInFinancialMetricArray(netIncomeGrowthArray) ? maximumValueInFinancialMetricArray(revenueGrowthArray) : maximumValueInFinancialMetricArray(netIncomeGrowthArray)
            
            calculateyYAxisMinMaxAndIntervalForDataMinimumValue(minValue, dataMaximumValue: maxValue)
            
            xAxisLabels = xAxisLabelsForFinancialMetrics(revenueGrowthArray)
            
            // Overwrite tick locations and plot length.
            xAxisCustomTickLocations = [0.0, 1.0, 2.0]
            plotSpaceLength = 3.0
            
            scatterPlotOffset = 0.2
            
            configureRevenueGrowthNetIncomeGrowthGraph()
            
        case 2:
            var financialMetrics: [FinancialMetric] = company.financialMetrics.allObjects as [FinancialMetric]
            
            for (index, financialMetric) in enumerate(financialMetrics) {
                switch financialMetric.type {
                case "Gross Margin":
                    grossMarginArray.append(financialMetric)
                default:
                    break
                }
            }
            
            grossMarginArray.sort({ $0.year < $1.year })
            
            var minValue = minimumValueInFinancialMetricArray(grossMarginArray)
            var maxValue = maximumValueInFinancialMetricArray(grossMarginArray)
            
            calculateyYAxisMinMaxAndIntervalForDataMinimumValue(minValue, dataMaximumValue: maxValue)
            
            xAxisLabels = xAxisLabelsForFinancialMetrics(grossMarginArray)
            
            scatterPlotOffset = 0.2
            
            configureGrossMarginGraph()
            
        case 3:
            var financialMetrics: [FinancialMetric] = company.financialMetrics.allObjects as [FinancialMetric]
            
            for (index, financialMetric) in enumerate(financialMetrics) {
                switch financialMetric.type {
                case "SG&A As Percent Of Revenue":
                    sgAndAArray.append(financialMetric)
                default:
                    break
                }
            }
            
            sgAndAArray.sort({ $0.year < $1.year })
            
            var minValue = minimumValueInFinancialMetricArray(sgAndAArray)
            var maxValue = maximumValueInFinancialMetricArray(sgAndAArray)
            
            calculateyYAxisMinMaxAndIntervalForDataMinimumValue(minValue, dataMaximumValue: maxValue, percentageDataMinimumValue: 0.0)
            
            xAxisLabels = xAxisLabelsForFinancialMetrics(sgAndAArray)
            
            scatterPlotOffset = 0.2
            
            configureSGAndAGraph()
            
        case 4:
            var financialMetrics: [FinancialMetric] = company.financialMetrics.allObjects as [FinancialMetric]
            
            for (index, financialMetric) in enumerate(financialMetrics) {
                switch financialMetric.type {
                case "R&D As Percent Of Revenue":
                    rAndDArray.append(financialMetric)
                default:
                    break
                }
            }
            
            rAndDArray.sort({ $0.year < $1.year })
            
            var minValue = minimumValueInFinancialMetricArray(rAndDArray)
            var maxValue = maximumValueInFinancialMetricArray(rAndDArray)
            
            calculateyYAxisMinMaxAndIntervalForDataMinimumValue(minValue, dataMaximumValue: maxValue, percentageDataMinimumValue: 0.0)
            
            xAxisLabels = xAxisLabelsForFinancialMetrics(rAndDArray)
            
            scatterPlotOffset = 0.2
            
            configureRAndDGraph()
            
        default:
            break
        }
        
        addAnnotationsToAllPlots()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Graph Configure Methods
    
    func configureTextStyles() {
        
        xAxisLabelTextStyle.color = xAxisLabelColor
        xAxisLabelTextStyle.fontSize = 14.0
        
        yAxisLabelTextStyle.color = yAxisLabelColor
        yAxisLabelTextStyle.fontSize = 14.0
        
        y2AxisLabelTextStyle.color = y2AxisLabelColor
        y2AxisLabelTextStyle.fontSize = 14.0
        y2AxisLabelTextStyle.textAlignment = CPTTextAlignment.Left
        
        legendTextStyle.color = CPTColor.darkGrayColor()
        legendTextStyle.fontSize = 12.0
        
        annotationTextStyle.color = CPTColor.grayColor()
        annotationTextStyle.fontSize = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? 18.0 : 13.0
        
        //titleTextStyle.color = CPTColor(componentRed: 120.0/255.0, green: 120.0/255.0, blue: 120.0/255.0, alpha: 1.0)
        titleTextStyle.fontName = "Helvetica-Bold"
        titleTextStyle.color = yAxisLabelColor
        titleTextStyle.fontSize = 15.0
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
        legend.paddingLeft = 8.0
        legend.paddingTop = 8.0
        legend.paddingRight = 8.0
        legend.paddingBottom = 8.0
        
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
        
        if pageIndex == 0 {
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
        graph.plotAreaFrame.paddingTop = 56.0
        graph.plotAreaFrame.paddingRight = 10.0
        graph.plotAreaFrame.paddingBottom = 60.0
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
        
        // Overwrite tick locations.
        xAxisCustomTickLocations = [0.5, 1.5, 2.5, 3.5]
        
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
        for index in 0...Int(numberOfYAxisIntervals) {
            let tickLocation: Double = yAxisMin + (Double(index) * yAxisInterval)
            yAxisCustomTickLocations.append(tickLocation)
        }
        
        // Create y-axis major tick line style.
        yMajorGridLineStyle.lineWidth = 1.0
        yMajorGridLineStyle.lineColor = CPTColor(componentRed: 200.0/255.0, green: 200.0/255.0, blue: 200.0/255.0, alpha: 1.0)
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
        for (index, value) in enumerate(yAxisCustomTickLocations) {
            var label: String = PIBHelper.pibGraphYAxisStyleValueStringFromDoubleValue(Double(value))
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
        
        // Create bar line style.
        barLineStyle.lineWidth = 1.0
        barLineStyle.lineColor = CPTColor.blackColor()
    }
    
    func configureBaseCurvedLineGraph() {
        
        configureBaseGraph()
        
        graph.paddingRight = 10.0
        graph.plotAreaFrame.paddingRight  = -44.0
        
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
            newLabel.tickLocation = tickLocation + scatterPlotOffset
            newLabel.offset = x.labelOffset + x.majorTickLength
            //newLabel.rotation = CGFloat(M_PI_4)
            xAxisCustomLabels.addObject(newLabel)
        }
        
        x.axisLabels = xAxisCustomLabels
        
        // Create y-axis custom tick locations.
        for index in 0...Int(numberOfYAxisIntervals) {
            let tickLocation: Double = yAxisMin + (Double(index) * yAxisInterval)
            yAxisCustomTickLocations.append(tickLocation)
        }
        
        // Create y-axis major tick line style.
        yMajorGridLineStyle.lineWidth = 1.0
        yMajorGridLineStyle.lineColor = CPTColor(componentRed: 200.0/255.0, green: 200.0/255.0, blue: 200.0/255.0, alpha: 1.0)
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
        for (index, value) in enumerate(yAxisCustomTickLocations) {
            var label:String = PIBHelper.pibGraphYAxisStyleValueStringFromDoubleValue(Double(value)) + "%"
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
    
    func configureRevenueIncomeMarginGraph() {
        
        configureBaseBarGraph()
        let graphTitle = "Revenue (" + company.currencyCode + ")"
        configureTitleForGraph(graphTitle)
        
        // Change right padding for 2nd Y Axis labels.
        graph.plotAreaFrame.paddingRight  = 46.0
        
        // Add 2nd plot space to graph for scatter plot.
        plotSpace2 = CPTXYPlotSpace()
        graph.addPlotSpace(plotSpace2)
        plotSpace2.yRange = CPTPlotRange(location: y2AxisMin, length: y2AxisRange)
        plotSpace2.xRange = CPTPlotRange(location: 0.0, length: 4.0)
        
        // Configure 2nd Y Axis for scatter plot.
        y2.coordinate = CPTCoordinate.Y
        y2.plotSpace = plotSpace2
        y2.axisLineStyle = nil
        y2.majorTickLineStyle = nil
        y2.minorTickLineStyle = nil
        y2.majorTickLocations = NSSet(array: y2AxisCustomTickLocations)
        y2.majorGridLineStyle = nil
        y2.majorIntervalLength = y2AxisInterval
        y2.orthogonalPosition = 4.0
        y2.labelingPolicy = .None
        y2.labelTextStyle = y2AxisLabelTextStyle
        y2.tickDirection = CPTSign.Positive
        
        // Custom Labels for 2nd Y Axis.
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
        
        graph.axisSet.axes = [x, y2, y]
        
        // First bar plot.
        let revenueBarPlot = CPTBarPlot()
        revenueBarPlot.barsAreHorizontal = false
        revenueBarPlot.lineStyle = nil
        revenueBarPlot.fill = CPTFill(color: CPTColor(componentRed: 44.0/255.0, green: 146.0/255.0, blue: 172.0/255.0, alpha: 1.0))
        revenueBarPlot.barWidth = 0.60
        revenueBarPlot.baseValue = 0.0
        revenueBarPlot.barOffset = 0.50
        revenueBarPlot.barCornerRadius = 2.0
        revenueBarPlot.identifier = "Revenue"
        revenueBarPlot.delegate = self
        revenueBarPlot.dataSource = self
        graph.addPlot(revenueBarPlot, toPlotSpace:plotSpace)
        
        // Profit Margin background line plot.
        /*let profitMarginPlotBackgroundColor = CPTColor(componentRed: 233.0/255.0, green: 31.0/255.0, blue: 100.0/255.0, alpha: 1.0)
        
        let profitMarginPlotBackgroundLineStyle = CPTMutableLineStyle()
        profitMarginPlotBackgroundLineStyle.lineWidth = scatterPlotLineWidth + 2.0
        profitMarginPlotBackgroundLineStyle.lineColor = CPTColor.whiteColor()
        
        let profitMarginBackgroundLinePlot = CPTScatterPlot()
        profitMarginBackgroundLinePlot.delegate = self
        profitMarginBackgroundLinePlot.dataSource = self
        profitMarginBackgroundLinePlot.interpolation = CPTScatterPlotInterpolation.Curved
        profitMarginBackgroundLinePlot.dataLineStyle = profitMarginPlotBackgroundLineStyle
        profitMarginBackgroundLinePlot.identifier = "Profit Margin Background"
        
        let backgroundSymbolLineStyle = CPTMutableLineStyle()
        backgroundSymbolLineStyle.lineColor = CPTColor.whiteColor()
        backgroundSymbolLineStyle.lineWidth = scatterPlotLineWidth
        let backgroundPlotSymbol = CPTPlotSymbol.ellipsePlotSymbol()
        //plotSymbol.fill = CPTFill(color: profitMarginPlotColor)
        backgroundPlotSymbol.fill = CPTFill(color: CPTColor.whiteColor())
        backgroundPlotSymbol.lineStyle = backgroundSymbolLineStyle
        backgroundPlotSymbol.size = CGSizeMake(scatterPlotSymbolSize.width + 2.0, scatterPlotSymbolSize.height + 2.0)
        profitMarginBackgroundLinePlot.plotSymbol = backgroundPlotSymbol
        
        graph.addPlot(profitMarginBackgroundLinePlot, toPlotSpace:plotSpace2)*/
        
        // Profit Margin line plot.
        let profitMarginPlotColor = CPTColor(componentRed: 233.0/255.0, green: 31.0/255.0, blue: 100.0/255.0, alpha: 1.0)
        
        let profitMarginPlotLineStyle = CPTMutableLineStyle()
        profitMarginPlotLineStyle.lineWidth = scatterPlotLineWidth
        profitMarginPlotLineStyle.lineColor = profitMarginPlotColor
        
        let profitMarginLinePlot = CPTScatterPlot()
        profitMarginLinePlot.delegate = self
        profitMarginLinePlot.dataSource = self
        profitMarginLinePlot.interpolation = CPTScatterPlotInterpolation.Curved
        profitMarginLinePlot.dataLineStyle = profitMarginPlotLineStyle
        profitMarginLinePlot.identifier = "Profit Margin"
        
        let symbolLineStyle = CPTMutableLineStyle()
        symbolLineStyle.lineColor = profitMarginPlotColor
        symbolLineStyle.lineWidth = scatterPlotLineWidth
        let plotSymbol = CPTPlotSymbol.ellipsePlotSymbol()
        //plotSymbol.fill = CPTFill(color: profitMarginPlotColor)
        plotSymbol.fill = CPTFill(color: CPTColor.whiteColor())
        plotSymbol.lineStyle = symbolLineStyle
        plotSymbol.size = scatterPlotSymbolSize
        profitMarginLinePlot.plotSymbol = plotSymbol
        
        graph.addPlot(profitMarginLinePlot, toPlotSpace:plotSpace2)
        
        // Add legend.
        graph.legend = legendForGraph()
        graph.legendAnchor = .Top
        graph.legendDisplacement = CGPointMake(0.0, -25.0)
        //graph.legend.removePlot(profitMarginBackgroundLinePlot)
        
        self.graphView.hostedGraph = graph
    }
    
    func configureRevenueGrowthNetIncomeGrowthGraph() {
        
        configureBaseCurvedLineGraph()
        configureTitleForGraph("Growth Dynamics")
        
        let revenueGrowthPlotColor = CPTColor(componentRed: 44.0/255.0, green: 146.0/255.0, blue: 172.0/255.0, alpha: 1.0)
        
        let revenueGrowthPlotLineStyle = CPTMutableLineStyle()
        revenueGrowthPlotLineStyle.lineWidth = scatterPlotLineWidth
        revenueGrowthPlotLineStyle.lineColor = revenueGrowthPlotColor
        
        let revenueGrowthPlot = CPTScatterPlot()
        revenueGrowthPlot.delegate = self
        revenueGrowthPlot.dataSource = self
        revenueGrowthPlot.interpolation = CPTScatterPlotInterpolation.Curved
        revenueGrowthPlot.dataLineStyle = revenueGrowthPlotLineStyle
        revenueGrowthPlot.identifier = "Revenue"
        
        let symbolLineStyle = CPTMutableLineStyle()
        symbolLineStyle.lineColor = revenueGrowthPlotColor
        symbolLineStyle.lineWidth = scatterPlotLineWidth
        let revenueGrowthPlotSymbol = CPTPlotSymbol.ellipsePlotSymbol()
        revenueGrowthPlotSymbol.fill = CPTFill(color: CPTColor.whiteColor())
        revenueGrowthPlotSymbol.lineStyle = symbolLineStyle
        revenueGrowthPlotSymbol.size = scatterPlotSymbolSize
        revenueGrowthPlot.plotSymbol = revenueGrowthPlotSymbol
        
        graph.addPlot(revenueGrowthPlot, toPlotSpace:plotSpace)
        
        let netIncomeGrowthPlotColor = CPTColor(componentRed: 233.0/255.0, green: 31.0/255.0, blue: 100.0/255.0, alpha: 1.0)
        
        let netIncomeGrowthPlotLineStyle = CPTMutableLineStyle()
        netIncomeGrowthPlotLineStyle.lineWidth = scatterPlotLineWidth
        netIncomeGrowthPlotLineStyle.lineColor = netIncomeGrowthPlotColor
        
        let netIncomeGrowthPlot = CPTScatterPlot()
        netIncomeGrowthPlot.delegate = self
        netIncomeGrowthPlot.dataSource = self
        netIncomeGrowthPlot.interpolation = CPTScatterPlotInterpolation.Curved
        netIncomeGrowthPlot.dataLineStyle = netIncomeGrowthPlotLineStyle
        netIncomeGrowthPlot.identifier = "Net Income"
        
        symbolLineStyle.lineColor = netIncomeGrowthPlotColor
        symbolLineStyle.lineWidth = scatterPlotLineWidth
        let netIncomeGrowthPlotSymbol = CPTPlotSymbol.ellipsePlotSymbol()
        netIncomeGrowthPlotSymbol.fill = CPTFill(color: CPTColor.whiteColor())
        netIncomeGrowthPlotSymbol.lineStyle = symbolLineStyle
        netIncomeGrowthPlotSymbol.size = scatterPlotSymbolSize
        netIncomeGrowthPlot.plotSymbol = netIncomeGrowthPlotSymbol
        
        graph.addPlot(netIncomeGrowthPlot, toPlotSpace:plotSpace)
        
        // Add legend.
        graph.legend = legendForGraph()
        graph.legendAnchor = .Top
        graph.legendDisplacement = CGPointMake(0.0, -25.0)
        
        self.graphView.hostedGraph = graph
    }
    
    func configureGrossMarginGraph() {
        
        configureBaseCurvedLineGraph()
        configureTitleForGraph("Gross Margin")
        
        let grossMarginPlotColor = CPTColor(componentRed: 233.0/255.0, green: 31.0/255.0, blue: 100.0/255.0, alpha: 1.0)
        
        let grossMarginPlotLineStyle = CPTMutableLineStyle()
        grossMarginPlotLineStyle.lineWidth = scatterPlotLineWidth
        grossMarginPlotLineStyle.lineColor = grossMarginPlotColor
        
        let grossMarginPlot = CPTScatterPlot()
        grossMarginPlot.delegate = self
        grossMarginPlot.dataSource = self
        grossMarginPlot.interpolation = CPTScatterPlotInterpolation.Curved
        grossMarginPlot.dataLineStyle = grossMarginPlotLineStyle
        grossMarginPlot.identifier = "Gross Margin"
        
        let symbolLineStyle = CPTMutableLineStyle()
        symbolLineStyle.lineColor = grossMarginPlotColor
        symbolLineStyle.lineWidth = scatterPlotLineWidth
        let grossMarginPlotSymbol = CPTPlotSymbol.ellipsePlotSymbol()
        grossMarginPlotSymbol.fill = CPTFill(color: CPTColor.whiteColor())
        grossMarginPlotSymbol.lineStyle = symbolLineStyle
        grossMarginPlotSymbol.size = scatterPlotSymbolSize
        grossMarginPlot.plotSymbol = grossMarginPlotSymbol
        
        graph.addPlot(grossMarginPlot, toPlotSpace:plotSpace)
        
        // Add legend.
        graph.legend = legendForGraph()
        graph.legendAnchor = .Top
        graph.legendDisplacement = CGPointMake(0.0, -25.0)
        
        self.graphView.hostedGraph = graph
    }
    
    func configureRAndDGraph() {
        
        configureBaseCurvedLineGraph()
        configureTitleForGraph("R & D")
        
        let raAndDLinePlotColor = CPTColor(componentRed: 44.0/255.0, green: 146.0/255.0, blue: 172.0/255.0, alpha: 1.0)
        
        let rAndDLinePlotLineStyle = CPTMutableLineStyle()
        rAndDLinePlotLineStyle.lineWidth = scatterPlotLineWidth
        rAndDLinePlotLineStyle.lineColor = raAndDLinePlotColor
        
        let rAndDLinePlot = CPTScatterPlot()
        rAndDLinePlot.delegate = self
        rAndDLinePlot.dataSource = self
        rAndDLinePlot.interpolation = CPTScatterPlotInterpolation.Curved
        rAndDLinePlot.dataLineStyle = rAndDLinePlotLineStyle
        rAndDLinePlot.identifier = "R&D"
        
        let symbolLineStyle = CPTMutableLineStyle()
        symbolLineStyle.lineColor = raAndDLinePlotColor
        symbolLineStyle.lineWidth = scatterPlotLineWidth
        let plotSymbol = CPTPlotSymbol.ellipsePlotSymbol()
        plotSymbol.fill = CPTFill(color: CPTColor.whiteColor())
        plotSymbol.lineStyle = symbolLineStyle
        plotSymbol.size = scatterPlotSymbolSize
        rAndDLinePlot.plotSymbol = plotSymbol
        
        graph.addPlot(rAndDLinePlot, toPlotSpace:plotSpace)
        
        // Add legend.
        graph.legend = legendForGraph()
        graph.legendAnchor = .Top
        graph.legendDisplacement = CGPointMake(0.0, -25.0)
        
        self.graphView.hostedGraph = graph
    }
    
    func configureSGAndAGraph() {
        
        configureBaseCurvedLineGraph()
        configureTitleForGraph("SG & A")
        
        let sgAndAPlotColor = CPTColor(componentRed: 44.0/255.0, green: 146.0/255.0, blue: 172.0/255.0, alpha: 1.0)
        
        let sgAndAPlotLineStyle = CPTMutableLineStyle()
        sgAndAPlotLineStyle.lineWidth = scatterPlotLineWidth
        sgAndAPlotLineStyle.lineColor = sgAndAPlotColor
        
        let sgAndAPlot = CPTScatterPlot()
        sgAndAPlot.delegate = self
        sgAndAPlot.dataSource = self
        sgAndAPlot.interpolation = CPTScatterPlotInterpolation.Curved
        sgAndAPlot.dataLineStyle = sgAndAPlotLineStyle
        sgAndAPlot.identifier = "SG&A"
        
        let symbolLineStyle = CPTMutableLineStyle()
        symbolLineStyle.lineColor = sgAndAPlotColor
        symbolLineStyle.lineWidth = scatterPlotLineWidth
        let sgAndAPlotSymbol = CPTPlotSymbol.ellipsePlotSymbol()
        sgAndAPlotSymbol.fill = CPTFill(color: CPTColor.whiteColor())
        sgAndAPlotSymbol.lineStyle = symbolLineStyle
        sgAndAPlotSymbol.size = scatterPlotSymbolSize
        sgAndAPlot.plotSymbol = sgAndAPlotSymbol
        
        graph.addPlot(sgAndAPlot, toPlotSpace:plotSpace)
        
        // Add legend.
        graph.legend = legendForGraph()
        graph.legendAnchor = .Top
        graph.legendDisplacement = CGPointMake(0.0, -25.0)
        
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
    
    func calculateyYAxisMinMaxAndIntervalForDataMinimumValue(minimumValue: Double, dataMaximumValue maximumValue: Double) {
        
        var minY: Double = minimumValue
        var maxY: Double = maximumValue
        //maxY += ((maxY - minY) / (numberOfYAxisIntervals * 2)) // Add room for labels.
        
        var range: Double = (maxY - minY) * 1.15
        
        var interval: Double = range / numberOfYAxisIntervals
        interval = multipleOfFiveCeilNumber(interval, toSignificantFigures: 2)
        
        if minY < 0.0 {
            var intervalMultiple = (minY * 1.05) / interval
            intervalMultiple = floor(intervalMultiple)
            minY = intervalMultiple * interval
        }
        
        maxY = minY + numberOfYAxisIntervals * interval
        
        yAxisMin = minY
        yAxisMax = maxY
        yAxisInterval = interval
        yAxisRange = numberOfYAxisIntervals * interval
    }
    
    func calculateyYAxisMinMaxAndIntervalForDataMinimumValue(minimumValue: Double, dataMaximumValue maximumValue: Double, percentageDataMinimumValue percentageMinimumValue: Double) {
        
        var minY: Double = minimumValue
        var maxY: Double = maximumValue
        maxY += ((maxY - minY) / (numberOfYAxisIntervals * 2)) // Add room for labels.
        
        var percentageIntervalsBelowZero = calculateRequiredMajorIntervalsBelowForMinimumPercentage(percentageMinimumValue)
        
        if percentageIntervalsBelowZero == 1 && minY >= 0 {
            minY = -((maxY - minY) / (numberOfYAxisIntervals * 2))
        } else if percentageIntervalsBelowZero == 2 {
            if maxY >= fabs(minY) {
                minY = -fabs(maxY)
            } else {
                maxY = fabs(minY)
            }
        } else if percentageIntervalsBelowZero == 3 {
            if maxY >= fabs(minY) {
                minY = -fabs(maxY) * 3.0
            } else {
                maxY = fabs(minY) * 3.0
            }
        }
        
        var range: Double = (maxY - minY) * 1.15
        
        var interval: Double = range / numberOfYAxisIntervals
        interval = multipleOfFiveCeilNumber(interval, toSignificantFigures: 2)
        
        if minY < 0.0 {
            var intervalMultiple = (minY * 1.05) / interval
            intervalMultiple = floor(intervalMultiple)
            minY = intervalMultiple * interval
        }
        
        maxY = minY + numberOfYAxisIntervals * interval
                
        yAxisMin = minY
        yAxisMax = maxY
        yAxisInterval = interval
        yAxisRange = numberOfYAxisIntervals * interval
        
        // Calculate Y2 axis.
        if minY + interval * 3.0 <= 0.0 {
            y2AxisCustomTickLocations = [-300.0, -200.0, -100.0, 0.0, 100.0]
            y2AxisMin = -300.0
            y2AxisMax = 100.0
            y2AxisInterval = 100.0
        } else if minY + interval * 2.0 <= 0.0 {
            y2AxisCustomTickLocations = [-100.0, -50.0, 0.0, 50.0, 100.0]
            y2AxisMin = -100.0
            y2AxisMax = 100.0
            y2AxisInterval = 50.0
        } else if minY + interval <= 0.0 {
            y2AxisCustomTickLocations = [-33.333, 0.0, 33.333, 66.666, 99.999]
            y2AxisMin = -33.333
            y2AxisMax = 100.0
            y2AxisInterval = 33.333
        } else {
            y2AxisCustomTickLocations = [0.0, 25.0, 50.0, 75.0, 100.0]
            y2AxisMin = 0.0
            y2AxisMax = 100.0
            y2AxisInterval = 25.0
        }
        y2AxisRange = y2AxisMax - y2AxisMin
    }
    
    func calculateyPercentageOnlyYAxisMinMaxAndIntervalForDataMinimumValue(minimumValue: Double, dataMaximumValue maximumValue: Double) {
        
        // Calculate Y2 axis.
        if minimumValue < -100.0 {
            yAxisCustomTickLocations = [-300.0, -200.0, -100.0, 0.0, 100.0]
            yAxisMin = -300.0
            yAxisMax = 100.0
            yAxisInterval = 100.0
        } else if minimumValue < -100.0 / 3.0 {
            yAxisCustomTickLocations = [-100.0, -50.0, 0.0, 50.0, 100.0]
            yAxisMin = -100.0
            yAxisMax = 100.0
            yAxisInterval = 50.0
        } else if minimumValue < 0.0 {
            yAxisCustomTickLocations = [-33.333, 0.0, 33.333, 66.666, 99.999]
            yAxisMin = -33.333
            yAxisMax = 100.0
            yAxisInterval = 33.333
        } else {
            yAxisCustomTickLocations = [0.0, 25.0, 50.0, 75.0, 100.0]
            yAxisMin = 0.0
            yAxisMax = 100.0
            yAxisInterval = 25.0
        }
        yAxisRange = yAxisMax - yAxisMin
    }
    
    func minimumValueInFinancialMetricArray(financialMetrics: Array<FinancialMetric>) -> Double {
        
        var minimumValue: Double = 0.0
        
        for (index, financialMetric) in enumerate(financialMetrics) {
            let currentValue: Double = Double(financialMetric.value)
            if currentValue < minimumValue { minimumValue = currentValue }
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
    
    func calculateRequiredMajorIntervalsBelowForMinimumPercentage(minPercentage: Double) -> Int {
        
        if minPercentage < -100.0 {
            return 3
        } else if minPercentage < -100.0 / 3.0 {
            return 2
        } else if minPercentage < 0.0 {
            return 1
        } else {
            return 0
        }
    }
    
    func xAxisLabelsForFinancialMetrics(financialMetrics: Array<FinancialMetric>) -> Array<String> {
        
        var xAxisLabels = Array<String>()
        
        for (index, financialMetric) in enumerate(financialMetrics) {
            let label: String = "\(financialMetric.year)"
            xAxisLabels.append(label)
        }
        
        xAxisCustomTickLocations = [0.0, 1.0, 2.0, 3.0]
        plotSpaceLength = 4.0
        
        return xAxisLabels
    }
    
    
    // MARK: - CPTPlotDataSource
    
    func numberOfRecordsForPlot(plot: CPTPlot!) -> UInt {
        return UInt(plotSpaceLength)
    }
    
    func numberForPlot(plot: CPTPlot!, field: UInt, recordIndex: UInt) -> NSNumber! {
        
        switch pageIndex {
            
        case 0:
            
            let plotID = plot.identifier as String
            
            if plotID == "Revenue" || plotID == "Net Income" {
                
                switch CPTBarPlotField(rawValue: Int(field))! {
                    
                case .BarLocation:
                    return recordIndex as NSNumber
                    
                case .BarTip:
                    
                    let plotID = plot.identifier as String
                    
                    if plotID == "Revenue" {
                        return totalRevenueArray[Int(recordIndex)].value
                    } else if plotID == "Net Income" {
                        return netIncomeArray[Int(recordIndex)].value
                    } else if plotID == "Profit Margin" {
                        return profitMarginArray[Int(recordIndex)].value
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
                
            } else if plotID == "Profit Margin Background" {
                
                switch CPTScatterPlotField(rawValue: Int(field))! {
                    
                case .X:
                    let x = Double(recordIndex) + 0.50
                    return x as NSNumber
                    
                case .Y:
                    let plotID = plot.identifier as String
                    
                    if plotID == "Profit Margin Background" {
                        return profitMarginArray[Int(recordIndex)].value
                    } else {
                        return nil
                    }
                    
                default:
                    return nil
                }
                
            } else {
                return nil
            }
            
        case 1:
            
            switch CPTScatterPlotField(rawValue: Int(field))! {
                
            case .X:
                let x = Double(recordIndex) + scatterPlotOffset
                return x as NSNumber
                
            case .Y:
                let plotID = plot.identifier as String
                
                if plotID == "Revenue" {
                    return revenueGrowthArray[Int(recordIndex)].value
                } else if plotID == "Net Income" {
                    return netIncomeGrowthArray[Int(recordIndex)].value
                } else {
                    return nil
                }
                
            default:
                return nil
            }
            
        case 2:
            
            switch CPTScatterPlotField(rawValue: Int(field))! {
                
            case .X:
                let x = Double(recordIndex) + scatterPlotOffset
                return x as NSNumber
                
            case .Y:
                let plotID = plot.identifier as String
                
                if plotID == "Gross Margin" {
                    return grossMarginArray[Int(recordIndex)].value
                } else {
                    return nil
                }
                
            default:
                return nil
            }
            
        case 3:
            
            switch CPTScatterPlotField(rawValue: Int(field))! {
                
            case .X:
                let x = Double(recordIndex) + scatterPlotOffset
                return x as NSNumber
                
            case .Y:
                let plotID = plot.identifier as String
                
                if plotID == "SG&A" {
                    return sgAndAArray[Int(recordIndex)].value
                } else {
                    return nil
                }
                
            default:
                return nil
            }
            
        case 4:
            
            switch CPTScatterPlotField(rawValue: Int(field))! {
                
            case .X:
                let x = Double(recordIndex) + scatterPlotOffset
                return x as NSNumber
                
            case .Y:
                let plotID = plot.identifier as String
                
                if plotID == "R&D" {
                    return rAndDArray[Int(recordIndex)].value
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
    
    func barPlot(plot: CPTBarPlot!, barWasSelectedAtRecordIndex idx: UInt) {
        
        var removedAnnotation: Bool = false
        
        let value = numberForPlot(plot, field: UInt(CPTBarPlotField.BarTip.rawValue), recordIndex: idx)
        let x: NSNumber = (Double(idx) + plot.barOffset.doubleValue) as NSNumber
        let y: NSNumber = value as NSNumber
        
        for annotation in graph.plotAreaFrame.plotArea.annotations {
            if let annotationAnchorPlotPoint = annotation.anchorPlotPoint as? [NSNumber] {
                if annotationAnchorPlotPoint[0] == x && annotationAnchorPlotPoint[1] == y {
                    graph.plotAreaFrame.plotArea.removeAnnotation(annotation as CPTAnnotation)
                    removedAnnotation = true
                }
            }
        }
        
        if !removedAnnotation {
            
            addAnnotationToBarPlot(plot, atSelectedRecordIndex: idx)
        }
    }
    
    
    // MARK: - CPTScatterPlotDelegate
    
    func scatterPlot(plot: CPTScatterPlot!, plotSymbolWasSelectedAtRecordIndex idx: UInt) {
        
        var removedAnnotation: Bool = false
        
        let value = numberForPlot(plot, field: UInt(CPTScatterPlotField.Y.rawValue), recordIndex: idx)
        let x: NSNumber = (Double(idx) + scatterPlotOffset) as NSNumber
        let y: NSNumber = value as NSNumber
        
        for annotation in graph.plotAreaFrame.plotArea.annotations {
            if let annotationAnchorPlotPoint = annotation.anchorPlotPoint as? [NSNumber] {
                if annotationAnchorPlotPoint[0] == x && annotationAnchorPlotPoint[1] == y {
                    graph.plotAreaFrame.plotArea.removeAnnotation(annotation as CPTAnnotation)
                    removedAnnotation = true
                }
            }
        }
        
        if !removedAnnotation {
            
            addAnnotationToScatterPlot(plot, atSelectedRecordIndex: idx)
        }
    }
    
    
    // MARK: - Gesture Recognizer Methods
    
    @IBAction func handleDoubleTap(recognizer: UITapGestureRecognizer) {
        
        if allAnnotationsShowing {
            graph.plotAreaFrame.plotArea.removeAllAnnotations()
            allAnnotationsShowing = false
        } else {
            addAnnotationsToAllPlots()
        }
    }
    
    
    // MARK: - Plot Annotation Methods
    
    func addAnnotationsToAllPlots() {
        
        let maxIndex: Int = Int(plotSpaceLength) - 1
        
        graph.plotAreaFrame.plotArea.removeAllAnnotations()
        
        if let plots = graph.allPlots() as? Array<CPTPlot> {
            
            for plot in plots {
                
                if let barPlot = plot as? CPTBarPlot {
                    
                    for index in 0...maxIndex {
                        addAnnotationToBarPlot(barPlot, atSelectedRecordIndex: UInt(index))
                    }
                    
                } else if let scatterPlot = plot as? CPTScatterPlot {
                    
                    for index in 0...maxIndex {
                        addAnnotationToScatterPlot(scatterPlot, atSelectedRecordIndex: UInt(index))
                    }
                }
            }
        }
        allAnnotationsShowing = true
    }
    
    func addAnnotationToBarPlot(plot: CPTBarPlot!, atSelectedRecordIndex idx: UInt) {
        
        let value = numberForPlot(plot, field: UInt(CPTBarPlotField.BarTip.rawValue), recordIndex: idx)
        let x: NSNumber = (Double(idx) + plot.barOffset.doubleValue) as NSNumber
        let y: NSNumber = value as NSNumber
        
        let annotationString = PIBHelper.pibGraphYAxisStyleValueStringFromDoubleValue(Double(value))
        
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
        newAnnotation.displacement = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? CGPointMake(0.0, 17.0) : CGPointMake(0.0, 13.0)
        
        graph.plotAreaFrame.plotArea.addAnnotation(newAnnotation)
    }
    
    func addAnnotationToScatterPlot(plot: CPTScatterPlot!, atSelectedRecordIndex idx: UInt) {
        
        let value = numberForPlot(plot, field: UInt(CPTScatterPlotField.Y.rawValue), recordIndex: idx)
        let x: NSNumber = (Double(idx) + scatterPlotOffset) as NSNumber
        let y: NSNumber = value as NSNumber
        
        let annotationString = PIBHelper.pibGraphYAxisStyleValueStringFromDoubleValue(Double(value)) + "%"
        
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
