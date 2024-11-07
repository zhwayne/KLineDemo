//
//  MARenderer.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import UIKit

class MARenderer: ChartRenderer, StyleConfigurable {
    
    typealias Value = IndicatorData
    
    let period: Int
    
    var indicatorKey: IndicatorKey { .ma(period: period) }
    
    var chartStyle: ChartStyle?
    
    var candlestickWidth: CGFloat = 0
    
    init(period: Int) {
        self.period = period
    }
    
    func draw(in layer: CALayer, rect: CGRect, transformer: ChartTransformer, values: [Value]) {
        guard let chartStyle else {
            return
        }
        
        let sublayer = CAShapeLayer()
        sublayer.frame = rect
        sublayer.contentsScale = UIScreen.main.scale
        sublayer.lineWidth = 1
        sublayer.fillColor = chartStyle.fillColor?.cgColor
        sublayer.strokeColor = chartStyle.lineColor.cgColor
        
        let visiableItems = values
        let path = UIBezierPath()
        
        for (idx, item) in visiableItems.enumerated() {
            guard let value = item.getIndicator(forKey: indicatorKey, as: Double.self) else {
                continue
            }
            // 计算 x 坐标
            let x = transformer.transformX(index: idx) + candlestickWidth * 0.5
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
