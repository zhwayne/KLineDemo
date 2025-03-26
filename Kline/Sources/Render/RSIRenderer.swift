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
        let transformer = context.transformer
        let rect = transformer.viewPort
        let candleStyle = context.styleManager.candleStyle
        let items = context.items
        
        let sublayer = CALayer()
        sublayer.frame = rect
        sublayer.contentsScale = UIScreen.main.scale

        // MARK: -
        for key in type.keys {
            let indicatorStyle = context.styleManager.indicatorStyle(for: key)
            let lineLayer = CAShapeLayer()
            lineLayer.frame = rect
            lineLayer.contentsScale = UIScreen.main.scale
            lineLayer.lineWidth = indicatorStyle?.lineWidth ?? 1
            lineLayer.fillColor = indicatorStyle?.fillColor?.cgColor
            lineLayer.strokeColor = indicatorStyle?.strokeColor.cgColor
            
            let path = UIBezierPath()
            let verticalInset = AxisInset(top: 2, bottom: 2)
            
            for (idx, item) in items.enumerated() {
                guard let value = item.getIndicator(forKey: key) as? Double else {
                    continue
                }
                // 计算 x 坐标
                let x = transformer.transformX(at: idx) + candleStyle.width * 0.5
                let y = transformer.transformY(value: value, inset: verticalInset)
                let centerX = x
                let point = CGPoint(x: centerX, y: y)
                
                if path.currentPoint == .zero {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            
            
            lineLayer.path = path.cgPath
            layer.addSublayer(lineLayer)
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

