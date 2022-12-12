import UIKit

class ADSlider: UISlider {

    @IBInspectable
    public var sliderTitle: String = "" {
        didSet{
            sliderTitleLabel.text = self.sliderTitle
        }
    }
    override var maximumValue: Float {
        didSet {
            self.addMarkLayers(rect: self.frame)
        }
    }
    
    public var markWidth: CGFloat = 2
    public var markPositions = [Int]()
    private let thumbWidth: Float = 38
    lazy var startingOffset: Float = 0 - (thumbWidth / 2) + 1
    lazy var endingOffset: Float = thumbWidth - 4
    public let trackHeight: CGFloat = 6
    
    let labelFont = UIFont(name: "Rubik-Light", size: 10)
    let leftImageView = UIImageView(image: UIImage(named: "purpleDot"))
    let rightImageView = UIImageView(image: UIImage(named: "blackDot"))
    
    lazy var sliderTitleLabel: ADLabel = {
        let label = ADLabel()
        label.textAlignment = .left
        label.backgroundColor = .clear
        label.textColor = .white
        label.font = labelFont
        return label
    }()
    
    lazy var valueLabel: ADLabel = {
        let label = ADLabel()
        label.frame = CGRect(x: 0.0, y: 0.0, width: 20, height: 19)
        label.textAlignment = .center
        label.backgroundColor = .clear
        label.textColor = .white
        label.font = labelFont
        return label
    }()
    
    lazy var minLabel: ADLabel = {
        let label = ADLabel()
        label.frame = CGRect(x: 0 - 4.5, y: self.frame.size.height - 5, width: 9, height: 19)
        label.textAlignment = .center
        label.backgroundColor = .clear
        label.textColor = .white
        label.font = labelFont
        return label
    }()
    
    lazy var maxLabel: ADLabel = {
        let label = ADLabel()
        label.frame = CGRect(x: 314 - 8, y: self.frame.size.height - 5, width: 26, height: 19)
        label.textAlignment = .center
        label.backgroundColor = .clear
        label.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.3)
        label.font = labelFont
        return label
    }()
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let point = CGPoint(x: bounds.minX, y: bounds.midY)
        return CGRect(origin: point, size: CGSize(width: bounds.width, height: trackHeight))
    }

    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        let newIndex = Int(value + 0.5)
        self.setValue(Float(newIndex), animated: false)
        prepareHaptics()
        let xTranslation =  startingOffset + (minimumValue + endingOffset) / maximumValue * value
        let frame = super.thumbRect(forBounds: bounds, trackRect: rect.applying(CGAffineTransform(translationX: CGFloat(xTranslation), y: 0)), value: value)
         self.xPositionOfThumbWithValue(position: frame, value: Int(value))
        leftImageView.frame = CGRect(x: rect.origin.x - 3, y: rect.origin.y, width: 6, height: 6)
        rightImageView.frame = CGRect(x: rect.size.width - 3, y: rect.origin.y, width: 6, height: 6)
        sliderTitleLabel.frame = CGRect(x: bounds.origin.x - 8, y: bounds.origin.y - 8 , width: 150, height: 19)
        return frame
    }
    
    func prepareHaptics() {
        let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .light)
        impactFeedbackgenerator.prepare()
        impactFeedbackgenerator.impactOccurred()
    }
    
    func xPositionOfThumbWithValue(position: CGRect, value: Int) {
        
        if value == Int(self.minimumValue) && position.origin.x == -20.0{
            minLabel.isHidden = true
        } else {
            minLabel.isHidden = false
        }
        
        if value == Int(self.maximumValue){
            maxLabel.isHidden = true
        } else {
            maxLabel.isHidden = false
        }
        
        valueLabel.text = "\(value)"
        
        if position.origin.x.isNaN == false {
            valueLabel.center = CGPoint(x: position.origin.x + 20, y: self.frame.size.height + 5)
        }
    }
    
    override func draw(_ rect: CGRect) {
        if (self.layer.sublayers!.count  < 4) {
           // self.addMarkLayers(rect: rect)
        }
    }
    
    
    func addMarkLayers(rect: CGRect) {
        let innerRect = rect.insetBy(dx: 1.0, dy: 10.0)
        UIGraphicsBeginImageContextWithOptions(innerRect.size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        markPositions.removeAll()
        // Selected side
        context?.setLineCap(.round)
        context?.setLineWidth(12.0)
        context?.move(to: CGPoint(x: 6, y: innerRect.height / 2))
        context?.addLine(to: CGPoint(x: innerRect.size.width - 10, y: innerRect.height / 2))
        context?.setStrokeColor(UIColor.clear.cgColor)
        context?.strokePath()
        let selectedSide = UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets: .zero)

        // Unselected side
        context?.setLineCap(.round)
        context?.setLineWidth(12.0)
        context?.move(to: CGPoint(x: 6, y: innerRect.height / 2))
        context?.addLine(to: CGPoint(x: innerRect.size.width - 10, y: innerRect.height / 2))
        context?.setStrokeColor(UIColor.clear.cgColor)
        context?.strokePath()
        let unselectedSide = UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets: .zero)
        markPositions += 1...Int(self.maximumValue)
        // Set trips on selected side
        selectedSide?.draw(at: CGPoint(x: 0, y: 0))
        for i in 0..<(markPositions.count - 1) {
            context?.setLineWidth(markWidth)
            var position = 0//markPositions[i] * Int(Int(innerRect.size.width) / Int(markPositions.count))
            if markPositions.count < 30 {
                position = (markPositions[i] * Int(Int(innerRect.size.width) / Int(markPositions.count))) + 3
            } else {
                position = markPositions[i] * Int(Int(innerRect.size.width) / Int(markPositions.count - 1))
            }
            context?.move(to: CGPoint(x: CGFloat(position), y: innerRect.height / 2 - 5))
            context?.addLine(to: CGPoint(x: CGFloat(position), y: innerRect.height / 2 + 5))
            context?.setStrokeColor(UIColor(red: 0.498, green: 0.047, blue: 0.898, alpha: 1).cgColor)
            context?.strokePath()
        }
        let selectedStripSide = UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets: .zero)

        // Set trips on unselected side
        unselectedSide?.draw(at: CGPoint(x: 0, y: 0))
        for i in 0..<(markPositions.count - 1) {
            context?.setLineWidth(markWidth)
            var position = 0//markPositions[i] * Int(Int(innerRect.size.width) / Int(markPositions.count))
            if markPositions.count < 30 {
                position = (markPositions[i] * Int(Int(innerRect.size.width) / Int(markPositions.count))) + 3
            } else {
                position = markPositions[i] * Int(Int(innerRect.size.width) / Int(markPositions.count - 1))
            }
            context?.move(to: CGPoint(x: CGFloat(position), y: innerRect.height / 2 - 5))
            context?.addLine(to: CGPoint(x: CGFloat(position), y: innerRect.height / 2 + 5))
            context?.setStrokeColor(UIColor(red: 0.263, green: 0.255, blue: 0.282, alpha: 1).cgColor)
            context?.strokePath()
        }
        let unselectedStripSide = UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets: .zero)

        UIGraphicsEndImageContext()

        setMinimumTrackImage(selectedStripSide, for: .normal)
        setMaximumTrackImage(unselectedStripSide, for: .normal)
        setThumbImage(UIImage(named: "whiteDot"), for: .normal)
        removeCustomizeView()
        customizeView()
    }
    
    func removeCustomizeView() {
        minLabel.removeFromSuperview()
        maxLabel.removeFromSuperview()
        sliderTitleLabel.removeFromSuperview()
        valueLabel.removeFromSuperview()
        leftImageView.removeFromSuperview()
        rightImageView.removeFromSuperview()
    }
    
    func customizeView() {
        self.addSubview(minLabel)
        self.addSubview(maxLabel)
        self.addSubview(sliderTitleLabel)
        self.addSubview(valueLabel)
        self.addSubview(leftImageView)
        self.addSubview(rightImageView)
        self.sendSubviewToBack(leftImageView)
        self.sendSubviewToBack(rightImageView)
        
        minLabel.text = "\(Int(self.minimumValue))"
        maxLabel.text = "\(Int(self.maximumValue))"
        
        sliderTitleLabel.letterSpace = 1.2
        maxLabel.letterSpace = 1.2
        minLabel.letterSpace = 1.2
        valueLabel.letterSpace = 1.2
    }
}

//---------------------------------------------------------------------------------------------------------------------------------------------//
//--------------------------------------------------------------CUSTOM LABEL CLASS-------------------------------------------------------------//
class ADLabel: UILabel {
    var letterSpaces: CGFloat {
        set {
            let attributedString: NSMutableAttributedString!
            if let currentAttrString = attributedText {
                attributedString = NSMutableAttributedString(attributedString: currentAttrString)
            } else {
                attributedString = NSMutableAttributedString(string: text ?? "")
                text = nil
            }

            attributedString.addAttribute(NSAttributedString.Key.kern, value: newValue, range: NSRange(location: 0, length: attributedString.length))
            attributedText = attributedString
        }
        
        get {
            if let currentLetterSpace = attributedText?.attribute(NSAttributedString.Key.kern, at: 0, effectiveRange: .none) as? CGFloat {
                return currentLetterSpace
            } else {
                return 0
            }
        }
    }
}
