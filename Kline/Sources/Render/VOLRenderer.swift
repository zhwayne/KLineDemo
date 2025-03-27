//
//  VOLRenderer.swift
//  KLineDemo
//
//  Created by work on 2025/3/24.
//

import UIKit

struct VOLRenderer: IndicatorRenderer {
    
    typealias Item = IndicatorData
    
    var type: IndicatorType { .vol }
    
    func draw(in layer: CALayer, context: RenderContext<IndicatorData>) {
        let transformer = context.transformer
        let rect = transformer.viewPort
        let candleStyle = context.styleManager.candleStyle
        let indicatorStyle = context.styleManager.indicatorStyle(for: .vol)
        let items = context.visibleItems
        
        // MARK: - 网格线（列）
        drawColumnBackground(in: layer, viewPort: transformer.viewPort)
        
        let sublayer = CALayer()
        sublayer.frame = rect
        sublayer.contentsScale = UIScreen.main.scale
        
        // MARK: - 标题
        let textLayer = CATextLayer()
        textLayer.font = indicatorStyle.font as CTFont
        textLayer.fontSize = indicatorStyle.font.pointSize
        textLayer.foregroundColor = indicatorStyle.strokeColor.cgColor
        textLayer.alignmentMode = .center
        textLayer.contentsScale = UIScreen.main.scale
        sublayer.addSublayer(textLayer)
        let volume = items.last!.item.volume
        textLayer.string = "VOL:\(context.styleManager.format(value: volume))"
        let size = textLayer.preferredFrameSize()
        textLayer.frame = CGRect(x: 12, y: rect.minY + 8, width: size.width, height: size.height)
        layer.addSublayer(textLayer)
        
        let verticalInset = AxisInset(top: textLayer.bounds.height + 16, bottom: 2)
        
        // MARK: - 折线图
        for (idx, item) in items.enumerated() {
            // 计算 x 坐标
            let x = transformer.viewPortMinX(at: idx)
            let y = transformer.transformY(value: Double(item.item.volume), inset: verticalInset)
            let rect = CGRect(x: x, y: y, width: candleStyle.width, height: rect.height - y - 2)
            let path = UIBezierPath(rect: rect)
            
            let shape = CAShapeLayer()
            shape.contentsScale = UIScreen.main.scale
            shape.path = path.cgPath
            shape.strokeColor = item.item.trend == .up ? candleStyle.upColor.cgColor : candleStyle.downColor.cgColor
            shape.fillColor = item.item.trend == .up ? candleStyle.upColor.cgColor : candleStyle.downColor.cgColor
            shape.opacity = 0.5
            
            sublayer.addSublayer(shape)
        }
        
        layer.addSublayer(sublayer)
        
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
