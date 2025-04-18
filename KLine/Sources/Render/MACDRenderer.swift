//
//  MACDRenderer.swift
//  KLine
//
//  Created by iya on 2025/4/1.
//

import UIKit

final class MACDRenderer: IndicatorRenderer {
    
    private var styleManager: StyleManager { .shared }
    private let lineWidth = 1 / UIScreen.main.scale
    var transformer: Transformer?
    
    var type: IndicatorType { .macd }
    
    typealias Item = IndicatorData
    
    func draw(in layer: CALayer, data: RenderData<IndicatorData>) {
        guard var transformer = transformer,
              case .macd = type.keys[0],
              let indicatorStyle = styleManager.indicatorStyle(for: type.keys[0], type: MACDStyle.self) else {
            return
        }
        let maxValue = max(abs(transformer.dataBounds.min), abs(transformer.dataBounds.max))
        transformer.dataBounds.combine(other: MetricBounds(max: maxValue, min: -maxValue))
        self.transformer = transformer
        
        let rect = transformer.viewPort
        let candleStyle = styleManager.candleStyle
        let visibleItems = data.visibleItems
        
        guard let item = data.selectedItem ?? visibleItems.last else { return }
        let key = type.keys[0]
        let indicatorValues = data.visibleItems.map {
            $0.indicator(forKey: key) as? MACDIndicatorValue
        }
        guard let selectedValue = item.indicator(forKey: key) as? MACDIndicatorValue else {
            return
        }
        
        let sublayer = CAShapeLayer()
        sublayer.frame = rect
        sublayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(sublayer)
        
        // MARK: - 网格线（列）
        drawColumnBackground(in: layer, viewPort: transformer.viewPort)
        
        // MARK: - 柱状图
        for (idx, value) in indicatorValues.enumerated() {
            guard let value else { continue }
            let shape = CAShapeLayer()
            shape.lineWidth = 1
            shape.contentsScale = UIScreen.main.scale
            let x = transformer.xAxis(at: idx)
            
            let y1 = transformer.yAxis(for: value.histogram > 0 ? value.histogram : 0)
            let y2 = transformer.yAxis(for: value.histogram > 0 ? 0 : value.histogram)
            let height = max(y2 - y1, 0)
            let rect = CGRect(x: x, y: y1, width: candleStyle.width, height: height)
            let path = UIBezierPath(rect: rect)
            shape.path = path.cgPath
            
            var isFillMode = true
            var color = KLineTrend.rising.color
            if idx > 0, let previousValue = indicatorValues[idx - 1] {
                if value.histogram < previousValue.histogram {
                    isFillMode = false
                }
                if value.histogram < 0 {
                    color = KLineTrend.falling.color
                }
            }
            shape.strokeColor = color
            if isFillMode {
                shape.fillColor = color
            } else {
                shape.fillColor = UIColor.clear.cgColor
            }
            
            sublayer.addSublayer(shape)
        }
        
        
        // MARK: - 折线图
        let drawLine: (UIColor, [Double?]) -> Void = { color, values in
            let indicatorLayer = CAShapeLayer()
            indicatorLayer.contentsScale = UIScreen.main.scale
            indicatorLayer.lineWidth = 1
            indicatorLayer.fillColor = UIColor.clear.cgColor
            indicatorLayer.strokeColor = color.cgColor
            
            let path = UIBezierPath()
            var hasStartPoint = false
            for (idx, value) in values.enumerated() {
                guard let value else { continue }
                // 计算 x 坐标
                let x = transformer.xAxis(at: idx) + candleStyle.width * 0.5
                let y = transformer.yAxis(for: value)
                let point = CGPoint(x: x, y: y)
                
                if !hasStartPoint {
                    path.move(to: point)
                    hasStartPoint = true
                } else {
                    path.addLine(to: point)
                }
            }
            
            indicatorLayer.path = path.cgPath
            sublayer.addSublayer(indicatorLayer)
        }
        
        drawLine(UIColor.systemPink, indicatorValues.map(\.?.macd))
        drawLine(UIColor.systemOrange, indicatorValues.map(\.?.signal))
        
        // MARK: - 标题
        let attrText = NSMutableAttributedString()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.1
        let font = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        let macdText = NSAttributedString(
            string: "MACD:\(styleManager.format(value: selectedValue.histogram))  ",
            attributes: [
                .foregroundColor: indicatorStyle.macdColor.cgColor,
                .font: font,
                .paragraphStyle: paragraphStyle
            ]
        )
        attrText.append(macdText)
        let difText = NSAttributedString(
            string: "DIF:\(styleManager.format(value: selectedValue.macd))  ",
            attributes: [
                .foregroundColor: indicatorStyle.difColor.cgColor,
                .font: font,
                .paragraphStyle: paragraphStyle
            ]
        )
        attrText.append(difText)
        let deaText = NSAttributedString(
            string: "DEA:\(styleManager.format(value: selectedValue.signal))  ",
            attributes: [
                .foregroundColor: indicatorStyle.deaColor.cgColor,
                .font: font,
                .paragraphStyle: paragraphStyle
            ]
        )
        attrText.append(deaText)
        
        let legendLayer = CATextLayer()
        legendLayer.contentsScale = UIScreen.main.scale
        legendLayer.alignmentMode = .left
        legendLayer.string = attrText
        let size = legendLayer.preferredFrameSize()
        legendLayer.frame = CGRect(x: 12, y: rect.minY + 8, width: size.width, height: size.height)
        layer.addSublayer(legendLayer)
        
        // MARK: - 边界线
        
        let bottomLineLayer = CAShapeLayer()
        bottomLineLayer.lineWidth = lineWidth
        bottomLineLayer.fillColor = UIColor.clear.cgColor
        bottomLineLayer.strokeColor = UIColor.separator.cgColor
        let bottomLinePath = UIBezierPath()
        bottomLinePath.move(to: CGPoint(x: 0, y: rect.maxY - lineWidth))
        bottomLinePath.addLine(to: CGPoint(x: layer.bounds.maxX, y: rect.maxY - lineWidth))
        bottomLineLayer.path = bottomLinePath.cgPath
        layer.addSublayer(bottomLineLayer)
    }
}
