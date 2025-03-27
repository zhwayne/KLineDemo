//
//  RSIRenderer.swift
//  KLineDemo
//
//  Created by iya on 2024/11/6.
//

import UIKit

struct RSIRenderer: IndicatorRenderer {
    
    typealias Item = IndicatorData
        
    var type: IndicatorType { .rsi }
    
    func draw(in layer: CALayer, context: RenderContext<IndicatorData>) {
        var transformer = context.transformer
        transformer.dataBounds.combine(other: .init(max: 70, min: 30))
        
        let rect = transformer.viewPort
        let styleManager = context.styleManager
        let candleStyle = context.styleManager.candleStyle
        let items = context.visibleItems
        
        let sublayer = CALayer()
        sublayer.frame = rect
        sublayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(sublayer)
        
        // MARK: - 网格线（列）
        drawColumnBackground(in: layer, viewPort: transformer.viewPort)
       
        // MARK: - 标题
        let attrText = NSMutableAttributedString()
        let indicatorData = items.last!
        let textLayer = CATextLayer()
        textLayer.alignmentMode = .center
        textLayer.contentsScale = UIScreen.main.scale
        sublayer.addSublayer(textLayer)
        
        for key in type.keys {
            var number: Double = 0
            if let value = indicatorData.getIndicator(forKey: key) {
                number = NSDecimalNumber(string: "\(value)").doubleValue
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
        let verticalInset = AxisInset(top: textLayer.bounds.height + 16, bottom: 2)
        for key in type.keys {
            let indicatorStyle = styleManager.indicatorStyle(for: key)
            let lineLayer = CAShapeLayer()
            lineLayer.frame = rect
            lineLayer.contentsScale = UIScreen.main.scale
            lineLayer.lineWidth = indicatorStyle.lineWidth
            lineLayer.fillColor = indicatorStyle.fillColor?.cgColor
            lineLayer.strokeColor = indicatorStyle.strokeColor.cgColor
            
            let path = UIBezierPath()
            
            for (idx, item) in items.enumerated() {
                guard let value = item.getIndicator(forKey: key) as? Double else {
                    continue
                }
                // 计算 x 坐标
                let x = transformer.viewPortMinX(at: idx) + candleStyle.width * 0.5
                let y = transformer.transformY(value: value, inset: verticalInset)
                let centerX = x
                let point = CGPoint(x: centerX, y: y)
                
                if idx == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            
            
            lineLayer.path = path.cgPath
            layer.addSublayer(lineLayer)
        }
        
        // MARK: - 超买和超卖区域
        let oby = transformer.transformY(value: 70, inset: verticalInset)
        let osy = transformer.transformY(value: 30, inset: verticalInset)
        let maxX = transformer.viewPortMinX(at: items.count - 1) + candleStyle.width * 0.5
        let overRect = CGRect(x: 0, y: oby, width: maxX, height: osy - oby)
        let overAreaShape = CAShapeLayer()
        overAreaShape.fillColor = UIColor.systemBlue.withAlphaComponent(0.1).cgColor
        overAreaShape.strokeColor = UIColor.clear.cgColor
        overAreaShape.path = UIBezierPath(rect: overRect).cgPath
        sublayer.addSublayer(overAreaShape)
        
        let overDashLine = CAShapeLayer()
        overDashLine.strokeColor = UIColor.systemBlue.withAlphaComponent(0.7).cgColor
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

