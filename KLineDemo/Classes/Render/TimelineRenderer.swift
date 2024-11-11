//
//  TimelineRenderer.swift
//  KLineDemo
//
//  Created by iya on 2024/11/7.
//

import UIKit

class TimelineRenderer: ChartRenderer, CandlestickStyleConfigurable {
    
    typealias Item = KLineItem
    
    var style: CandleStyle
    
    init(style: CandleStyle) {
        self.style = style
    }
    
    func draw(in layer: CALayer, rect: CGRect, transformer: any ChartTransformer, items: [Item], range: Range<Int>) {

        let sublayer = CALayer()
        sublayer.frame = rect
        sublayer.contentsScale = UIScreen.main.scale
                
        let visiableItems = Array(items[range])
        let labelInterval = 6  // 控制标签密度，约 6 个标签
        let labelWidth = rect.width / CGFloat(labelInterval - 1)
        let itemWdith = style.lineWidth + style.gap
        
        
        
//        if rect.minX > 0 {
//            let unvisiableCount = Int(ceil(rect.width / (style.lineWidth + style.gap))) - range.upperBound + 1
//            for idx in (range.lowerBound + unvisiableCount..<range.upperBound + unvisiableCount)  where idx.isMultiple(of: labelInterval) {
//                let x =  transformer.transformX(index: idx)
//                
//                let item = visiableItems[idx - unvisiableCount]
//                
//                // 创建并配置时间标签
//                let date = Date(timeIntervalSince1970: TimeInterval(item.timestamp))
//                let dateFormatter = DateFormatter()
//                dateFormatter.dateFormat = "MM-dd HH:mm"
//                let timeString = dateFormatter.string(from: date)
//                            
//                let textLayer = CATextLayer()
//                textLayer.string = timeString
//                textLayer.font = CTFontCreateWithName("Roboto Mono" as CFString, 9, nil)
//                textLayer.fontSize = 9
//                textLayer.foregroundColor = UIColor.secondaryLabel.cgColor
//                textLayer.alignmentMode = .center
//                textLayer.contentsScale = UIScreen.main.scale
//                
//                let labelX = x - (labelWidth) / 2
//                textLayer.frame = CGRect(x: labelX - rect.origin.x, y: (rect.height - 12) * 0.5, width: labelWidth, height: 10)
//                sublayer.addSublayer(textLayer)
//            }
//        } else {
//            for (idx, item) in visiableItems.enumerated() where idx.isMultiple(of: labelInterval) {
//                let x =  transformer.transformX(index: idx)
//                
//                // 创建并配置时间标签
//                let date = Date(timeIntervalSince1970: TimeInterval(item.timestamp))
//                let dateFormatter = DateFormatter()
//                dateFormatter.dateFormat = "MM-dd HH:mm"
//                let timeString = dateFormatter.string(from: date)
//                            
//                let textLayer = CATextLayer()
//                textLayer.string = timeString
//                textLayer.font = CTFontCreateWithName("Roboto Mono" as CFString, 9, nil)
//                textLayer.fontSize = 9
//                textLayer.foregroundColor = UIColor.secondaryLabel.cgColor
//                textLayer.alignmentMode = .center
//                textLayer.contentsScale = UIScreen.main.scale
//                
//                let labelX = x - (labelWidth + style.lineWidth + style.gap) / 2
//                textLayer.frame = CGRect(x: labelX - rect.origin.x, y: (rect.height - 12) * 0.5, width: labelWidth, height: 10)
//                sublayer.addSublayer(textLayer)
//            }
//        }
        
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

import SwiftUI

@available(iOS 17.0, *)
#Preview {
    ViewController()
}
