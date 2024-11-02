//
//  MARender.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import UIKit

class MARender: KLineRenderer {
    
    var styleConfig: StyleConfiguration
    
    init(styleConfig: StyleConfiguration) {
        self.styleConfig = styleConfig
    }
    
    func draw(in layer: CALayer, for dataProvider: KLineDataProvider, range: Range<Int>, in rect: CGRect, metricBounds: MetricBounds) {
        let sublayer = CALayer()
        sublayer.frame = rect
        sublayer.contentsScale = UIScreen.main.scale
        
        let visiableItems = Array(dataProvider.indicators[range])
        let unit = rect.height / metricBounds.distance
        
        let path1 = UIBezierPath()
        let path2 = UIBezierPath()
        let path3 = UIBezierPath()
        
        for (idx, item) in visiableItems.enumerated() {
            let x = CGFloat(idx) * (styleConfig.kLineStyle.lineWidth + styleConfig.kLineStyle.gap)
            let value1 = item.getIndicator(forKey: .ma(period: 10), as: Double.self) ?? 0
            let point1 = CGPoint(x: x + styleConfig.kLineStyle.lineWidth / 2, y: rect.height - (value1 - metricBounds.minimum) * unit)
            
            let value2 = item.getIndicator(forKey: .ma(period: 30), as: Double.self) ?? 0
            let point2 = CGPoint(x: x + styleConfig.kLineStyle.lineWidth / 2, y: rect.height - (value2 - metricBounds.minimum) * unit)
            
            let value3 = item.getIndicator(forKey: .ma(period: 60), as: Double.self) ?? 0
            let point3 = CGPoint(x: x + styleConfig.kLineStyle.lineWidth / 2, y: rect.height - (value3 - metricBounds.minimum) * unit)
            
            if idx == 0 {
                path1.move(to: point1)
                path2.move(to: point2)
                path3.move(to: point3)
            } else {
                path1.addLine(to: point1)
                path2.addLine(to: point2)
                path3.addLine(to: point3)
            }
        }
        
        
        let shape1 = CAShapeLayer()
        shape1.contentsScale = UIScreen.main.scale
        shape1.path = path1.cgPath
        shape1.lineWidth = 1
        shape1.strokeColor = UIColor.systemOrange.cgColor
        shape1.fillColor = UIColor.clear.cgColor
        
        
        
        let shape2 = CAShapeLayer()
        shape2.contentsScale = UIScreen.main.scale
        shape2.path = path2.cgPath
        shape2.lineWidth = 1
        shape2.strokeColor = UIColor.systemPink.cgColor
        shape2.fillColor = UIColor.clear.cgColor
        
        let shape3 = CAShapeLayer()
        shape3.contentsScale = UIScreen.main.scale
        shape3.path = path3.cgPath
        shape3.lineWidth = 1
        shape3.strokeColor = UIColor.systemPurple.cgColor
        shape3.fillColor = UIColor.clear.cgColor
        
        sublayer.addSublayer(shape1)
        sublayer.addSublayer(shape2)
        sublayer.addSublayer(shape3)
        
        layer.addSublayer(sublayer)
    }
}

import Charts
