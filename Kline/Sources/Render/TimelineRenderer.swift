//
//  TimelineRenderer.swift
//  KLineDemo
//
//  Created by iya on 2024/11/7.
//

import UIKit

struct TimelineRenderer: ChartRenderer {
    
    typealias Item = KLineItem
    
    func draw(in layer: CALayer, context: RenderContext<KLineItem>) {
        let rect = layer.bounds
        let transformer = context.transformer
        let items = context.items
        let indices = context.indices
        
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
            textLayer.font = CTFontCreateWithName("Roboto Mono" as CFString, 11, nil)
            textLayer.fontSize = 11
            textLayer.foregroundColor = UIColor.secondaryLabel.cgColor
            textLayer.alignmentMode = .center
            textLayer.contentsScale = UIScreen.main.scale
            sublayer.addSublayer(textLayer)
            textLayer.bounds = CGRect(x: 0, y: 0, width: labelWidth, height: 11)
            textLayer.position = CGPoint(x: CGFloat(idx) * labelWidth, y: rect.midY - 1)
            
            let index = Int(ceil(textLayer.position.x / transformer.itemWidth))

            if index >= 0 && index < adjustedItems.count, let item = adjustedItems[index] {
                let date = Date(timeIntervalSince1970: TimeInterval(item.timestamp))
                let timeString = dateFormatter.string(from: date)
                textLayer.string = timeString
            } else {
                textLayer.string = nil
            }
        }
        
        let lineHeight = 1 / UIScreen.main.scale
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: 0, y: lineHeight))
        linePath.addLine(to: CGPoint(x: rect.maxX, y: lineHeight))
        linePath.move(to: CGPoint(x: 0, y: rect.height - lineHeight))
        linePath.addLine(to: CGPoint(x: rect.maxX, y: rect.height - lineHeight))
        
        let lineLayer = CAShapeLayer()
        lineLayer.path = linePath.cgPath
        lineLayer.lineWidth = lineHeight
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.strokeColor = UIColor.separator.cgColor
        sublayer.addSublayer(lineLayer)
        
        layer.addSublayer(sublayer)
    }
}
