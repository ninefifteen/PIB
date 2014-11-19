//
//  GraphContentViewController.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 11/1/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

import UIKit

class GraphContentViewController: UIViewController, CPTPlotDataSource, CPTBarPlotDelegate, CPTScatterPlotDelegate, CPTPlotAreaDelegate {

    // MARK: - Properties
    
    @IBOutlet weak var graphView: CPTGraphHostingView!
    
    var company: Company!
    
    let graph = CPTXYGraph()
    var pageIndex: Int = 0
    
    var totalRevenueArray = Array<FinancialMetric>()
    var netIncomeArray = Array<FinancialMetric>()
    var grossProfitArray = Array<FinancialMetric>()
    var rAndDArray = Array<FinancialMetric>()
    var sgAndAArray = Array<FinancialMetric>()
    
    var yAxisMin: Double = 0.0
    var yAxisMax: Double = 0.0
    var yAxisInterval: Double = 0.0
    var yAxisRange: Double = 0.0
    let numberOfYAxisIntervals: Double = 4.0
    
    var xAxisLabels = Array<String>()
    var yAxisLabels = Array<String>()
    var plotSpace = CPTXYPlotSpace()
    var axisSet = CPTXYAxisSet()
    var x = CPTXYAxis()
    var y = CPTXYAxis()
    var xAxisCustomTickLocations = Array<Double>()
    var yAxisCustomTickLocations = Array<Double>()
    var yMajorGridLineStyle = CPTMutableLineStyle()
    var barLineStyle = CPTMutableLineStyle()
    
    let xAxisLabelColor = CPTColor(componentRed: 23.0/255.0, green: 98.0/255.0, blue: 55.0/255.0, alpha: 1.0)
    let yAxisLabelColor = CPTColor(componentRed: 237.0/255.0, green: 68.0/255.0, blue: 4.0/255.0, alpha: 1.0)
    
    let xAxisLabelTextStyle = CPTMutableTextStyle()
    let yAxisLabelTextStyle = CPTMutableTextStyle()
    let legendTextStyle = CPTMutableTextStyle()
    let annotationTextStyle = CPTMutableTextStyle()
    let titleTextStyle = CPTMutableTextStyle()
    
    var scatterPlotOffset: Double = 0.0
    let scatterPlotLineWidth: CGFloat = 3.5
    let scatterPlotSymbolSize = CGSizeMake(14.0, 14.0)
    
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
                case "Net Income":
                    netIncomeArray.append(financialMetric)
                default:
                    break
                }
            }
            
            totalRevenueArray.sort({ $0.year < $1.year })
            netIncomeArray.sort({ $0.year < $1.year })
            
            var minValue = minimumValueInFinancialMetricArray(totalRevenueArray) < minimumValueInFinancialMetricArray(netIncomeArray) ? minimumValueInFinancialMetricArray(totalRevenueArray) : minimumValueInFinancialMetricArray(netIncomeArray)
            var maxValue = maximumValueInFinancialMetricArray(totalRevenueArray) > maximumValueInFinancialMetricArray(netIncomeArray) ? maximumValueInFinancialMetricArray(totalRevenueArray) : maximumValueInFinancialMetricArray(netIncomeArray)
            
            calculateyYAxisMinMaxAndIntervalForDataMinimumValue(minValue, dataMaximumValue: maxValue)
            
            xAxisLabels = xAxisLabelsForFinancialMetrics(totalRevenueArray)
            
            configureRevenueIncomeMarginGraph()
            
        case 1:
            var financialMetrics: [FinancialMetric] = company.financialMetrics.allObjects as [FinancialMetric]
            
            for (index, financialMetric) in enumerate(financialMetrics) {
                switch financialMetric.type {
                case "Gross Profit":
                    grossProfitArray.append(financialMetric)
                default:
                    break
                }
            }
            
            grossProfitArray.sort({ $0.year < $1.year })
            
            var minValue = minimumValueInFinancialMetricArray(grossProfitArray)
            var maxValue = maximumValueInFinancialMetricArray(grossProfitArray)
            
            calculateyYAxisMinMaxAndIntervalForDataMinimumValue(minValue, dataMaximumValue: maxValue)
            
            xAxisLabels = xAxisLabelsForFinancialMetrics(grossProfitArray)
            
            configureGrossMarginGraph()
            
        case 2:
            var financialMetrics: [FinancialMetric] = company.financialMetrics.allObjects as [FinancialMetric]
            
            for (index, financialMetric) in enumerate(financialMetrics) {
                switch financialMetric.type {
                case "Research & Development":
                    rAndDArray.append(financialMetric)
                default:
                    break
                }
            }
            
            rAndDArray.sort({ $0.year < $1.year })
            
            var minValue = minimumValueInFinancialMetricArray(rAndDArray)
            var maxValue = maximumValueInFinancialMetricArray(rAndDArray)
            
            calculateyYAxisMinMaxAndIntervalForDataMinimumValue(minValue, dataMaximumValue: maxValue)
            
            xAxisLabels = xAxisLabelsForFinancialMetrics(rAndDArray)
            
            scatterPlotOffset = 0.2
            
            configureRAndDGraph()
            
        case 3:
            var financialMetrics: [FinancialMetric] = company.financialMetrics.allObjects as [FinancialMetric]
            
            for (index, financialMetric) in enumerate(financialMetrics) {
                switch financialMetric.type {
                case "Selling/General/Admin. Expenses, Total":
                    sgAndAArray.append(financialMetric)
                default:
                    break
                }
            }
            
            sgAndAArray.sort({ $0.year < $1.year })
            
            var minValue = minimumValueInFinancialMetricArray(sgAndAArray)
            var maxValue = maximumValueInFinancialMetricArray(sgAndAArray)
            
            calculateyYAxisMinMaxAndIntervalForDataMinimumValue(minValue, dataMaximumValue: maxValue)
            
            xAxisLabels = xAxisLabelsForFinancialMetrics(sgAndAArray)
            
            scatterPlotOffset = 0.2

            configureSGAndAGraph()
            
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
        
        legendTextStyle.color = CPTColor.darkGrayColor()
        legendTextStyle.fontSize = 12.0
        
        annotationTextStyle.color = CPTColor.grayColor()
        annotationTextStyle.fontSize = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? 15.0 : 11.0
        
        titleTextStyle.color = CPTColor(componentRed: 120.0/255.0, green: 120.0/255.0, blue: 120.0/255.0, alpha: 1.0)
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
        
        graph.plotAreaFrame.paddingLeft   = 50.0
        graph.plotAreaFrame.paddingTop    = 36.0
        graph.plotAreaFrame.paddingRight  = 10.0
        graph.plotAreaFrame.paddingBottom = 80.0
    }
    
    func configureBaseBarGraph() {
        
        configureBaseGraph()
        
        // Plot space.
        plotSpace = graph.defaultPlotSpace as CPTXYPlotSpace
        plotSpace.yRange = CPTPlotRange(location: yAxisMin, length: yAxisRange)
        plotSpace.xRange = CPTPlotRange(location: 0.0, length: 4.0)
        
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
            var label:String = PIBHelper.pibGraphYAxisStyleValueStringFromDoubleValue(Double(value))
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
        plotSpace.xRange = CPTPlotRange(location: 0.0, length: 4.0)
        
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
        
        xAxisCustomTickLocations = [0.0, 1.0, 2.0, 3.0]
        
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
            var label:String = PIBHelper.pibGraphYAxisStyleValueStringFromDoubleValue(Double(value))
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
        configureTitleForGraph("Revenue  Income")
        
        // First bar plot.
        let revenueBarPlot = CPTBarPlot()
        revenueBarPlot.barsAreHorizontal = false
        revenueBarPlot.lineStyle = nil
        revenueBarPlot.fill = CPTFill(color: CPTColor(componentRed: 44.0/255.0, green: 146.0/255.0, blue: 172.0/255.0, alpha: 1.0))
        revenueBarPlot.barWidth = 0.3
        revenueBarPlot.baseValue = 0.0
        revenueBarPlot.barOffset = 0.30
        revenueBarPlot.barCornerRadius = 2.0
        revenueBarPlot.identifier = "Revenue"
        revenueBarPlot.delegate = self
        revenueBarPlot.dataSource = self
        graph.addPlot(revenueBarPlot, toPlotSpace:plotSpace)
        
        // Second bar plot.
        let netIncomeBarPlot = CPTBarPlot()
        netIncomeBarPlot.barsAreHorizontal = false
        netIncomeBarPlot.lineStyle = nil
        netIncomeBarPlot.fill = CPTFill(color: CPTColor(componentRed: 233.0/255.0, green: 31.0/255.0, blue: 100.0/255.0, alpha: 1.0))
        netIncomeBarPlot.barWidth = 0.3
        netIncomeBarPlot.baseValue = 0.0
        netIncomeBarPlot.barOffset = 0.70
        netIncomeBarPlot.barCornerRadius = 2.0
        netIncomeBarPlot.identifier = "Net Income"
        netIncomeBarPlot.delegate = self
        netIncomeBarPlot.dataSource = self
        graph.addPlot(netIncomeBarPlot, toPlotSpace:plotSpace)
        
        // Add legend.
        graph.legend = legendForGraph()
        graph.legendAnchor = .Bottom
        graph.legendDisplacement = CGPointMake(0.0, 25.0)
        
        self.graphView.hostedGraph = graph
    }
    
    func configureGrossMarginGraph() {
        
        configureBaseBarGraph()
        configureTitleForGraph("Gross Margin")
        
        // First bar plot.
        let revenueBarPlot = CPTBarPlot()
        revenueBarPlot.barsAreHorizontal = false
        revenueBarPlot.lineStyle = nil
        revenueBarPlot.fill = CPTFill(color: CPTColor(componentRed: 44.0/255.0, green: 146.0/255.0, blue: 172.0/255.0, alpha: 1.0))
        revenueBarPlot.barWidth = 0.5
        revenueBarPlot.baseValue = 0.0
        revenueBarPlot.barOffset = 0.50
        revenueBarPlot.barCornerRadius = 2.0
        revenueBarPlot.identifier = "Gross Profit"
        revenueBarPlot.delegate = self
        revenueBarPlot.dataSource = self
        graph.addPlot(revenueBarPlot, toPlotSpace:plotSpace)
        
        // Add legend.
        graph.legend = legendForGraph()
        graph.legendAnchor = .Bottom
        graph.legendDisplacement = CGPointMake(0.0, 25.0)
        
        self.graphView.hostedGraph = graph
    }
    
    func configureRAndDGraph() {
        
        configureBaseCurvedLineGraph()
        configureTitleForGraph("R & D")
        
        let raAndDLinePlotColor = CPTColor(componentRed: 233.0/255.0, green: 31.0/255.0, blue: 100.0/255.0, alpha: 1.0)
        
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
        graph.legendAnchor = .Bottom
        graph.legendDisplacement = CGPointMake(0.0, 25.0)
        
        self.graphView.hostedGraph = graph
    }
    
    func configureSGAndAGraph() {
        
        configureBaseCurvedLineGraph()
        configureTitleForGraph("SG & A")

        let sgAndALinePlotColor = CPTColor(componentRed: 44.0/255.0, green: 146.0/255.0, blue: 172.0/255.0, alpha: 1.0)
        
        let sgAndALinePlotLineStyle = CPTMutableLineStyle()
        sgAndALinePlotLineStyle.lineWidth = scatterPlotLineWidth
        sgAndALinePlotLineStyle.lineColor = sgAndALinePlotColor
        
        let sgAndALinePlot = CPTScatterPlot()
        sgAndALinePlot.delegate = self
        sgAndALinePlot.dataSource = self
        sgAndALinePlot.interpolation = CPTScatterPlotInterpolation.Curved
        sgAndALinePlot.dataLineStyle = sgAndALinePlotLineStyle
        sgAndALinePlot.identifier = "SG&A"
        
        let symbolLineStyle = CPTMutableLineStyle()
        symbolLineStyle.lineColor = sgAndALinePlotColor
        symbolLineStyle.lineWidth = scatterPlotLineWidth
        let plotSymbol = CPTPlotSymbol.ellipsePlotSymbol()
        plotSymbol.fill = CPTFill(color: CPTColor.whiteColor())
        plotSymbol.lineStyle = symbolLineStyle
        plotSymbol.size = scatterPlotSymbolSize
        sgAndALinePlot.plotSymbol = plotSymbol
        
        graph.addPlot(sgAndALinePlot, toPlotSpace:plotSpace)
        
        // Add legend.
        let graphLegend = CPTLegend(graph: graph)
        graphLegend.fill = CPTFill(color: CPTColor.whiteColor())
        graphLegend.borderLineStyle = nil
        graphLegend.cornerRadius = 10.0
        graphLegend.swatchSize = CGSizeMake(14.0, 14.0)
        let blackTextStyle = CPTMutableTextStyle()
        blackTextStyle.color = CPTColor.blackColor()
        blackTextStyle.fontSize = 12.0
        graphLegend.textStyle = blackTextStyle
        graphLegend.rowMargin = 10.0
        graphLegend.numberOfRows = 1
        graphLegend.paddingLeft = 8.0
        graphLegend.paddingTop = 8.0
        graphLegend.paddingRight = 8.0
        graphLegend.paddingBottom = 8.0
        
        graph.legend = graphLegend
        graph.legendAnchor = .Bottom
        graph.legendDisplacement = CGPointMake(0.0, 25.0)
        
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
        let range: Double = (maxY - minY) * 1.15
        
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
    
    func xAxisLabelsForFinancialMetrics(financialMetrics: Array<FinancialMetric>) -> Array<String> {
        
        var xAxisLabels = Array<String>()
        
        for (index, financialMetric) in enumerate(financialMetrics) {
            let label: String = "\(financialMetric.year)"
            xAxisLabels.append(label)
        }
        
        return xAxisLabels
    }
    
    
    // MARK: - CPTPlotDataSource
    
    func numberOfRecordsForPlot(plot: CPTPlot!) -> UInt {
        return 4
    }
    
    func numberForPlot(plot: CPTPlot!, field: UInt, recordIndex: UInt) -> NSNumber! {
        
        switch pageIndex {
            
        case 0:
            
            switch CPTBarPlotField(rawValue: Int(field))! {
                
            case .BarLocation:
                return recordIndex as NSNumber
                
            case .BarTip:
                
                let plotID = plot.identifier as String
                
                if plotID == "Revenue" {
                    return totalRevenueArray[Int(recordIndex)].value
                } else if plotID == "Net Income" {
                    return netIncomeArray[Int(recordIndex)].value
                } else {
                    return nil
                }
                
            default:
                return nil
            }
            
        case 1:
            
            switch CPTBarPlotField(rawValue: Int(field))! {
                
            case .BarLocation:
                return recordIndex as NSNumber
                
            case .BarTip:
                
                let plotID = plot.identifier as String
                
                if plotID == "Gross Profit" {
                    return grossProfitArray[Int(recordIndex)].value
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
                
                if plotID == "R&D" {
                    return rAndDArray[Int(recordIndex)].value
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
        
        graph.plotAreaFrame.plotArea.removeAllAnnotations()
        
        if let plots = graph.allPlots() as? Array<CPTPlot> {
            
            for plot in plots {
                
                if let barPlot = plot as? CPTBarPlot {
                    
                    for index in 0...3 {
                        addAnnotationToBarPlot(barPlot, atSelectedRecordIndex: UInt(index))
                    }
                    
                } else if let scatterPlot = plot as? CPTScatterPlot {
                    
                    for index in 0...3 {
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
        textLayer.fill = CPTFill(color: CPTColor.whiteColor())
        textLayer.cornerRadius = 5.0
        
        let annotationLineStyle = CPTMutableLineStyle()
        annotationLineStyle.lineWidth = 1.0
        annotationLineStyle.lineColor = CPTColor.darkGrayColor()
        textLayer.borderLineStyle = annotationLineStyle
        
        let newAnnotation = CPTPlotSpaceAnnotation(plotSpace: plot.plotSpace, anchorPlotPoint: [x, y])
        newAnnotation.contentLayer = textLayer
        newAnnotation.displacement = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? CGPointMake(0.0, 16.0) : CGPointMake(0.0, 12.0)
        
        graph.plotAreaFrame.plotArea.addAnnotation(newAnnotation)
    }
    
    func addAnnotationToScatterPlot(plot: CPTScatterPlot!, atSelectedRecordIndex idx: UInt) {
        
        let value = numberForPlot(plot, field: UInt(CPTScatterPlotField.Y.rawValue), recordIndex: idx)
        let x: NSNumber = (Double(idx) + scatterPlotOffset) as NSNumber
        let y: NSNumber = value as NSNumber
        
        let annotationString = PIBHelper.pibGraphYAxisStyleValueStringFromDoubleValue(Double(value))
        
        let textLayer = CPTTextLayer(text: annotationString, style: annotationTextStyle)
        textLayer.fill = CPTFill(color: CPTColor.whiteColor())
        textLayer.cornerRadius = 5.0
        
        let annotationLineStyle = CPTMutableLineStyle()
        annotationLineStyle.lineWidth = 1.0
        annotationLineStyle.lineColor = CPTColor.darkGrayColor()
        textLayer.borderLineStyle = annotationLineStyle
        
        let newAnnotation = CPTPlotSpaceAnnotation(plotSpace: plot.plotSpace, anchorPlotPoint: [x, y])
        newAnnotation.contentLayer = textLayer
        newAnnotation.displacement = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? CGPointMake(0.0, 24.0) : CGPointMake(0.0, 20.0)
        
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
