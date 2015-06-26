import UIKit


// MARK: Constants
let pi: CGFloat = CGFloat(M_PI)
let startAnlge: CGFloat = CGFloat(M_PI_2)
let textFont: UIFont = UIFont.boldSystemFontOfSize(32)
let textColor: UIColor = UIColor.whiteColor()
let NotFound: Int = -1

func radiansToDegree(radian: CGFloat) -> CGFloat {
    return radian * 180 / pi
}


// MARK: Data Soucre For Pie Graph
/// Data Source for Pie Graph
protocol PieGraphDataSouce : NSObjectProtocol {
    
    /// Number of sectors required to be shown in the PieGraph
    ///
    /// :returns: Int value. Number of sectors in the PieGragh
    func numberOfSectors() -> Int
    
    /// Details for the sector at the index. Details are title, value, sector color, title color
    ///
    /// :param: Int index for ths sector
    /// :returns: A tuple with iTitle: String, iValue: CGFloat, iSectorColor: UIColor, iTitleColor: UIColor
    func detailsForSector(iIndex: Int) -> (iTitle: String, iValue: CGFloat, iSectorColor: UIColor, iTitleColor: UIColor)
    
    /// Whether it has priority sector or not. By default false.
    ///
    /// :returns: Bool value
    func hasPrioritySector() -> Bool
    
    /// Details for the priority sector at the index. Details are title, value, sector color, title color, between the indexes
    ///
    /// :returns: A tuple with iTitle: String, iValues: [CGFloat], iSectorColor: UIColor, iTitleColor: UIColor, iBetweenIndex: Int, iToIndex: Int
    func detailsForPrioritySector() -> (iTitle: String, iValues: [CGFloat], iSectorColor: UIColor, iTitleColor: UIColor, iBetweenIndex: Int, iToIndex: Int)
}


// MARK: Delegate For Pie Graph
/// Delegate for Pie Graph
protocol PieGraphDelegate : NSObjectProtocol {
    
    ///  Gives the selected sector details index and is priority sector or not.
    ///
    /// :param: Int index of the sector. If the selected sector is only priority sector, index will be NotFound.
    /// :param: Bool whether the selected sector is priority sector or not.
    func didSelectTheSector (iIndex: Int, isPriority: Bool)
}


// MARK: Sector Class
/// Class for Sector
private class Sector: NSObject{
    var title: String?
    var value: CGFloat = 0
    var color: UIColor?
    var textColor: UIColor?
    var sectorStartAngle : CGFloat = 0
    var sectorEndAngle : CGFloat = 0
    var isPrioritySector: Bool = false
    var values: [CGFloat] = []
    
    ///
    init(iTitle: String, iValue: CGFloat, iColor: UIColor, iTextColor: UIColor) {
        super.init()
        title = iTitle
        value = iValue
        color = iColor
        textColor = iTextColor
    }
}


// MARK: Pie Graph View
/// Class for Pie Graph view
@IBDesignable class PieGraphView: UIView {
    
    // MARK: Public Properties
    /// Data Source for the graph view
    var dataSource: PieGraphDataSouce?
    /// Delegate for the graph view
    var delegate: PieGraphDelegate?
    var innerRadius : CGFloat {
        set (newInnerRadius){
            innerCutRadius = newInnerRadius
        }
        get {
            if innerCutRadius < 0 {
                return 0
            } else if innerCutRadius > radius{
                return radius * 0.9
            } else {
                return innerCutRadius
            }
        }
    }
    
    // MARK: Private Properties
    private var graphCenter: CGPoint {
        get {
            return CGPointMake(bounds.width/2, bounds.height/2)
        }
    }
    
    private var radius : CGFloat {
        get {
            return min(bounds.width, bounds.height) / 2.0
        }
    }
    
    private var outerRadius : CGFloat {
        get {
            return radius * 0.8
        }
    }
    
    private var prioritySectorRadius : CGFloat {
        get {
            return radius * 0.95
        }
    }
    
    private var titleRadius: CGFloat {
        get {
            return (outerRadius + innerRadius + textFont.pointSize / 2) / 2.0
        }
    }
    
    private var hasPrioritySector: Bool = false
    private var innerCutRadius: CGFloat = 0
    private var totalValue: CGFloat = 0
    private var sectors: [Sector] = []
    private var prioritySector: Sector?
    private var priorityStartIndex: Int = 0
    private var priorityEndIndex: Int = 0
    private var sectorLayers: [CALayer] = []
    
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    
    // MARK: Drawing in the View
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
        self.loadData()
        
        var sectorStartAngle = startAnlge
        
        for aSector in sectors {
            var sectorAngle : CGFloat = anlgeForSectorLength(aSector.value)
            aSector.sectorStartAngle = sectorStartAngle
            aSector.sectorEndAngle = sectorStartAngle + sectorAngle
            self.drawSector(aSector)
            sectorStartAngle += sectorAngle
        }
        
        for aSector in sectors {
            self.drawTextInArc(aSector)
        }
        
        if hasPrioritySector {
            var sectorRangeStart: CGFloat = 0
            var sectorRangeEnd: CGFloat = 0
            
            var index : Int = 0
            var i: Int = 0
            for index = priorityStartIndex, i = 0; (index < sectors.count && index <= priorityEndIndex && i < prioritySector?.values.count) ; ++index, ++i {
                var aSector: Sector = sectors[index]
                var sectorAngleComponent = anlgeForSectorLength(prioritySector!.values[i])
                
                if priorityStartIndex == priorityEndIndex && index == priorityStartIndex{
                    if sectorAngleComponent < (aSector.sectorEndAngle - aSector.sectorStartAngle) {
                        var halfAngle = (aSector.sectorStartAngle + aSector.sectorEndAngle) / 2
                        prioritySector?.sectorStartAngle = halfAngle - sectorAngleComponent / 2
                        prioritySector?.sectorEndAngle = halfAngle + sectorAngleComponent / 2
                        break
                    } else {
                        prioritySector?.sectorStartAngle = aSector.sectorStartAngle
                        prioritySector?.sectorEndAngle = aSector.sectorEndAngle
                        break
                    }
                } else {
                    if index == priorityStartIndex {
                        var sectorStartAngle = aSector.sectorEndAngle - sectorAngleComponent
                        prioritySector?.sectorStartAngle = (sectorStartAngle > aSector.sectorStartAngle) ? sectorStartAngle : aSector.sectorStartAngle
                    }
                    
                    if index == priorityEndIndex {
                        var sectorEndAngle = aSector.sectorStartAngle + sectorAngleComponent
                        prioritySector?.sectorEndAngle = (sectorEndAngle < aSector.sectorEndAngle) ? sectorEndAngle : aSector.sectorEndAngle
                    }
                }
            }

            self.drawGradientSector(prioritySector!)
            self.drawTextInArc(prioritySector!)
        }
    }
    
    
    private func drawSector(iSector: Sector) {
        // Create a path for the sector
        // Create the outer arc path
        var sectorPath : UIBezierPath = UIBezierPath (arcCenter: graphCenter, radius: outerRadius, startAngle: iSector.sectorStartAngle, endAngle: iSector.sectorEndAngle, clockwise: true)
        // Add the inner arc path
        sectorPath.addArcWithCenter(graphCenter, radius: innerRadius, startAngle: iSector.sectorEndAngle, endAngle: iSector.sectorStartAngle, clockwise: false)
        // Close the path to fill the path with color
        sectorPath.closePath()
        // Set the fill color
        iSector.color!.setFill()
        // Fill the color
        sectorPath.fill()
        
        // Create a layer with the shape path
        var sectorLayer: CAShapeLayer = CAShapeLayer()
        sectorLayer.path = sectorPath.CGPath
        // Fill the color in the layer
        sectorLayer.fillColor = UIColor.clearColor().CGColor
        //  Add the new shapelayer to the layer array
        sectorLayers.append(sectorLayer)
    }
    
    
    private func drawTextInArc(iSector: Sector) {
        var title : String = iSector.title!
        var titleFont = textFont
        if iSector.isPrioritySector {
            titleFont = textFont.fontWithSize(textFont.pointSize - 6)
        }
        // Creating attributes for the title with font and text color
        let textAttributes : [NSObject:AnyObject] = [NSFontAttributeName : titleFont, NSForegroundColorAttributeName : iSector.textColor!]
        let alphaCount = count(title)
        
        // Calculating the size of the text
        var titleSize = title.sizeWithAttributes(textAttributes)
        
        var textRadius = titleRadius * 2
        if iSector.isPrioritySector {
            textRadius = (prioritySectorRadius - textFont.pointSize * 0.25) * 2
        }
        // Calculating the lenght of the arc with the radius of the text. So that it is used for terminating the text.
        var sectorArcLength = textRadius * (iSector.sectorEndAngle - iSector.sectorStartAngle)
        
        // Calculate the angle for the required for the text. For making the text center in the sector
        var angleForText = (titleSize.width * 1.5)/textRadius
        // Calculate the text start angle.
        var titleStartAngle = ((iSector.sectorStartAngle + iSector.sectorEndAngle) / 2.0) + (pi/2) - (angleForText)/2
        
        if angleForText > (iSector.sectorEndAngle - iSector.sectorStartAngle) {
            titleStartAngle = iSector.sectorStartAngle + (pi/2)
        }
        
        // Start drawing
        var textFrame = CGRectMake(0, 0, bounds.width * 2, bounds.height * 2)
        var textCenter = CGPointMake(textFrame.width/2, textFrame.height/2)
        UIGraphicsBeginImageContext(textFrame.size);
        var aContext = UIGraphicsGetCurrentContext();
        
        // Start by adjusting the context origin
        // This affects all subsequent operations
        CGContextTranslateCTM(aContext, textCenter.x, textCenter.y);
        
        // Iterate through the alphabet
        var consumedSize = CGFloat(0)
        
        for var i = 0; i < alphaCount; i++ {
            // Retrieve the letter and measure its display size
            var letter = String(title[advance(title.startIndex, i)]) as NSString
            var letterSize = letter.sizeWithAttributes(textAttributes)
            
            if (consumedSize + letterSize.width) > sectorArcLength {
                letter = "."
                letterSize = letter.sizeWithAttributes(textAttributes)
            }
            
            // Calculate the current angular offset
            consumedSize += letterSize.width / 1.5
            var percent : CGFloat = consumedSize / textRadius
            var theta : CGFloat = titleStartAngle + percent
            consumedSize += letterSize.width / 1.5
            
            // Terminating the loop if the consumed length exceeds the arc length
            if consumedSize > sectorArcLength { break }
            
            // Encapsulate each stage of the drawing
            CGContextSaveGState(aContext)
            
            // Rotate the context
            CGContextRotateCTM(aContext, theta)
            
            // Translate up to the edge of the radius and move left by
            // half the letter width. The height translation is negative
            // as this drawing sequence uses the UIKit coordinate system.
            // Transformations that move up go to lower y values.
            CGContextTranslateCTM(aContext, -letterSize.width / 2, -textRadius)
            
            // Draw the letter and pop the transform state
            letter .drawAtPoint(CGPointZero, withAttributes: textAttributes)
            CGContextRestoreGState(aContext)
        }
        
        // Retrieve and return the image
        var image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        //Add the image to a layer and add to view layer
        var imageLayer = CALayer()
        imageLayer.frame = bounds
        imageLayer.contents = image.CGImage
        self.layer.addSublayer(imageLayer)
        
    }
    
    
    private func drawGradientSector(iSector: Sector) {
        let context = UIGraphicsGetCurrentContext()
        let colors = [UIColor.clearColor().CGColor, iSector.color!.CGColor]
        let colorLocations : [CGFloat] = [0.0, 1.0]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradientCreateWithColors(colorSpace, colors, colorLocations)
        
        
        var sectorPath : UIBezierPath = UIBezierPath (arcCenter: graphCenter, radius: prioritySectorRadius, startAngle: iSector.sectorStartAngle, endAngle: iSector.sectorEndAngle, clockwise: true)
        sectorPath.addLineToPoint(graphCenter)
        sectorPath.closePath()
        CGContextSaveGState(context)
        sectorPath.addClip()
        CGContextDrawRadialGradient(context, gradient, graphCenter, 0.1*radius, graphCenter, radius, 0)
        CGContextRestoreGState(context)
        
        // Create a layer with the shape path
        var sectorLayer: CAShapeLayer = CAShapeLayer()
        sectorLayer.path = sectorPath.CGPath
        // Fill the color in the layer
        sectorLayer.fillColor = UIColor.clearColor().CGColor
        //  Add the new shapelayer to the layer array
        sectorLayers.append(sectorLayer)
    }
    
    
    // MARK: Loading Data
    func loadData() {
        // Check the existance of the data soucre
        if (dataSource != nil) {
            var numberofSectors = dataSource!.numberOfSectors()
            hasPrioritySector = dataSource!.hasPrioritySector()
            
            for var index = 0; index < numberofSectors; index++ {
                var sectorDetails = dataSource?.detailsForSector(index)
                totalValue += sectorDetails!.iValue
                var sector: Sector = Sector(iTitle: sectorDetails!.iTitle, iValue: sectorDetails!.iValue, iColor: sectorDetails!.iSectorColor, iTextColor: sectorDetails!.iTitleColor)
                sectors.append(sector)
            }
            
            if hasPrioritySector {
                var prioritySectorDetails = dataSource?.detailsForPrioritySector()
                prioritySector = Sector(iTitle: prioritySectorDetails!.iTitle, iValue: 0, iColor: prioritySectorDetails!.iSectorColor, iTextColor: prioritySectorDetails!.iTitleColor)
                prioritySector?.values = prioritySectorDetails!.iValues
                prioritySector?.isPrioritySector = true
                priorityStartIndex = prioritySectorDetails!.iBetweenIndex
                priorityEndIndex = prioritySectorDetails!.iToIndex
            }
            
            
        }
    }
    
    func relaodData() {
        sectors.removeAll(keepCapacity: false)
        sectorLayers.removeAll(keepCapacity: false)
        hasPrioritySector = false
        totalValue = 0
        self.layer.sublayers.removeAll(keepCapacity: false)
        self.setNeedsDisplay()
    }
    
    
    // MARK: Touch event
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        var touchesSet = touches as NSSet
        var touch: UITouch = touchesSet.anyObject() as! UITouch
        var point = touch.locationInView(self)
        var sectorIndex = self.getCurrentSelectedOnTouch(point)
        if self.delegate != nil && sectorIndex.index >= 0 {
            if sectorIndex.index >= sectors.count {
                self.delegate?.didSelectTheSector(NotFound, isPriority: sectorIndex.isPriority)
            } else {
                self.delegate?.didSelectTheSector(sectorIndex.index, isPriority: sectorIndex.isPriority)
            }
            
        }
        
    }
    
    
    private func getCurrentSelectedOnTouch(iPoint: CGPoint) -> (index: Int, isPriority: Bool) {
        var sectorIndex: Int = -1
        var transform: CGAffineTransform = CGAffineTransformIdentity;
        var parentLayer: CALayer = self.layer
        var pieLayers: NSArray = sectorLayers as NSArray

        pieLayers.enumerateObjectsUsingBlock { (id obj, Int index , Bool found) -> Void in
            if obj.isKindOfClass(CAShapeLayer) {
                var sectorLayer: CAShapeLayer = obj as! CAShapeLayer
                
                if CGPathContainsPoint(sectorLayer.path, &transform, iPoint, false) && sectorIndex == -1 {
                    sectorIndex = index
                }
            }
        }
        
        var isPriority = false
        if hasPrioritySector {
            var sectorLayer: CAShapeLayer = pieLayers.lastObject as! CAShapeLayer
            
            if CGPathContainsPoint(sectorLayer.path, &transform, iPoint, false) {
                isPriority = true
            }
        }
        
        return (sectorIndex, isPriority)
    }
    
    
    //MARK: internal functions
    private func anlgeForSectorLength(length: CGFloat) -> CGFloat {
        return 2 * pi * length / totalValue
    }
}
