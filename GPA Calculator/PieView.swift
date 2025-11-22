//
//  PieView.swift
//  GPA Calculator
//
//  Created by Will on 11/25/25.
//
//  - creates a nice pie (or donut) view at the bottom.
//  - animates!
//  - always shows text upright
//  - gets the subjects right upon update
//

import UIKit

// MARK: - helpers

// animate the color
extension UIColor {
    func darker(by percentage: CGFloat = 0.3) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if self.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return UIColor(hue: h, saturation: s, brightness: max(b - percentage, 0.0), alpha: a)
        }
        return self
    }
    
    static func interpolate(from: UIColor, to: UIColor, progress: CGFloat) -> UIColor {
        let p = min(max(progress, 0), 1)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        if from.getRed(&r1, green: &g1, blue: &b1, alpha: &a1) &&
            to.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) {
            let r = r1 + (r2 - r1) * p
            let g = g1 + (g2 - g1) * p
            let b = b1 + (b2 - b1) * p
            let a = a1 + (a2 - a1) * p
            return UIColor(red: r, green: g, blue: b, alpha: a)
        }
        return to
    }
}

extension UIFont {
    func rounded() -> UIFont {
        if let descriptor = self.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: self.pointSize)
        }
        return self
    }
}

extension String {
    func truncate(toWidth width: CGFloat, font: UIFont) -> String {
        let nsString = self as NSString
        let ellipses = "..."
        if nsString.size(withAttributes: [.font: font]).width <= width { return self }
        var len = self.count
        while len > 0 {
            let sub = nsString.substring(to: len) + ellipses
            if (sub as NSString).size(withAttributes: [.font: font]).width <= width {
                return sub
            }
            len -= 1
        }
        return ellipses
    }
}

class PieChartView: UIView {
    
    // MARK: - props
    
    private var targetSlices: [PieSlice] = []
    private var currentSlices: [PieSlice] = []
    private var selectionStates: [CGFloat] = []
    
    var slices: [PieSlice] = [] {
        didSet {
            targetSlices = slices
            
            // 1. Handle selection state array sizing
            if selectionStates.count != targetSlices.count {
                selectionStates = Array(repeating: 0.0, count: targetSlices.count)
            }
            
            // 2. Handle Slice Transition
            if currentSlices.isEmpty {
                // Brand new data (or after reset).
                // Create "zero value" slices so we can animate them growing out.
                currentSlices = targetSlices.map {
                    PieSlice(value: 0, color: $0.color, label: $0.label, subGPA: $0.subGPA)
                }
            } else if currentSlices.count != targetSlices.count {
                // Structure changed (e.g. different number of subjects).
                // Snap to zero for a frame then grow to target, or just snap to target.
                // For smoothness, we'll reset to zero-values of the NEW structure, then animate up.
                currentSlices = targetSlices.map {
                    PieSlice(value: 0, color: $0.color, label: $0.label, subGPA: $0.subGPA)
                }
            } else {
                // Same number of slices, just update metadata (labels/colors) immediately
                // so the animation loop only handles the 'value' interpolation.
                for i in 0..<currentSlices.count {
                    currentSlices[i].label = targetSlices[i].label
                    currentSlices[i].color = targetSlices[i].color
                    currentSlices[i].subGPA = targetSlices[i].subGPA
                }
            }
            
            startAnimation()
            updateCenterLabel()
        }
    }
    
    var totalGPA: Double = 0.0 {
        didSet { updateCenterLabel() }
    }
    
    private var selectedSliceIndex: Int? = nil {
        didSet { startAnimation() }
    }
    
    private var displayLink: CADisplayLink?
    
    private let ringWidth: CGFloat = 60.0
    private let selectedGrowth: CGFloat = 15.0
    
    private let centerLabel: UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    // MARK: - init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        isUserInteractionEnabled = true
        
        // make it not stretch when rotating screen
        contentMode = .redraw
        
        addSubview(centerLabel)
        NSLayoutConstraint.activate([
            centerLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            centerLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.55)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    // reset everything when view reloads
    func reset() {
        targetSlices = []
        currentSlices = []
        selectionStates = []
        selectedSliceIndex = nil
        displayLink?.invalidate()
        displayLink = nil
        setNeedsDisplay()
    }
    
    // MARK: - animate
    
    private func startAnimation() {
        if displayLink == nil {
            displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink))
            displayLink?.add(to: .main, forMode: .common)
        }
    }
    
    @objc private func handleDisplayLink() {
        var needsRedraw = false
        let lerpSpeed: CGFloat = 0.15
    
        if currentSlices.count == targetSlices.count {
            for i in 0..<targetSlices.count {
                let current = currentSlices[i].value
                let target = targetSlices[i].value
                let diff = target - current
                
                if abs(diff) > 0.001 {
                    currentSlices[i].value += diff * Double(lerpSpeed)
                    needsRedraw = true
                } else {
                    currentSlices[i].value = target
                }
            }
        }
        
        if selectionStates.count == currentSlices.count {
            for i in 0..<selectionStates.count {
                let targetState: CGFloat = (i == selectedSliceIndex) ? 1.0 : 0.0
                let current = selectionStates[i]
                let diff = targetState - current
                
                if abs(diff) > 0.001 {
                    selectionStates[i] += diff * lerpSpeed
                    needsRedraw = true
                } else {
                    selectionStates[i] = targetState
                }
            }
        }
        
        if needsRedraw {
            setNeedsDisplay()
        } else {
            displayLink?.invalidate()
            displayLink = nil
        }
    }
    
    // MARK: - draw
    
    override func draw(_ rect: CGRect) {
        guard !currentSlices.isEmpty else { return }
        
        let total = currentSlices.reduce(0) { $0 + $1.value }
        
        // If total is 0, we can't draw arcs.
        if total < 0.001 { return }
        
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        // Dynamic radius based on current bounds (fixes layout issues)
        let radius = (min(rect.width, rect.height) / 2) - (selectedGrowth + 10)
        
        var startAngle: CGFloat = -CGFloat.pi / 2
        let safeTotal = total
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        for (i, slice) in currentSlices.enumerated() {
            let sweepAngle = CGFloat(2 * .pi * (slice.value / safeTotal))
            let endAngle = startAngle + sweepAngle
            let midAngle = startAngle + (sweepAngle / 2)
            
            // Safety check for array bounds during rapid updates
            let selectFactor = (i < selectionStates.count) ? selectionStates[i] : 0.0
            
            let currentLineWidth = ringWidth + (selectedGrowth * selectFactor)
            let path = UIBezierPath(arcCenter: center,
                                    radius: radius - (ringWidth / 2),
                                    startAngle: startAngle,
                                    endAngle: endAngle,
                                    clockwise: true)
            
            path.lineWidth = currentLineWidth
            
            let displayColor = slice.color.darker(by: 0.3 * selectFactor)
            displayColor.setStroke()
            path.lineCapStyle = .butt
            path.stroke()
            
            // Text drawing logic
            if sweepAngle > 0.12 {
                let fontSize: CGFloat = 12
                let font = UIFont.systemFont(ofSize: fontSize, weight: .bold).rounded()
                
                let unselectedTextColor = slice.color.darker(by: 0.5)
                let selectedTextColor = UIColor.white
                let textColor = UIColor.interpolate(from: unselectedTextColor, to: selectedTextColor, progress: selectFactor)
                
                let textRadius = radius - (ringWidth / 2)
                let availableArcLength = textRadius * sweepAngle
                let padding: CGFloat = 12
                let maxTextWidth = max(0, availableArcLength - padding)
                
                let textToDraw = slice.label.truncate(toWidth: maxTextWidth, font: font)
                
                var normMid = midAngle.truncatingRemainder(dividingBy: 2 * .pi)
                if normMid < 0 { normMid += 2 * .pi }
                let isBottomHalf = sin(midAngle) > 0.1
                
                drawCurvedString(
                    string: textToDraw,
                    context: context,
                    radius: textRadius,
                    centerAngle: midAngle,
                    color: textColor,
                    font: font,
                    isBottom: isBottomHalf
                )
            }
            
            startAngle = endAngle
        }
    }
    
    private func drawCurvedString(string: String, context: CGContext, radius: CGFloat, centerAngle: CGFloat, color: UIColor, font: UIFont, isBottom: Bool) {
        
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let attrStr = NSAttributedString(string: string, attributes: attributes)
        let totalWidth = attrStr.size().width
        let totalTextAngle = totalWidth / radius
        
        let cx = bounds.width / 2
        let cy = bounds.height / 2
        
        var currentAngle = isBottom
            ? centerAngle + (totalTextAngle / 2)
            : centerAngle - (totalTextAngle / 2)
        
        for char in string {
            let s = String(char)
            let charSize = s.size(withAttributes: attributes)
            let charWidth = charSize.width
            let charAngle = charWidth / radius
            
            let charMidAngle = isBottom
                ? currentAngle - (charAngle / 2)
                : currentAngle + (charAngle / 2)
            
            context.saveGState()
            
            let x = cx + radius * cos(charMidAngle)
            let y = cy + radius * sin(charMidAngle)
            
            context.translateBy(x: x, y: y)
            
            let rotation = isBottom
                ? charMidAngle - .pi / 2
                : charMidAngle + .pi / 2
            
            context.rotate(by: rotation)
            
            let drawPoint = CGPoint(x: -charWidth / 2, y: -charSize.height / 2)
            s.draw(at: drawPoint, withAttributes: attributes)
            
            context.restoreGState()
            
            if isBottom {
                currentAngle -= charAngle
            } else {
                currentAngle += charAngle
            }
        }
    }
    
    // MARK: - update logic
    
    private func updateCenterLabel() {
        if let idx = selectedSliceIndex, idx < targetSlices.count {
            let s = targetSlices[idx]
            
            let titleFont = UIFont.systemFont(ofSize: 15, weight: .semibold).rounded()
            let gpaFont = UIFont.systemFont(ofSize: 26, weight: .bold).rounded()
            
            let attr = NSMutableAttributedString(string: "\(s.label)\n", attributes: [
                .font: titleFont,
                .foregroundColor: UIColor.label
            ])
            attr.append(NSAttributedString(string: String(format: "%.2f", s.subGPA), attributes: [
                .font: gpaFont,
                .foregroundColor: s.color.darker(by: 0.2)
            ]))
            centerLabel.attributedText = attr
        } else {
            let titleFont = UIFont.systemFont(ofSize: 14, weight: .medium).rounded()
            let gpaFont = UIFont.systemFont(ofSize: 34, weight: .heavy).rounded()
            
            let attr = NSMutableAttributedString(string: "Your GPA\n", attributes: [
                .font: titleFont,
                .foregroundColor: UIColor.secondaryLabel
            ])
            attr.append(NSAttributedString(string: String(format: "%.3f", totalGPA), attributes: [
                .font: gpaFont,
                .foregroundColor: UIColor.label
            ]))
            centerLabel.attributedText = attr
        }
    }
    
    // MARK: - update on touch
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: self)
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        
        let dx = location.x - center.x
        let dy = location.y - center.y
        let dist = sqrt(dx*dx + dy*dy)
        
        let radius = (min(bounds.width, bounds.height) / 2) - (selectedGrowth + 10)
        let innerR = radius - ringWidth - 20
        let outerR = radius + selectedGrowth + 20
        
        if dist >= innerR && dist <= outerR {
            var angle = atan2(dy, dx)
            angle += CGFloat.pi / 2
            if angle < 0 { angle += 2 * .pi }
            
            let total = currentSlices.reduce(0) { $0 + $1.value }
            let safeTotal = total > 0 ? total : 1
            var currentAngle: CGFloat = 0
            
            for (i, slice) in currentSlices.enumerated() {
                let sliceAngle = CGFloat(2 * .pi * (slice.value / safeTotal))
                if angle >= currentAngle && angle < currentAngle + sliceAngle {
                    let gen = UIImpactFeedbackGenerator(style: .light)
                    gen.impactOccurred()
                    
                    if selectedSliceIndex == i {
                        selectedSliceIndex = nil
                    } else {
                        selectedSliceIndex = i
                    }
                    updateCenterLabel()
                    return
                }
                currentAngle += sliceAngle
            }
        } else {
            if selectedSliceIndex != nil {
                selectedSliceIndex = nil
                updateCenterLabel()
            }
        }
    }
}
