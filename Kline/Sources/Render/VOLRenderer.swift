//
//  VOLRenderer.swift
//  KLineDemo
//
//  Created by work on 2025/3/24.
//

import UIKit

final class VOLRenderer: IndicatorRenderer {
    
    var styleManager: StyleManager { .shared }
        
    var transformer: Transformer?
    
    typealias Item = IndicatorData
    
    var type: IndicatorType { .vol }

    func draw(in layer: CALayer, data: RenderData<IndicatorData>) {
        guard let transformer = transformer else { return }
        let rect = transformer.viewPort
        let candleStyle = styleManager.candleStyle
        let indicatorStyle = styleManager.indicatorStyle(for: .vol)
        let items = data.visibleItems
        
        // MARK: - 网格线（列）
        drawColumnBackground(in: layer, viewPort: transformer.viewPort)
        
        let sublayer = CALayer()
        sublayer.frame = rect
        sublayer.contentsScale = UIScreen.main.scale
        
        // MARK: - 标题
        let textLayer = CATextLayer()
        textLayer.font = indicatorStyle.font as CTFont
        textLayer.fontSize = indicatorStyle.font.pointSize
        textLayer.foregroundColor = indicatorStyle.strokeColor.cgColor
        textLayer.alignmentMode = .center
        textLayer.contentsScale = UIScreen.main.scale
        sublayer.addSublayer(textLayer)
        let volume = items.last!.item.volume
        textLayer.string = "VOL:\(styleManager.format(value: volume))"
        let size = textLayer.preferredFrameSize()
        textLayer.frame = CGRect(x: 12, y: rect.minY + 8, width: size.width, height: size.height)
        layer.addSublayer(textLayer)
                
        // MARK: - 折线图
        for (idx, item) in items.enumerated() {
            // 计算 x 坐标
            let x = transformer.xAxis(at: idx)
            let y = transformer.yAxis(for: Double(item.item.volume))
            let rect = CGRect(x: x, y: y, width: candleStyle.width, height: rect.height - y - 2)
            let path = UIBezierPath(rect: rect)
            
            let shape = CAShapeLayer()
            shape.contentsScale = UIScreen.main.scale
            shape.path = path.cgPath
            shape.strokeColor = item.item.trend == .up ? candleStyle.upColor.cgColor : candleStyle.downColor.cgColor
            shape.fillColor = item.item.trend == .up ? candleStyle.upColor.cgColor : candleStyle.downColor.cgColor
            shape.opacity = 0.5
            
            sublayer.addSublayer(shape)
        }
        
        layer.addSublayer(sublayer)
        
        let lineHeight = 1 / UIScreen.main.scale
        let bottomLinePath = UIBezierPath()
        bottomLinePath.move(to: CGPoint(x: 0, y: rect.maxY - lineHeight))
        bottomLinePath.addLine(to: CGPoint(x: layer.bounds.maxX, y: rect.maxY - lineHeight))

        let bottomLineLayer = CAShapeLayer()
        bottomLineLayer.path = bottomLinePath.cgPath
        bottomLineLayer.lineWidth = lineHeight
        bottomLineLayer.fillColor = UIColor.clear.cgColor
        bottomLineLayer.strokeColor = UIColor.separator.cgColor
        layer.addSublayer(bottomLineLayer)
    }
}
