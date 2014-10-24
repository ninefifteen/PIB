//
//  GraphPageViewController.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/21/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

import UIKit

class GraphPageViewController: PageContentViewController, CPTPlotDataSource {
    
    
    // MARK: - Properties

    @IBOutlet weak var graphView: CPTGraphHostingView!
    var graphDataDictionaryArray = Array<Array<Dictionary<String,Double>>>()
    var yAxisMin: Double = 0.0
    var yAxisMax: Double = 0.0
    var yAxisInterval: Double = 0.0
    var yAxisRange: Double = 0.0
    let numberOfYAxisIntervals: Double = 7.0
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Temporary code for testing charts.
        /*let totalRevenueString: String = "[{\"Year\":\"2013\",\"Value\":\"14109.0\"},{\"Year\":\"2012\",\"Value\":\"9508.0\"},{\"Year\":\"2011\",\"Value\":\"10249.0\"}]"
        let netIncomeString: String = "[{\"Year\":\"2013\",\"Value\":\"637.0\"},{\"Year\":\"2012\",\"Value\":\"-4033.0\"},{\"Year\":\"2011\",\"Value\":\"222.0\"}]"
        company.totalRevenue = totalRevenueString
        company.netIncome = netIncomeString*/
        
        switch pageIndex {
            
        case 1:
            graphDataDictionaryArray.append(dictionaryArrayFromDataString(company.totalRevenue))
            graphDataDictionaryArray.append(dictionaryArrayFromDataString(company.netIncome))
            calculateyYAxisMinMaxAndIntervalForDataInArray(graphDataDictionaryArray)
            configureRevenueIncomeMarginGraph()
            
        case 2:
            graphDataDictionaryArray.append(dictionaryArrayFromDataString(company.grossProfit))
            configureGrossMarginGraph()
        
        case 3:
            graphDataDictionaryArray.append(dictionaryArrayFromDataString(company.rAndD))
            configureRAndDGraph()
            
        case 4:
            graphDataDictionaryArray.append(dictionaryArrayFromDataString(company.sgAndA))
            configureSGAndAGraph()
            
        default:
            break
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Graph Configure Methods
    
    func configureRevenueIncomeMarginGraph() {
        
        let graph = CPTXYGraph()
        graph.applyTheme(CPTTheme(named: kCPTPlainWhiteTheme))
        
        // Border
        graph.plotAreaFrame.borderLineStyle = nil
        graph.plotAreaFrame.cornerRadius = 0.0
        graph.plotAreaFrame.masksToBorder = false
        
        // Paddings
        graph.paddingLeft = 0.0
        graph.paddingRight = 0.0
        graph.paddingTop = 0.0
        graph.paddingBottom = 0.0
        
        graph.plotAreaFrame.paddingLeft   = 70.0
        graph.plotAreaFrame.paddingTop    = 20.0
        graph.plotAreaFrame.paddingRight  = 20.0
        graph.plotAreaFrame.paddingBottom = 60.0
        
        // Graph Title
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .Center
        
        let lineOne = "Graph Title"
        let lineTwo = "Subtitle"
        
        let line1Font = UIFont(name: "Helvetica-Bold", size: 16.0)
        let line2Font = UIFont(name: "Helvetica", size: 12.0)
        
        let graphTitle = NSMutableAttributedString(string: lineOne + "\n" + lineTwo)
        
        let titleRange1 = NSRange(location: 0, length: lineOne.utf16Count)
        let titleRange2 = NSRange(location: lineOne.utf16Count, length: lineTwo.utf16Count + 1)
        
        graphTitle.addAttribute(NSForegroundColorAttributeName, value: UIColor.blackColor(), range: titleRange1)
        graphTitle.addAttribute(NSForegroundColorAttributeName, value: UIColor.grayColor(), range: titleRange2)
        graphTitle.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSRange(location: 0, length: graphTitle.length))
        graphTitle.addAttribute(NSFontAttributeName, value: line1Font!, range: titleRange1)
        graphTitle.addAttribute(NSFontAttributeName, value: line2Font!, range: titleRange2)
        
        graph.attributedTitle = graphTitle
        
        graph.titleDisplacement = CGPoint(x: 0.0, y: -20.0)
        graph.titlePlotAreaFrameAnchor = .Top
        
        // Plot Space
        let plotSpace = graph.defaultPlotSpace as CPTXYPlotSpace
        plotSpace.yRange = CPTPlotRange(location: yAxisMin, length: yAxisRange)
        plotSpace.xRange = CPTPlotRange(location: 0.0, length: 4.0)
        
        let axisSet = graph.axisSet as CPTXYAxisSet
        
        let x = axisSet.xAxis
        x.axisLineStyle = nil
        x.majorTickLineStyle = nil
        x.minorTickLineStyle = nil
        x.majorIntervalLength = 1.0
        x.orthogonalPosition = yAxisMin
        x.title = "X Axis"
        x.titleLocation = 1.5
        x.titleOffset = 35
        
        // Custom Labels
        //x.labelRotation = CGFloat(M_PI_4)
        x.labelingPolicy = .None
        
        let customTickLocations = [1.0, 2.0, 3.0]
        
        var xAxisLabels = Array<String>()
        
        for (index, value) in enumerate(graphDataDictionaryArray[0]) {
            let year: Int = Int(value["Year"]!)
            let label: String = "\(year)"
            xAxisLabels.append(label)
        }
        
        var labelLocation = 0
        let customLabels = NSMutableSet(capacity: xAxisLabels.count)
        for tickLocation in customTickLocations {
            let newLabel = CPTAxisLabel(text: xAxisLabels[labelLocation++], textStyle: x.labelTextStyle)
            newLabel.tickLocation = tickLocation
            newLabel.offset = x.labelOffset + x.majorTickLength
            //newLabel.rotation = CGFloat(M_PI_4)
            customLabels.addObject(newLabel)
        }
        
        x.axisLabels = customLabels
        
        // Create y-axis major tick line style.
        var yMajorGridLineStyle = CPTMutableLineStyle()
        yMajorGridLineStyle.lineWidth = 1.0
        yMajorGridLineStyle.lineColor = CPTColor.lightGrayColor()
        
        let y = axisSet.yAxis
        y.axisLineStyle = nil
        y.majorTickLineStyle = nil
        y.minorTickLineStyle = nil
        y.majorGridLineStyle = yMajorGridLineStyle
        y.majorIntervalLength = yAxisInterval
        y.orthogonalPosition = 0.0
        y.title = "Y Axis"
        y.titleOffset = 45.0
        y.titleLocation = yAxisMin + yAxisRange / 2.0
        
        // Create bar line style.
        var barLineStyle = CPTMutableLineStyle()
        barLineStyle.lineWidth = 1.0
        barLineStyle.lineColor = CPTColor.blackColor()
        
        // First Bar Plot
        let revenueBarPlot = CPTBarPlot()
        revenueBarPlot.barsAreHorizontal = false
        revenueBarPlot.lineStyle = barLineStyle
        revenueBarPlot.fill = CPTFill(color: CPTColor.greenColor())
        revenueBarPlot.barWidth = 0.3
        revenueBarPlot.baseValue = 0.0
        revenueBarPlot.barOffset = -0.17
        revenueBarPlot.identifier = "RevenueBarPlot"
        revenueBarPlot.dataSource = self
        graph.addPlot(revenueBarPlot, toPlotSpace:plotSpace)
        
        // Second bar plot
        let netIncomeBarPlot = CPTBarPlot()
        netIncomeBarPlot.barsAreHorizontal = false
        netIncomeBarPlot.lineStyle = barLineStyle
        netIncomeBarPlot.fill = CPTFill(color: CPTColor.yellowColor())
        netIncomeBarPlot.barWidth = 0.3
        netIncomeBarPlot.baseValue = 0.0
        netIncomeBarPlot.barOffset = 0.17
        netIncomeBarPlot.barCornerRadius = 2.0
        netIncomeBarPlot.identifier = "NetIncomeBarPlot"
        netIncomeBarPlot.dataSource = self
        graph.addPlot(netIncomeBarPlot, toPlotSpace:plotSpace)
        
        self.graphView.hostedGraph = graph
    }
    
    func configureGrossMarginGraph() {
        
        //
    }
    
    func configureRAndDGraph() {
        
        //
    }
    
    func configureSGAndAGraph() {
        
        //
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
    
    func calculateyYAxisMinMaxAndIntervalForDataInArray(dataArray: Array<Array<Dictionary<String,Double>>>) {
        
        var minY: Double = minimumValueInDataArray(dataArray)
        var maxY: Double = maximumValueInDataArray(dataArray)
        let range: Double = (maxY - minY) * 1.15
        
        var interval: Double = range / numberOfYAxisIntervals
        interval = multipleOfFiveCeilNumber(interval, toSignificantFigures: 2)
        
        if minY < 0.0 {
            var intervalMultiple = (minY * 1.05) / interval
            intervalMultiple = floor(intervalMultiple)
            minY = intervalMultiple * interval
        }
        
        maxY = minY + numberOfYAxisIntervals * interval
        
        yAxisMin = minY / 1000.0
        yAxisMax = maxY / 1000.0
        yAxisInterval = interval / 1000.0
        yAxisRange = numberOfYAxisIntervals * interval / 1000.0
    }
    
    func minimumValueInDataArray(dataArray: Array<Array<Dictionary<String,Double>>>) -> Double {
        
        var minimumValue: Double = 0.0
        
        for (index, dataPoint) in enumerate(graphDataDictionaryArray[0]) {
            let currentValue: Double = Double(dataPoint["Value"]!)
            if currentValue < minimumValue { minimumValue = currentValue }
        }
        
        if graphDataDictionaryArray.count > 1 {
            for (index, dataPoint) in enumerate(graphDataDictionaryArray[1]) {
                let currentValue: Double = Double(dataPoint["Value"]!)
                if currentValue < minimumValue { minimumValue = currentValue }
            }
        }
        
        return minimumValue
    }
    
    func maximumValueInDataArray(dataArray: Array<Array<Dictionary<String,Double>>>) -> Double {
        
        var maximumValue: Double = 0.0
        
        for (index, dataPoint) in enumerate(graphDataDictionaryArray[0]) {
            let currentValue: Double = Double(dataPoint["Value"]!)
            if currentValue > maximumValue { maximumValue = currentValue }
        }
        
        if graphDataDictionaryArray.count > 1 {
            for (index, dataPoint) in enumerate(graphDataDictionaryArray[1]) {
                let currentValue: Double = Double(dataPoint["Value"]!)
                if currentValue > maximumValue { maximumValue = currentValue }
            }
        }
        
        return maximumValue
    }
    
    func dictionaryArrayFromDataString(dataString: String) -> Array<Dictionary<String,Double>> {
        
        var dictionaryArray = Array<Dictionary<String,Double>>()
        
        let data = (dataString as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        let json = JSON(data: data!)
        
        for (index: String, subJson: JSON) in json {
            
            let value: Double = subJson["Value"].doubleValue
            let year: Double = subJson["Year"].doubleValue
            let dictionary: Dictionary<String,Double> = ["Year": year, "Value": value]
            dictionaryArray.append(dictionary)
        }
        
        // Sort in ascending order by year.
        dictionaryArray.sort({ $0["Year"] < $1["Year"] })
        
        return dictionaryArray
    }
    
    
    // MARK: - CPTPlotDataSource
    
    func numberOfRecordsForPlot(plot: CPTPlot!) -> UInt {
        if graphDataDictionaryArray.count > 0 {
            return UInt(graphDataDictionaryArray[0].count)
        } else {
            return 0
        }
        
    }
    
    func numberForPlot(plot: CPTPlot!, field: UInt, recordIndex: UInt) -> NSNumber! {
        
        switch pageIndex {
            
        case 1:
            
            switch CPTBarPlotField(rawValue: Int(field))! {
            case .BarLocation:
                return recordIndex + 1 as NSNumber
                
            case .BarTip:
                
                let plotID = plot.identifier as String
                
                if plotID == "RevenueBarPlot" {
                    let value: Double = graphDataDictionaryArray[0][Int(recordIndex)]["Value"]! / 1000.0
                    return NSNumber(double: value)
                } else if plotID == "NetIncomeBarPlot" {
                    let value: Double = graphDataDictionaryArray[1][Int(recordIndex)]["Value"]! / 1000.0
                    return NSNumber(double: value)
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
