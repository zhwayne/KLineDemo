//
//  LongPressRenderer.swift
//  KLine
//
//  Created by work on 2025/3/28.
//

import UIKit

final class LongPressRenderer: ChartRenderer {
    
    let layer = CALayer()
    private let feedback = UISelectionFeedbackGenerator()
    private var styleManager: StyleManager { .shared }
    private let dateBgLayer = CALayer()
    private let dateLayer = CATextLayer()
    private let dateFormatter: DateFormatter
    private let dashLineLayer = CAShapeLayer()
    private let pointLayer = CAShapeLayer()
    private var lastLocationX: CGFloat = 0
    var location: CGPoint = .zero
    var transformer: Transformer?
    var timelineY: CGFloat = 0
    var timelineHeight: CGFloat = 0
    
    typealias Item = IndicatorData
    
    init() {
        dateBgLayer.contentsScale = UIScreen.main.scale
        dateBgLayer.cornerRadius = 3
        dateLayer.font = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular) as CTFont
        dateLayer.fontSize = 10
        dateLayer.alignmentMode = .center
        dateLayer.contentsScale = UIScreen.main.scale
        dateBgLayer.addSublayer(dateLayer)
        
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        
        dashLineLayer.strokeColor = UIColor.label.cgColor
        dashLineLayer.lineWidth = 1 / UIScreen.main.scale
        dashLineLayer.lineDashPattern = [2, 2]
        
        pointLayer.fillColor = UIColor.label.cgColor
        feedback.prepare()
    }
    
    func clean() {
        if layer.superlayer != nil {
            layer.removeFromSuperlayer()
            layer.sublayers = nil
        }
    }
    
    func draw(in layer: CALayer, data: RenderData<IndicatorData>) {
        guard let transformer = transformer else { return }
        layer.addSublayer(dashLineLayer)
        layer.addSublayer(pointLayer)
        layer.addSublayer(dateBgLayer)
        
        let rect = layer.bounds
        
        // 调整x轴，使其始终和蜡烛图item水平居中对齐
        let index = transformer.indexOfVisibleItem(at: location.x, extend: true)!
        location.x = transformer.xAxisInLayer(
            at: index - data.visibleRange.lowerBound
        ) + styleManager.candleStyle.width * 0.5
        if lastLocationX != location.x {
            feedback.selectionChanged()
        }
        lastLocationX = location.x
        
        // MARK: - 绘制y轴虚线
        let path = UIBezierPath()
        path.move(to: CGPoint(x: location.x, y: 0))
        path.addLine(to: CGPoint(x: location.x, y: rect.height))
        dashLineLayer.path = path.cgPath
        
        // MARK: - 绘制圆点
        let circlePath = UIBezierPath(
            arcCenter: location,
            radius: 2,
            startAngle: 0,
            endAngle: CGFloat.pi * 2,
            clockwise: false
        )
        pointLayer.path = circlePath.cgPath
        
        // MARK: - 绘制日期时间轴
        if index >= 0 && index < data.items.count {
            dateBgLayer.isHidden = false
            let item = data.items[index].item
            let date = Date(timeIntervalSince1970: TimeInterval(item.timestamp))
            let timeString = dateFormatter.string(from: date)
            dateLayer.string = timeString
            let size = dateLayer.preferredFrameSize()
            let x = location.x - (size.width + 8) * 0.5
            let bgRect = CGRect(
                x: max(0, min(x, rect.width - size.width)),
                y: timelineY,
                width: size.width + 8,
                height: timelineHeight
            )
            dateLayer.foregroundColor = UIColor.systemBackground.cgColor
            dateBgLayer.backgroundColor = UIColor.label.cgColor
            dateBgLayer.frame = bgRect
            dateLayer.frame = CGRect(
                x: (bgRect.width - size.width) * 0.5,
                y: (bgRect.height - size.height) * 0.5,
                width: size.width,
                height: size.height
            )
        } else {
            // TODO: 根据K线周期计算当前x轴的日期
            dateBgLayer.isHidden = true
        }
    }
}
