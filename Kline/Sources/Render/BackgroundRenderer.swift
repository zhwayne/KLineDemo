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
        let transformer = context.transformer
        let viewPort = transformer.viewPort
        let rect = CGRectMake(0, viewPort.minY, layer.bounds.width, viewPort.height)
        
        let sublayer = CALayer()
        sublayer.frame = rect
        sublayer.contentsScale = UIScreen.main.scale
        
        let gridLayer = CAShapeLayer()
        gridLayer.lineWidth = 1 / UIScreen.main.scale
        gridLayer.fillColor = UIColor.clear.cgColor
        gridLayer.strokeColor = UIColor.secondarySystemFill.cgColor
        gridLayer.contentsScale = UIScreen.main.scale
        
        let gridColumns = 6
        let columnWidth = rect.width / CGFloat(gridColumns - 1)
        
        // MARK: - 绘制列
        // (不包含第一列和最后一列)
        let path = UIBezierPath()
        for idx in (1..<gridColumns - 1) {
            let x = CGFloat(idx) * columnWidth
            let start = CGPoint(x: x, y: 0)
            let end = CGPoint(x: x, y: layer.bounds.height)
            path.move(to: start)
            path.addLine(to: end)
        }

        // MARK: - 绘制行
        // 生成等分价格线
        let dataBounds = transformer.dataBounds
        let (stepSize, _) = calculateGridSteps(
            min: dataBounds.minimum,
            max: dataBounds.maximum,
            maxLines: 8
        )
        let verticalInset = VerticalInset(top: 8, bottom: 8)
        var currentValue = floor(dataBounds.minimum / stepSize) * stepSize
        var y: CGFloat = rect.maxY
        while y > 0 {
            defer {
                currentValue += stepSize
            }
            y = transformer.transformY(
                value: currentValue,
                inset: verticalInset // 和主图数据范围留白保持一致
            )
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
            
            // 添加 文本显示
            let textLayer = CATextLayer()
            textLayer.fontSize = 11
            textLayer.foregroundColor = UIColor.secondaryLabel.cgColor
            textLayer.alignmentMode = .center
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.string = formatter.string(for: currentValue)
            let textSize = textLayer.preferredFrameSize()
            let textOrigin = CGPoint(
                x: rect.width - 12 - textSize.width,
                y: y - textSize.height - 2
            )
            textLayer.frame = CGRect(origin: textOrigin, size: textSize)
            textLayer.zPosition = 1
            layer.addSublayer(textLayer)
        }
        
        gridLayer.path = path.cgPath
        sublayer.addSublayer(gridLayer)
        layer.addSublayer(sublayer)
    }
    
    // 智能网格步长计算
    private func calculateGridSteps(min: Double, max: Double, maxLines: Int) -> (step: Double, count: Int) {
        let range = max - min
        guard range > 0, maxLines > 0 else { return (0, 0) }
        
        // 计算初始估算步长
        let roughStep = range / Double(maxLines)
        
        // 计算数量级
        let magnitude = pow(10, floor(log10(roughStep)))
        let normalizedStep = roughStep / magnitude
        
        // 选择最接近的标准步长
        let niceSteps: [Double] = [0.1, 0.2, 0.25, 0.5, 1.0, 2.0, 2.5, 5.0, 10.0]
        let chosenStep = niceSteps.first { $0 >= normalizedStep } ?? normalizedStep
        
        let actualStep = chosenStep * magnitude
        let stepCount = Int(ceil(range / actualStep))
        
        return (actualStep, Swift.min(stepCount, maxLines))
    }
}

private let formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 4
    formatter.minimumFractionDigits = 2
    return formatter
}()
