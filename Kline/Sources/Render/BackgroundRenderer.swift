//
//  BackgroundRenderer.swift
//  KLine
//
//  Created by work on 2025/3/25.
//

import UIKit

struct BackgroundRenderer: ChartRenderer {
    typealias Item = KLineItem
    
    func draw(in layer: CALayer, context: RenderContext<KLineItem>) {
        let rect = layer.bounds
        let transformer = context.transformer
        
        let sublayer = CAShapeLayer()
        sublayer.lineWidth = 1 / UIScreen.main.scale
        sublayer.fillColor = UIColor.clear.cgColor
        sublayer.strokeColor = UIColor.systemFill.cgColor
        sublayer.contentsScale = UIScreen.main.scale
        
        let gridColumns = 6
        let columnWidth = rect.width / CGFloat(gridColumns - 1)
        
        // 绘制列(不包含第一列和最后一列)
        let path = UIBezierPath()
        for idx in (1..<gridColumns - 1) {
            let x = CGFloat(idx) * columnWidth
            let start = CGPoint(x: x, y: 0)
            let end = CGPoint(x: x, y: layer.bounds.height)
            path.move(to: start)
            path.addLine(to: end)
        }
        
//        // 绘制行，于价格差计算步长和行数
//        let (stepSize, numberOfRows) = calculateGridParameters(
//            min: transformer.dataBounds.minimum,
//            max: transformer.dataBounds.maximum,
//            maxLines: 8 // 最大允许行数
//        )
//        
//        var currentLevel = ceil(transformer.dataBounds.minimum / stepSize) * stepSize
//        while currentLevel < transformer.dataBounds.maximum {
//            let y = transformer.transformY(value: currentLevel)
//            path.move(to: CGPoint(x: 0, y: y))
//            path.addLine(to: CGPoint(x: rect.width, y: y))
//            currentLevel += stepSize
//        }
        
        sublayer.path = path.cgPath
        layer.addSublayer(sublayer)
    }
    
    /// 自动计算最佳步长和行数
    private func calculateGridParameters(min: Double, max: Double, maxLines: Int) -> (step: Double, count: Int) {
        let range = niceNumber(max - min, round: true)
        let stepSize = niceNumber(range / Double(maxLines), round: true)
        let count = Int(range / stepSize)
        return (stepSize, Swift.min(count, maxLines))
    }
    
    /// Nice Numbers算法实现
    private func niceNumber(_ value: Double, round: Bool) -> Double {
        let exponent = floor(log10(value))
        let fraction = value / pow(10, exponent)
        
        let niceFraction: Double
        if round {
            niceFraction = fraction >= 1.5 ? 2.0 :
            fraction >= 1.0 ? 1.0 :
            fraction >= 0.5 ? 0.5 : 0.1
        } else {
            niceFraction = fraction <= 1.0 ? 1.0 :
            fraction <= 2.0 ? 2.0 :
            fraction <= 5.0 ? 5.0 : 10.0
        }
        return niceFraction * pow(10, exponent)
    }
}

