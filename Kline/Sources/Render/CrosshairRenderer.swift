//
//  CrosshairRenderer.swift
//  KLine
//
//  Created by work on 2025/3/28.
//

import UIKit

final class CrosshairRenderer: ChartRenderer {
    
    private let feedback = UISelectionFeedbackGenerator()
    private var styleManager: StyleManager { .shared }
//    private let dateBgLayer = CALayer()
//    private let dateLayer = CATextLayer()
    private let dateLabel = UILabel()
    private let dateFormatter: DateFormatter
    private let dashLineLayer = CAShapeLayer()
    private let pointLayer = CAShapeLayer()
    private let yAxisValueLabel = UILabel()
    private var lastLocationX: CGFloat = 0
    var location: CGPoint = .zero
    var locationRect: CGRect = .zero
    var transformer: Transformer?
    var timelineY: CGFloat = 0
    var timelineHeight: CGFloat = 0
    
    typealias Item = IndicatorData
    
    init() {
//        dateBgLayer.contentsScale = UIScreen.main.scale
//        dateBgLayer.cornerRadius = 3
//        dateLayer.font = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular) as CTFont
//        dateLayer.fontSize = 10
//        dateLayer.alignmentMode = .center
//        dateLayer.contentsScale = UIScreen.main.scale
//        dateBgLayer.addSublayer(dateLayer)
        dateLabel.backgroundColor = .label
        dateLabel.textColor = .systemBackground
        dateLabel.font = .monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        dateLabel.textAlignment = .center
        dateLabel.layer.masksToBounds = true
        dateLabel.layer.cornerRadius = 3
        
        yAxisValueLabel.backgroundColor = .label
        yAxisValueLabel.textColor = .systemBackground
        yAxisValueLabel.font = .monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        yAxisValueLabel.textAlignment = .center
        yAxisValueLabel.layer.masksToBounds = true
        yAxisValueLabel.layer.cornerRadius = 3
        
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        
        dashLineLayer.lineWidth = 1 / UIScreen.main.scale
        dashLineLayer.lineDashPattern = [2, 2]
        
        feedback.prepare()
    }
    
//    func clean() {
//        dashLineLayer.removeFromSuperlayer()
//        pointLayer.removeFromSuperlayer()
//        dateLabel.removeFromSuperview()
//        yAxisValueLabel.removeFromSuperview()
//    }
    
    func draw(in layer: CALayer, data: RenderData<IndicatorData>) {
        guard let transformer = transformer else { return }
        pointLayer.path = nil
        dashLineLayer.strokeColor = UIColor.label.cgColor
        pointLayer.fillColor = UIColor.label.cgColor
        layer.addSublayer(dashLineLayer)
        layer.addSublayer(pointLayer)
        if dateLabel.superview == nil, let view = layer.owningView {
            view.addSubview(dateLabel)
        }
        if yAxisValueLabel.superview == nil, let view = layer.owningView {
            view.addSubview(yAxisValueLabel)
        }
        
        let rect = layer.bounds
        
        // 调整x轴，使其始终和蜡烛图item居中对齐
        let index = transformer.indexOfVisibleItem(xAxis: location.x, extend: true)!
        let candleHalfWidth = styleManager.candleStyle.width * 0.5
        let indexInVisibaleRect = index - data.visibleRange.lowerBound
        location.x = transformer.xAxisInLayer(at: indexInVisibaleRect) + candleHalfWidth
        // x轴变化时反馈
        if lastLocationX != location.x {
            feedback.selectionChanged()
        }
        lastLocationX = location.x
        
        // MARK: - 绘制y轴虚线
        let path = UIBezierPath()
        path.move(to: CGPoint(x: location.x, y: 0))
        path.addLine(to: CGPoint(x: location.x, y: rect.height))
        defer { dashLineLayer.path = path.cgPath }
        
        let edgeInset = UIEdgeInsets(
            top: transformer.contentInset.top,
            left: 0,
            bottom: transformer.contentInset.bottom,
            right: 0
        )
        
        // MARK: - 绘制x轴虚线x
        let inMainChart = location.y > 0 && locationRect.minY < timelineY
        let inSubChart = locationRect.minY >= timelineY + timelineHeight
        && locationRect.inset(by: edgeInset).contains(location)
        if (inMainChart || inSubChart) {
            path.move(to: CGPoint(x: 0, y: location.y))
            path.addLine(to: CGPoint(x: rect.width, y: location.y))
            
            // MARK: - 绘制圆点
            let circlePath = UIBezierPath(
                arcCenter: location,
                radius: 2,
                startAngle: 0,
                endAngle: CGFloat.pi * 2,
                clockwise: false
            )
            pointLayer.path = circlePath.cgPath
            
            yAxisValueLabel.isHidden = false
            let value = transformer.valueOf(yAxis: location.y - locationRect.minY)
            
            yAxisValueLabel.text = styleManager.format(value: value)
            var size = yAxisValueLabel.systemLayoutSizeFitting(rect.size)
            size.width += 10
            size.height += 10
            yAxisValueLabel.frame = CGRect(
                x: rect.width - size.width - 10,
                y: location.y - size.height * 0.5,
                width: size.width,
                height: size.height
            )
        } else {
            yAxisValueLabel.isHidden = true
        }
        
        // MARK: - 绘制日期时间轴
        if index >= 0 && index < data.items.count {
            dateLabel.isHidden = false
            let item = data.items[index].item
            let date = Date(timeIntervalSince1970: TimeInterval(item.timestamp))
            let timeString = dateFormatter.string(from: date)
            dateLabel.text = timeString
            let size = dateLabel.systemLayoutSizeFitting(rect.size)
            let x = location.x - (size.width + 10) * 0.5
            let bgRect = CGRect(
                x: max(0, min(x, rect.width - size.width - 10)),
                y: timelineY,
                width: size.width + 10,
                height: timelineHeight
            )
            dateLabel.frame = bgRect
        } else {
            // TODO: 根据K线周期计算当前x轴的日期
            dateLabel.text = nil
            dateLabel.isHidden = true
        }
    }
}

//private class YAxisValueTextLayer: CALayer {
//    
//    private let textLayer = CATextLayer()
//    
//    private var foregroundColor: CGColor? {
//        get { textLayer.foregroundColor }
//        set { textLayer.foregroundColor = newValue }
//    }
//    
//    private var string: Any? {
//        get { textLayer.string }
//        set { textLayer.string = newValue }
//    }
//    
//    override init() {
//        super.init()
//        textLayer.font = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular) as CTFont
//        textLayer.fontSize = 10
//        addSublayer(textLayer)
//    }
//    
//    override func layoutSublayers() {
//        super.layoutSublayers()
//        let size = textLayer.preferredFrameSize()
//        textLayer.frame = CGRect(x: <#T##Int#>, y: <#T##Int#>, width: <#T##Int#>, height: <#T##Int#>)
//    }
//    
//    override func preferredFrameSize() -> CGSize {
//        var size = textLayer.preferredFrameSize()
//        size.width += 8
//        size.height += 8
//        return size
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
