//
//  CandleRender.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import UIKit

class CandleRender: KLineRenderer {
    
    var styleConfig: StyleConfiguration
    
    init(styleConfig: StyleConfiguration) {
        self.styleConfig = styleConfig
    }
    
    func draw(in layer: CALayer, for dataProvider: KLineDataProvider, range: Range<Int>, in rect: CGRect, metricBounds: MetricBounds) {
        let sublayer = CALayer()
        sublayer.frame = rect
        sublayer.contentsScale = UIScreen.main.scale
        
        let visiableItems = Array(dataProvider.kLineItems[range])
        let unit = rect.height / metricBounds.distance
        
        for (idx, item) in visiableItems.enumerated() {
            let x = CGFloat(idx) * (styleConfig.kLineStyle.lineWidth + styleConfig.kLineStyle.gap)
            let centerX = x + styleConfig.kLineStyle.lineWidth / 2 - styleConfig.kLineStyle.gap / 2
            let highestPoint = CGPoint(x: centerX, y: rect.height - (item.highest - metricBounds.minimum) * unit)
            let lowestPoint = CGPoint(x: centerX, y: rect.height - (item.lowest - metricBounds.minimum) * unit)
            
            let h = fabs(item.opening - item.closing) * unit
            let y = rect.height - (max(item.opening, item.closing) - metricBounds.minimum) * unit
            
            let path = UIBezierPath(rect: CGRect(x: x, y: y, width: styleConfig.kLineStyle.lineWidth - styleConfig.kLineStyle.gap, height: h))
            
            path.move(to: lowestPoint)
            path.addLine(to: CGPoint(x: centerX, y: y + h))
            path.move(to: highestPoint)
            path.addLine(to: CGPoint(x: centerX, y: y))
            
            let shape = CAShapeLayer()
            shape.contentsScale = UIScreen.main.scale
            shape.path = path.cgPath
            shape.lineWidth = 1
            shape.strokeColor = item.trend != .down ? UIColor.systemRed.cgColor : UIColor.systemGreen.cgColor
            shape.fillColor = item.trend != .down ? UIColor.systemRed.cgColor : UIColor.clear.cgColor
            
            sublayer.addSublayer(shape)
        }
        
        layer.addSublayer(sublayer)
    }
}
