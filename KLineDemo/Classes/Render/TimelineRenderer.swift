//
//  TimelineRenderer.swift
//  KLineDemo
//
//  Created by iya on 2024/11/7.
//

import UIKit

struct TimelineRenderer: ChartRenderer {
    
    typealias Item = KLineItem
    
    func draw(in layer: CALayer, items: [KLineItem], indices: Range<Int>, context: RenderContext) {
        let rect = layer.bounds
        let transformer = context.transformer
        
        let sublayer = CALayer()
        sublayer.frame = rect
        sublayer.contentsScale = UIScreen.main.scale
        
        // 时间 label 位置固定
        let labelCount = 6  // 控制标签密度，约 6 个标签
        let labelWidth = rect.width / CGFloat(labelCount - 1)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd HH:mm"
        
        // 网 items 中塞入 nil，以保证和 indices 元素数量相等
        var adjustedItems: [KLineItem?] = items
        indices.forEach { idx in
            if idx < 0 {
                adjustedItems.insert(nil, at: 0)
            } else if  idx >= items.count {
                adjustedItems.append(nil)
            }
        }
        for idx in (0..<labelCount) {
            
            let textLayer = CATextLayer()
            textLayer.font = CTFontCreateWithName("Roboto Mono" as CFString, 9, nil)
            textLayer.fontSize = 10
            textLayer.foregroundColor = UIColor.secondaryLabel.cgColor
            textLayer.alignmentMode = .center
            textLayer.contentsScale = UIScreen.main.scale
            sublayer.addSublayer(textLayer)
            textLayer.bounds = CGRect(x: 0, y: 0, width: labelWidth, height: 10)
            textLayer.position = CGPoint(x: CGFloat(idx) * labelWidth, y: rect.midY)
            
            let index = transformer.transformIndex(offset: textLayer.position.x)

            if index >= 0 && index < adjustedItems.count, let item = adjustedItems[index] {
                let date = Date(timeIntervalSince1970: TimeInterval(item.timestamp))
                let timeString = dateFormatter.string(from: date)
                textLayer.string = timeString
            } else {
                textLayer.string = nil
            }
        }
        
        let topLinePath = UIBezierPath()
        topLinePath.move(to: CGPoint(x: -rect.origin.x, y: 0))
        topLinePath.addLine(to: CGPoint(x: rect.maxX, y: 0))
        
        let topLineLayer = CAShapeLayer()
        topLineLayer.path = topLinePath.cgPath
        topLineLayer.lineWidth = 1 / UIScreen.main.scale
        topLineLayer.fillColor = UIColor.clear.cgColor
        topLineLayer.strokeColor = UIColor.separator.cgColor
        sublayer.addSublayer(topLineLayer)
        
        let bottomLinePath = UIBezierPath()
        bottomLinePath.move(to: CGPoint(x: -rect.origin.x, y: rect.height - 1))
        bottomLinePath.addLine(to: CGPoint(x: rect.maxX, y: rect.height))
        
        let bottomLineLayer = CAShapeLayer()
        bottomLineLayer.path = bottomLinePath.cgPath
        bottomLineLayer.lineWidth = 1 / UIScreen.main.scale
        bottomLineLayer.fillColor = UIColor.clear.cgColor
        bottomLineLayer.strokeColor = UIColor.separator.cgColor
        sublayer.addSublayer(bottomLineLayer)
        
        layer.addSublayer(sublayer)
    }
}
