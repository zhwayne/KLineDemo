//
//  MARenderer.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import UIKit

struct MARenderer: IndicatorRenderer {
    
    typealias Item = IndicatorData
    
    let period: Int
    
    var key: IndicatorKey { .ma(period: period) }
    
    init(period: Int) {
        self.period = period
    }
    
    func draw(in layer: CALayer, items: [IndicatorData], indices: Range<Int>, context: RenderContext) {
        let transformer = context.transformer
        let rect = transformer.viewPort
        let chartStyle = context.chartStyle
        let candleStyle = context.candleStyle
        
        let sublayer = CAShapeLayer()
        sublayer.frame = rect
        sublayer.contentsScale = UIScreen.main.scale
        sublayer.lineWidth = 1
        sublayer.fillColor = chartStyle?.fillColor?.cgColor
        sublayer.strokeColor = chartStyle?.lineColor.cgColor
        
        let path = UIBezierPath()
        
        for (idx, item) in items.enumerated() {
            guard let value = item.getIndicator(forKey: key) as? Double else {
                continue
            }
            // 计算 x 坐标
            let x = transformer.transformX(at: idx) + candleStyle.lineWidth * 0.5
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
