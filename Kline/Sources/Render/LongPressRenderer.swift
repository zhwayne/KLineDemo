//
//  LongPressRenderer.swift
//  KLine
//
//  Created by work on 2025/3/28.
//

import UIKit

final class LongPressRenderer: ChartRenderer {
    
    let layer = CALayer()
    
    private let dateLabel = UILabel()
    private let dateFormatter: DateFormatter
    var location: CGPoint = .zero
    var transformer: Transformer?
    var timelineY: CGFloat = 0
    var timelineHeight: CGFloat = 0
    
    typealias Item = IndicatorData
    
    init() {
        dateLabel.font = .monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        dateLabel.textAlignment = .center
        dateLabel.backgroundColor = .label
        dateLabel.textColor = .systemBackground
        dateLabel.layer.cornerRadius = 4
        dateLabel.layer.masksToBounds = true
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
    }
    
    func clean() {
        if layer.superlayer != nil {
            layer.removeFromSuperlayer()
            layer.sublayers = nil
        }
    }
    
    func draw(in layer: CALayer, data: RenderData<IndicatorData>) {
        guard let transformer = transformer else { return }
        let rect = layer.bounds
        
        // MARK: - 绘制y轴虚线
        let dashLine = CAShapeLayer()
        dashLine.strokeColor = UIColor.label.cgColor
        dashLine.lineWidth = 1 / UIScreen.main.scale
        dashLine.lineDashPattern = [2, 2]
        let path = UIBezierPath()
        path.move(to: CGPoint(x: location.x, y: 0))
        path.addLine(to: CGPoint(x: location.x, y: rect.height))
        dashLine.path = path.cgPath
        layer.addSublayer(dashLine)
        
        // MARK: - 绘制日期时间轴
        if let index = transformer.indexOfVisibleItem(at: location.x) {
            let item = data.items[index].item
            let date = Date(timeIntervalSince1970: TimeInterval(item.timestamp))
            let timeString = dateFormatter.string(from: date)
            dateLabel.text = timeString
            var size = dateLabel.systemLayoutSizeFitting(rect.size)
            size.width += 8
            var x = location.x - size.width * 0.5
            x = max(0, min(x, rect.width - size.width))
            dateLabel.frame = CGRect(x: x, y: timelineY, width: size.width, height: timelineHeight)
            layer.addSublayer(dateLabel.layer)
        } else {
            
        }
    }
}
