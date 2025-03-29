//
//  RSIRenderer.swift
//  KLineDemo
//
//  Created by iya on 2024/11/6.
//

import UIKit

final class RSIRenderer: IndicatorRenderer {
    
    var styleManager: StyleManager { .shared }
        
    var transformer: Transformer?
    
    typealias Item = IndicatorData
        
    var type: IndicatorType { .rsi }
    
    func draw(in layer: CALayer, data: RenderData<IndicatorData>) {
        transformer?.dataBounds.combine(other: .init(max: 70, min: 30))
        guard let transformer = transformer else { return }
        
        let rect = transformer.viewPort
        let candleStyle = styleManager.candleStyle
        let visibleItems = data.visibleItems
        
        let sublayer = CALayer()
        sublayer.frame = rect
        sublayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(sublayer)
        
        // MARK: - 网格线（列）
        drawColumnBackground(in: layer, viewPort: transformer.viewPort)
       
        // MARK: - 标题
        let attrText = NSMutableAttributedString()
        let indicatorData = visibleItems.last!
        let textLayer = CATextLayer()
        textLayer.alignmentMode = .center
        textLayer.contentsScale = UIScreen.main.scale
        sublayer.addSublayer(textLayer)
        
        for key in type.keys {
            var number: Double = 0
            if let value = indicatorData.indicator(forKey: key) {
                number = value.doubeValue
            }
            let indicatorStyle = styleManager.indicatorStyle(for: key)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.1
            let span = NSAttributedString(
                string: "\(key):\(styleManager.format(value: number))  ",
                attributes: [
                    .foregroundColor: indicatorStyle.strokeColor,
                    .font: indicatorStyle.font,
                    .paragraphStyle: paragraphStyle
                ]
            )
            attrText.append(span)
        }
        textLayer.string = attrText
        let size = textLayer.preferredFrameSize()
        textLayer.frame = CGRect(x: 12, y: rect.minY + 8, width: size.width, height: size.height)
        layer.addSublayer(textLayer)
        

        // MARK: - 折线图
        for key in type.keys {
            let indicatorStyle = styleManager.indicatorStyle(for: key)
            let lineLayer = CAShapeLayer()
            lineLayer.frame = rect
            lineLayer.contentsScale = UIScreen.main.scale
            lineLayer.lineWidth = indicatorStyle.lineWidth
            lineLayer.fillColor = indicatorStyle.fillColor?.cgColor
            lineLayer.strokeColor = indicatorStyle.strokeColor.cgColor
            
            let path = UIBezierPath()
            var hasStartPoint = false
            for (idx, item) in visibleItems.enumerated() {
                guard let value = item.indicator(forKey: key)?.doubeValue else {
                    continue
                }
                // 计算 x 坐标
                let x = transformer.xAxis(at: idx) + candleStyle.width * 0.5
                let y = transformer.yAxis(for: value)
                let point = CGPoint(x: x, y: y)
                
                if !hasStartPoint {
                    path.move(to: point)
                    hasStartPoint = true
                } else {
                    path.addLine(to: point)
                }
            }
            
            
            lineLayer.path = path.cgPath
            layer.addSublayer(lineLayer)
        }
        
        // MARK: - 超买和超卖区域
        let oby = transformer.yAxis(for: 70)
        let osy = transformer.yAxis(for: 30)
        let maxX = transformer.xAxis(at: visibleItems.count - 1) + candleStyle.width * 0.5
        let overRect = CGRect(x: 0, y: oby, width: maxX, height: osy - oby)
        let overAreaShape = CAShapeLayer()
        overAreaShape.fillColor = UIColor.systemBlue.withAlphaComponent(0.1).cgColor
        overAreaShape.strokeColor = UIColor.clear.cgColor
        overAreaShape.path = UIBezierPath(rect: overRect).cgPath
        sublayer.addSublayer(overAreaShape)
        
        let overDashLine = CAShapeLayer()
        overDashLine.strokeColor = UIColor.systemBlue.withAlphaComponent(0.8).cgColor
        overDashLine.lineWidth = 1
        overDashLine.lineDashPattern = [2, 2]
        let overDashLinePath = UIBezierPath()
        overDashLinePath.move(to: CGPoint(x: overRect.minX, y: overRect.minY))
        overDashLinePath.addLine(to: CGPoint(x: overRect.maxX, y: overRect.minY))
        overDashLinePath.move(to: CGPoint(x: overRect.minX, y: overRect.maxY))
        overDashLinePath.addLine(to: CGPoint(x: overRect.maxX, y: overRect.maxY))
        overDashLine.path = overDashLinePath.cgPath
        sublayer.addSublayer(overDashLine)
        
        // MARK: - 边界线
        let lineHeight = 1 / UIScreen.main.scale
        let bottomLinePath = UIBezierPath()
        bottomLinePath.move(to: CGPoint(x: 0, y: rect.maxY - lineHeight))
        bottomLinePath.addLine(to: CGPoint(x: layer.bounds.maxX, y: rect.maxY - lineHeight))
        
        let bottomLineLayer = CAShapeLayer()
        bottomLineLayer.path = bottomLinePath.cgPath
        bottomLineLayer.lineWidth = lineHeight
        bottomLineLayer.fillColor = UIColor.clear.cgColor
        bottomLineLayer.strokeColor = UIColor.separator.cgColor
        layer.addSublayer(bottomLineLayer)
    }
}

