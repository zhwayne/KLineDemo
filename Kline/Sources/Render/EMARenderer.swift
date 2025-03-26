//
//  EMARenderer.swift
//  KLineDemo
//
//  Created by iya on 2024/11/6.
//

import UIKit

struct EMARenderer: IndicatorRenderer {
    
    typealias Item = IndicatorData
        
    var type: IndicatorType { .ema }

    func draw(in layer: CALayer, context: RenderContext<IndicatorData>) {
        
        let transformer = context.transformer
        let rect = transformer.viewPort
        let candleStyle = context.styleManager.candleStyle
        let items = context.items
        
        
        for key in type.keys {
            let indicatorStyle = context.styleManager.indicatorStyle(for: key)
            let sublayer = CAShapeLayer()
            sublayer.frame = rect
            sublayer.contentsScale = UIScreen.main.scale
            sublayer.lineWidth = indicatorStyle.lineWidth
            sublayer.fillColor = indicatorStyle.fillColor?.cgColor
            sublayer.strokeColor = indicatorStyle.strokeColor.cgColor
            
            let path = UIBezierPath()
            
            for (idx, item) in items.enumerated() {
                guard let value = item.getIndicator(forKey: key) as? Double else {
                    continue
                }
                // 计算 x 坐标
                let x = transformer.transformX(at: idx) + candleStyle.width * 0.5
                let y = transformer.transformY(value: value)
                let centerX = x
                let point = CGPoint(x: centerX, y: y)
                
                if path.currentPoint == .zero {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            
            sublayer.path = path.cgPath
            layer.addSublayer(sublayer)
        }
    }
}

