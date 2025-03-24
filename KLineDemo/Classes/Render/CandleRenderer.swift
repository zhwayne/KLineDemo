//
//  CandleRenderer.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import UIKit

struct CandleRenderer: ChartRenderer {
    
    typealias Item = KLineItem
    
    func draw(in layer: CALayer, items: [KLineItem], indices: Range<Int>, context: RenderContext) {
        let transformer = context.transformer
        let rect = transformer.viewPort
        let candleStyle = context.styleManager.candleStyle
        
        let sublayer = CALayer()
        sublayer.frame = rect
        sublayer.contentsScale = UIScreen.main.scale        
        
        for (idx, item) in items.enumerated() {
            // 计算 x 坐标
            let x = transformer.transformX(at: idx)

            // 计算开盘价和收盘价的 y 坐标
            let openY = transformer.transformY(value: item.opening)
            let closeY = transformer.transformY(value: item.closing)
            let y = min(openY, closeY)
            let h = abs(openY - closeY)
            
            let rect = CGRect(x: x, y: y, width: candleStyle.lineWidth, height: h)
            let path = UIBezierPath(rect: rect)
            
            // 计算最高价和最低价的 y 坐标
            let highY = transformer.transformY(value: item.highest)
            let lowY = transformer.transformY(value: item.lowest)
            
            let centerX = candleStyle.lineWidth / 2 + x
            let highestPoint = CGPoint(x: centerX, y: highY)
            let lowestPoint = CGPoint(x: centerX, y: lowY)
            
            path.move(to: highestPoint)
            path.addLine(to: CGPoint(x: centerX, y: y))
            path.move(to: lowestPoint)
            path.addLine(to: CGPoint(x: centerX, y: y + h))
            
            let shape = CAShapeLayer()
            shape.contentsScale = UIScreen.main.scale
            shape.path = path.cgPath
            shape.lineWidth = 1
            shape.strokeColor = item.trend == .up ? candleStyle.upColor.cgColor : candleStyle.downColor.cgColor
            shape.fillColor = item.trend == .up ? candleStyle.upColor.cgColor : candleStyle.downColor.cgColor
            
            sublayer.addSublayer(shape)
        }
        
        layer.addSublayer(sublayer)
    }
}
