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
    
    @IBOutlet weak var singleTapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var doubleTapGestureRecognizer: UITapGestureRecognizer!
    
    var company: Company!
    
    let graph = CPTXYGraph()
    var pageIndex: Int = 0
    var pageIdentifier: String = ""
    
    var totalRevenueArray = Array<FinancialMetric>()
    var profitMarginArray = Array<FinancialMetric>()
    var revenueGrowthArray = Array<FinancialMetric>()
    var netIncomeGrowthArray = Array<FinancialMetric>()
    var grossProfitArray = Array<FinancialMetric>()
    var grossMarginArray = Array<FinancialMetric>()
    var rAndDArray = Array<FinancialMetric>()
    var sgAndAArray = Array<FinancialMetric>()
    
    var numberOfDataPointPerPlot: Int = 0
    
    var yAxisMin: Double = 0.0
    var yAxisMax: Double = 0.0
    var yAxisInterval: Double = 0.0
    var yAxisRange: Double = 0.0
    
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
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        singleTapGestureRecognizer.requireGestureRecognizerToFail(doubleTapGestureRecognizer)
        
        configureTextStyles()
        
        switch pageIdentifier {
            
        case "Revenue":
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
            profitMarginArray.sort({ $0.year < $1.year })
            
            numberOfDataPointPerPlot = totalRevenueArray.count
            
            var minPercentageValue = minimumValueInFinancialMetricArray(profitMarginArray)
            
            var minValue = minimumValueInFinancialMetricArray(totalRevenueArray)
            var maxValue = maximumValueInFinancialMetricArray(totalRevenueArray)
            
            calculateyYAxisMinMaxAndIntervalForDataMinimumValue(minValue, dataMaximumValue: maxValue, percentageDataMinimumValue: minPercentageValue)
            
            xAxisLabels = xAxisLabelsForFinancialMetrics(totalRevenueArray)
            
            configureRevenueIncomeMarginGraph()
            
        case "Growth":
            var financialMetrics: [FinancialMetric] = company.financialMetrics.allObjects as [FinancialMetric]
            
            for (index, financialMetric) in enumerate(financialMetrics) {
                switch financialMetric.type {
                case "Revenue Growth":
                    revenueGrowthArray.append(financialMetric)
                case "Profit Margin":
                    profitMarginArray.append(financialMetric)
                default:
                    break
                }
            }
            
            revenueGrowthArray.sort({ $0.year < $1.year })
            profitMarginArray.sort({ $0.year < $1.year })
            
            if profitMarginArray.count > 0 { profitMarginArray.removeAtIndex(0) }
            
            numberOfDataPointPerPlot = revenueGrowthArray.count
            
            var minValue = minimumValueInFinancialMetricArray(revenueGrowthArray) < minimumValueInFinancialMetricArray(profitMarginArray) ? minimumValueInFinancialMetricArray(revenueGrowthArray) : minimumValueInFinancialMetricArray(profitMarginArray)
            var maxValue = maximumValueInFinancialMetricArray(revenueGrowthArray) > maximumValueInFinancialMetricArray(profitMarginArray) ? maximumValueInFinancialMetricArray(revenueGrowthArray) : maximumValueInFinancialMetricArray(profitMarginArray)
            
            calculateyYAxisMinMaxAndIntervalForDataMinimumValue(minValue, dataMaximumValue: maxValue, initialYAxisMinimum: 0.0, initialYAxisMaximum: maxValue)
            
            xAxisLabels = xAxisLabelsForFinancialMetrics(revenueGrowthArray)
            
            configureRevenueGrowthProfitMarginGraph()
            
        case "GrossMargin":
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
            
            numberOfDataPointPerPlot = grossMarginArray.count
            
            calculateyYAxisMinMaxAndIntervalForDataMinimumValue(minValue, dataMaximumValue: maxValue, initialYAxisMinimum: 0.0, initialYAxisMaximum: maxValue)
            
            xAxisLabels = xAxisLabelsForFinancialMetrics(grossMarginArray)
            
            configureGrossMarginGraph()
            
        case "SG&A":
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
            
            numberOfDataPointPerPlot = sgAndAArray.count
            
            var minValue = minimumValueInFinancialMetricArray(sgAndAArray)
            var maxValue = maximumValueInFinancialMetricArray(sgAndAArray)
            
            calculateyYAxisMinMaxAndIntervalForDataMinimumValue(minValue, dataMaximumValue: maxValue, initialYAxisMinimum: 0.0, initialYAxisMaximum: maxValue)
            
            xAxisLabels = xAxisLabelsForFinancialMetrics(sgAndAArray)
            
            configureSGAndAGraph()
            
        case "R&D":
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
            
            numberOfDataPointPerPlot = rAndDArray.count
            
            var minValue = minimumValueInFinancialMetricArray(rAndDArray)
            var maxValue = maximumValueInFinancialMetricArray(rAndDArray)
            
            calculateyYAxisMinMaxAndIntervalForDataMinimumValue(minValue, dataMaximumValue: maxValue, initialYAxisMinimum: 0.0, initialYAxisMaximum: maxValue)
            
            xAxisLabels = xAxisLabelsForFinancialMetrics(rAndDArray)
            
            configureRAndDGraph()
            
        default:
            break
        }
        
        plotLabelState = 0  // All plots labeled.
        addRemoveAnnotationsAllPlots()
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
        graph.plotAreaFrame.paddingTop = 36.0
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
        for index in 0...Int(GraphContent.Axis.Y.kNumberOfIntervals) {
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
        for index in 0...Int(GraphContent.Axis.Y.kNumberOfIntervals) {
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
        //let graphTitle = "Revenue (" + company.currencyCode + ")"
        //configureTitleForGraph(graphTitle)
        
        let isDataForProfitMarginPlot: Bool = minimumValueInFinancialMetricArray(profitMarginArray) != 0.0 || maximumValueInFinancialMetricArray(profitMarginArray) != 0.0
        
        if isDataForProfitMarginPlot {
            
            // Change right padding for 2nd Y Axis labels.
            graph.plotAreaFrame.paddingRight = 46.0
            
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
            
        } else {
            
            graph.axisSet.axes = [x, y]
        }
        
        // First bar plot.
        let revenueBarPlot = CPTBarPlot()
        revenueBarPlot.barsAreHorizontal = false
        revenueBarPlot.lineStyle = nil
        revenueBarPlot.fill = CPTFill(color: GraphContent.Color.kRevenuePlotColor)
        revenueBarPlot.barWidth = 0.60
        revenueBarPlot.baseValue = 0.0
        revenueBarPlot.barOffset = 0.50
        revenueBarPlot.barCornerRadius = 2.0
        let revenueBarPlotIdentifier = "Revenue (" + company.currencyCode + ")"
        revenueBarPlot.identifier = revenueBarPlotIdentifier
        revenueBarPlot.delegate = self
        revenueBarPlot.dataSource = self
        graph.addPlot(revenueBarPlot, toPlotSpace:plotSpace)
        plots.append(revenueBarPlot)
        
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
        
        // Add legend.
        graph.legend = legendForGraph()
        graph.legendAnchor = graphLegendAnchor
        graph.legendDisplacement = graphLegendDisplacement
        
        self.graphView.hostedGraph = graph
    }
    
    func configureRAndDGraph() {
        
        configureBaseCurvedLineGraph()
        //configureTitleForGraph("R & D")
        
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
        
        // Add legend.
        graph.legend = legendForGraph()
        graph.legendAnchor = graphLegendAnchor
        graph.legendDisplacement = graphLegendDisplacement
        
        self.graphView.hostedGraph = graph
    }
    
    func configureSGAndAGraph() {
        
        configureBaseCurvedLineGraph()
        //configureTitleForGraph("SG & A")
        
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
    
    func calculateyYAxisMinMaxAndIntervalForDataMinimumValue(minimumValue: Double, dataMaximumValue maximumValue: Double, initialYAxisMinimum yAxisMinimum: Double, initialYAxisMaximum yAxisMaximum: Double) {
        
        var minY: Double = yAxisMinimum
        var maxY: Double = yAxisMaximum
        
        var range: Double = yAxisMaximum - yAxisMinimum
        
        var interval: Double = range / GraphContent.Axis.Y.kNumberOfIntervals
        interval = multipleOfFiveCeilNumber(interval, toSignificantFigures: 2)
        
        if minY < 0.0 {
            var intervalMultiple = (minY * 1.05) / interval
            intervalMultiple = floor(intervalMultiple)
            minY = intervalMultiple * interval
        }
        
        maxY = minY + GraphContent.Axis.Y.kNumberOfIntervals * interval
        
        yAxisMin = minY
        yAxisMax = maxY
        yAxisInterval = interval
        yAxisRange = GraphContent.Axis.Y.kNumberOfIntervals * interval
        
        let minimumValueRangePercentage = (minimumValue + abs(yAxisMin)) / yAxisRange
        let maximumValueRangePercentage = (maximumValue + abs(yAxisMin)) / yAxisRange
        
        let minimumAcceptableRangePercentage = 0.05
        let maximumAcceptableRangePercentage = UIDevice.currentDevice().userInterfaceIdiom == .Phone ? 0.90 : 0.95
        
        if minimumValueRangePercentage < minimumAcceptableRangePercentage && maximumValueRangePercentage > maximumAcceptableRangePercentage {
            calculateyYAxisMinMaxAndIntervalForDataMinimumValue(minimumValue, dataMaximumValue: maximumValue, initialYAxisMinimum: yAxisMinimum - 0.05 * yAxisRange, initialYAxisMaximum: yAxisMaximum + 0.05 * yAxisRange)
        } else if minimumValueRangePercentage < minimumAcceptableRangePercentage {
            calculateyYAxisMinMaxAndIntervalForDataMinimumValue(minimumValue, dataMaximumValue: maximumValue, initialYAxisMinimum: yAxisMinimum - 0.05 * yAxisRange, initialYAxisMaximum: yAxisMaximum)
        } else if maximumValueRangePercentage > maximumAcceptableRangePercentage {
            calculateyYAxisMinMaxAndIntervalForDataMinimumValue(minimumValue, dataMaximumValue: maximumValue, initialYAxisMinimum: yAxisMinimum, initialYAxisMaximum: yAxisMaximum + 0.05 * yAxisRange)
        }
    }
    
    func calculateyYAxisMinMaxAndIntervalForDataMinimumValue(minimumValue: Double, dataMaximumValue maximumValue: Double, percentageDataMinimumValue percentageMinimumValue: Double) {
        
        var minY: Double = minimumValue
        var maxY: Double = maximumValue
        
        // Compensate for curved interpolation line possibly going below zero.
        if minY >= 0.0 {
            minY = minY < maxY * 0.10 ? -0.001 : 0.0
        }
        
        maxY += ((maxY - minY) / (GraphContent.Axis.Y.kNumberOfIntervals * 2)) // Add room for labels.
        
        // Compensate for plot symbols near zero being partially cut off.
        let adjustZoneMax = UIDevice.currentDevice().userInterfaceIdiom == .Phone ? 3.0 : 1.0
        let adjustedPercentageMinimumValue = percentageMinimumValue < adjustZoneMax && percentageMinimumValue >= 0.0 ? -0.001 : percentageMinimumValue
        let percentageIntervalsBelowZero = calculateRequiredMajorIntervalsBelowZeroForMinimumPercentage(adjustedPercentageMinimumValue)
        
        if percentageIntervalsBelowZero == 1 && minY >= 0 {
            minY = -((maxY - minY) / (GraphContent.Axis.Y.kNumberOfIntervals * 2))
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
        
        var range: Double = 0.0
        if minY < 0.0 {
            range = (maxY - minY) * 1.40
        } else {
            range = (maxY - minY) * 1.05
        }
        
        var interval: Double = range / GraphContent.Axis.Y.kNumberOfIntervals
        interval = multipleOfFiveCeilNumber(interval, toSignificantFigures: 2)
        
        if minY < 0.0 {
            var intervalMultiple = (minY * 1.05) / interval
            intervalMultiple = floor(intervalMultiple)
            minY = intervalMultiple * interval
        }
        
        maxY = minY + GraphContent.Axis.Y.kNumberOfIntervals * interval
        yAxisMin = minY
        yAxisMax = maxY
        yAxisInterval = interval
        yAxisRange = GraphContent.Axis.Y.kNumberOfIntervals * interval
        
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
    
    func calculateRequiredMajorIntervalsBelowZeroForMinimumPercentage(minPercentage: Double) -> Int {
        
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
        
        for index in 0...(numberOfDataPointPerPlot - 1) {
            xAxisCustomTickLocations.append(Double(index) + 0.5)
        }
        
        plotSpaceLength = Double(numberOfDataPointPerPlot)
        
        return xAxisLabels
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
        
        /*var removedAnnotation: Bool = false
        
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
            
            addAnnotationsToBarPlot(plot, atSelectedRecordIndex: idx)
        }*/
    }
    
    
    // MARK: - CPTScatterPlotDelegate
    
    func scatterPlot(plot: CPTScatterPlot!, plotSymbolWasSelectedAtRecordIndex idx: UInt) {
        
        /*var removedAnnotation: Bool = false
        
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
            
            addAnnotationsToScatterPlot(plot, atSelectedRecordIndex: idx)
        }*/
    }
    
    
    // MARK: - Gesture Recognizer Methods
    
    @IBAction func handleSingleTapGesture(recognizer: UITapGestureRecognizer) {
        
        if plots.count == 1 {
            plotLabelState = plotLabelState == 0 ? 3 : 0
        } else {
            plotLabelState++
            if plotLabelState > 3 { plotLabelState = 0 }
        }
        
        switch plotLabelState {
        case 0:
            addRemoveAnnotationsAllPlots()
        case 1:
            graph.plotAreaFrame.plotArea.removeAllAnnotations()
            addAnnotationsToPlot(plots[0])
        case 2:
            graph.plotAreaFrame.plotArea.removeAllAnnotations()
            addAnnotationsToPlot(plots[1])
        case 3:
            addRemoveAnnotationsAllPlots()
        default:
            break
        }
    }
    
    @IBAction func handleDoubleTapGesture(recognizer: UITapGestureRecognizer) {
        
        plotLabelState = plotLabelState == 0 ? 3 : 0
        addRemoveAnnotationsAllPlots()
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
    
    func addAnnotationsToScatterPlot(plot: CPTScatterPlot!, atSelectedRecordIndex idx: UInt) {
        
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
