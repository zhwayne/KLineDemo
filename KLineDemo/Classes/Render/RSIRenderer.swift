//
//  RSIRenderer.swift
//  KLineDemo
//
//  Created by iya on 2024/11/6.
//

import UIKit

class RSIRenderer: ChartRenderer, IndicatorStyleConfigurable {
    
    typealias Item = IndicatorData
    
    let period: Int
    
    var indicatorKey: IndicatorKey { .rsi(period: period) }
    
    var chartStyle: ChartStyle?
    
    var candleWidth: CGFloat = 0
    
    init(period: Int) {
        self.period = period
    }
    
    func draw(in layer: CALayer, rect: CGRect, transformer: any ChartTransformer, items: [Item], range: Range<Int>) {
        guard let chartStyle else {
            return
        }
        
        let sublayer = CAShapeLayer()
        sublayer.frame = rect
        sublayer.contentsScale = UIScreen.main.scale
        sublayer.lineWidth = 1
        sublayer.fillColor = chartStyle.fillColor?.cgColor
        sublayer.strokeColor = chartStyle.lineColor.cgColor
        
        let visiableItems = items[range]
        let path = UIBezierPath()
        
        for (idx, item) in visiableItems.enumerated() {
            guard let value = item.getIndicator(forKey: indicatorKey, as: Double.self) else {
                continue
            }
            // 计算 x 坐标
            let x = transformer.transformX(index: idx) + candleWidth * 0.5
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

