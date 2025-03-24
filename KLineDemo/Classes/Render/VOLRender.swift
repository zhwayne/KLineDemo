//
//  VOLRender.swift
//  KLineDemo
//
//  Created by work on 2025/3/24.
//

import UIKit

struct VOLRender: IndicatorRenderer {
    
    typealias Item = IndicatorData
    
    var type: IndicatorType { .vol }
    
    func draw(in layer: CALayer, items: [IndicatorData], indices: Range<Int>, context: RenderContext) {
        let transformer = context.transformer
        let rect = transformer.viewPort
        let candleStyle = context.styleManager.candleStyle
        
        let sublayer = CALayer()
        sublayer.frame = rect
        sublayer.contentsScale = UIScreen.main.scale
        
        // 文字
        let textLayer = CATextLayer()
        textLayer.fontSize = 10
        textLayer.foregroundColor = UIColor.secondaryLabel.cgColor
        textLayer.alignmentMode = .center
        textLayer.contentsScale = UIScreen.main.scale
        sublayer.addSublayer(textLayer)
        textLayer.string = "VOL(XXX):\(items.last!.item.volume)"
        let size = textLayer.preferredFrameSize()
        textLayer.frame = CGRect(x: 16, y: 8, width: size.width, height: size.height)
        layer.addSublayer(textLayer)
        
        for (idx, item) in items.enumerated() {
            // 计算 x 坐标
            let x = transformer.transformX(at: idx)
            
            let y = transformer.transformY(value: Double(item.item.volume)) + textLayer.frame.maxY + 8
            let rect = CGRect(x: x, y: y, width: candleStyle.lineWidth, height: rect.height - y)
            let path = UIBezierPath(rect: rect)
            
            let shape = CAShapeLayer()
            shape.contentsScale = UIScreen.main.scale
            shape.path = path.cgPath
            shape.strokeColor = item.item.trend == .up ? candleStyle.upColor.cgColor : candleStyle.downColor.cgColor
            shape.fillColor = item.item.trend == .up ? candleStyle.upColor.cgColor : candleStyle.downColor.cgColor
            
            sublayer.addSublayer(shape)
        }
        
        layer.addSublayer(sublayer)
    }
}
