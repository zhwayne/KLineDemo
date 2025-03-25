//
//  CandleRenderer.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import UIKit

struct CandleRenderer: ChartRenderer {
    
    typealias Item = KLineItem
    typealias Style = CandleStyle
    
    func draw(in layer: CALayer, context: RenderContext<KLineItem>) {
        let transformer = context.transformer
        let rect = transformer.viewPort
        let candleStyle = context.styleManager.candleStyle
        let items = context.items
        
        let sublayer = CALayer()
        sublayer.frame = rect
        sublayer.contentsScale = UIScreen.main.scale
        
        let verticalInset = VerticalInset(top: 8, bottom: 8)
        
        for (idx, item) in items.enumerated() {
            // 计算 x 坐标
            let x = transformer.transformX(at: idx)
            
            // 计算开盘价和收盘价的 y 坐标
            let openY = transformer.transformY(value: item.opening, inset: verticalInset)
            let closeY = transformer.transformY(value: item.closing, inset: verticalInset)
            let y = min(openY, closeY)
            let h = abs(openY - closeY)
            
            let rect = CGRect(x: x, y: y, width: candleStyle.width, height: h)
            let path = UIBezierPath(rect: rect)
            
            // 计算最高价和最低价的 y 坐标
            let highY = transformer.transformY(value: item.highest, inset: verticalInset)
            let lowY = transformer.transformY(value: item.lowest, inset: verticalInset)
            
            let centerX = candleStyle.width / 2 + x
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
        
        // 最高价指示
        if let item = items.max(by: { $0.highest < $1.highest }),
           let index = items.firstIndex(of: item) {
            let x = transformer.transformX(at: index) + candleStyle.width * 0.5
            let y = transformer.transformY(value: item.highest, inset: verticalInset)
            
            let rightSide = (x + transformer.viewPort.origin.x) < layer.bounds.midX
            let startPoint = CGPoint(x: x, y: y)
            let endPoint = CGPoint(x: x + (rightSide ? 30 : -30 ), y: y)
            
            let linePath = UIBezierPath()
            linePath.move(to: startPoint)
            linePath.addLine(to: endPoint)
            
            let lineLayer = CAShapeLayer()
            lineLayer.lineWidth = 1
            lineLayer.strokeColor = UIColor.secondaryLabel.cgColor
            lineLayer.path = linePath.cgPath
            
            let textLayer = CATextLayer()
            textLayer.fontSize = 11
            textLayer.foregroundColor = UIColor.secondaryLabel.cgColor
            textLayer.alignmentMode = .center
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.string = formatter.string(for: item.highest)
            let textSize = textLayer.preferredFrameSize()
            let textOrigin = CGPoint(
                x: endPoint.x + (rightSide ? 0 : -textSize.width),
                y: y - textSize.height * 0.5
            )
            textLayer.frame = CGRect(origin: textOrigin, size: textSize)
            
            sublayer.addSublayer(lineLayer)
            sublayer.addSublayer(textLayer)
        }
        
        if let item = items.max(by: { $0.lowest > $1.lowest }),
           let index = items.firstIndex(of: item) {
            let x = transformer.transformX(at: index) + candleStyle.width * 0.5
            let y = transformer.transformY(value: item.lowest, inset: verticalInset)
            
            let rightSide = (x + transformer.viewPort.origin.x) < layer.bounds.midX
            let startPoint = CGPoint(x: x, y: y)
            let endPoint = CGPoint(x: x + (rightSide ? 30 : -30 ), y: y)
            
            let linePath = UIBezierPath()
            linePath.move(to: startPoint)
            linePath.addLine(to: endPoint)
            
            let lineLayer = CAShapeLayer()
            lineLayer.lineWidth = 1
            lineLayer.strokeColor = UIColor.secondaryLabel.cgColor
            lineLayer.path = linePath.cgPath
            
            let textLayer = CATextLayer()
            textLayer.fontSize = 11
            textLayer.foregroundColor = UIColor.secondaryLabel.cgColor
            textLayer.alignmentMode = .center
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.string = formatter.string(for: item.lowest)
            let textSize = textLayer.preferredFrameSize()
            let textOrigin = CGPoint(
                x: endPoint.x + (rightSide ? 0 : -textSize.width),
                y: y - textSize.height * 0.5
            )
            textLayer.frame = CGRect(origin: textOrigin, size: textSize)
            
            sublayer.addSublayer(lineLayer)
            sublayer.addSublayer(textLayer)
        }
        
        // 最低价指示
        
        layer.addSublayer(sublayer)
    }
}

private let formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 4
    formatter.minimumFractionDigits = 2
    return formatter
}()
