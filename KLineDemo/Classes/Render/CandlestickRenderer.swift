//
//  CandlestickRenderer.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import UIKit

class CandlestickRenderer: ChartRenderer {
    
    typealias Value = KLineItem
    
    var style: CandlestickStyle
    
    init(style: CandlestickStyle) {
        self.style = style
    }
    
    func draw(in layer: CALayer, rect: CGRect, transformer: ChartTransformer, values: [Value]) {

        let sublayer = CALayer()
        sublayer.frame = rect
        sublayer.contentsScale = UIScreen.main.scale
        
        let visiableItems = values
        
        for (idx, item) in visiableItems.enumerated() {
            // 计算 x 坐标
            let x = transformer.transformX(index: idx)
    
            // 计算开盘价和收盘价的 y 坐标
            let openY = transformer.transformY(value: item.opening)
            let closeY = transformer.transformY(value: item.closing)
            let y = min(openY, closeY)
            let h = abs(openY - closeY)
            
            let rect = CGRect(x: x, y: y, width: style.lineWidth, height: h)
            let path = UIBezierPath(rect: rect)
            
            // 计算最高价和最低价的 y 坐标
            let highY = transformer.transformY(value: item.highest)
            let lowY = transformer.transformY(value: item.lowest)
            
            let centerX = style.lineWidth / 2 + x
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
            shape.strokeColor = item.trend == .up ? style.upColor.cgColor : style.downColor.cgColor
            shape.fillColor = item.trend == .up ? style.upColor.cgColor : style.downColor.cgColor
            
            sublayer.addSublayer(shape)
        }
        
        layer.addSublayer(sublayer)
    }
}
