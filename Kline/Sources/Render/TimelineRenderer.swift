//
//  TimelineRenderer.swift
//  KLineDemo
//
//  Created by iya on 2024/11/7.
//

import UIKit

final class TimelineRenderer: ChartRenderer {
    
    var styleManager: StyleManager { .shared }
        
    var transformer: Transformer?
    
    private let dateLabels: [UILabel]
    
    private let dateFormatter = DateFormatter()
    
    typealias Item = KLineItem
    
    init() {
        dateLabels = (0..<6).map({ idx in
            let label = UILabel()
            label.font = .monospacedDigitSystemFont(ofSize: 10, weight: .regular)
            label.textAlignment = .center
            label.textColor = UIColor.secondaryLabel
            return label
        })
        
        dateFormatter.dateFormat = "MM/dd HH:mm"
    }
   
    func draw(in layer: CALayer, data: RenderData<KLineItem>) {
        guard let transformer = transformer else { return }
        let rect = layer.bounds
        
        let sublayer = CALayer()
        sublayer.frame = rect
        sublayer.contentsScale = UIScreen.main.scale
        
        // 时间 label 位置固定
        let labelCount = 6  // 控制标签密度，约 6 个标签
        let labelWidth = rect.width / CGFloat(labelCount - 1)
       
        
        for idx in (0..<labelCount) {
            let label = dateLabels[idx]
            label.bounds = CGRect(x: 0, y: 0, width: labelWidth - 4, height: rect.height)
            label.center = CGPoint(x: CGFloat(idx) * labelWidth, y: rect.midY)
            
            if let index = transformer.indexOfVisibleItem(at: label.center.x) {
                let item = data.items[index]
                let date = Date(timeIntervalSince1970: TimeInterval(item.timestamp))
                let timeString = dateFormatter.string(from: date)
                label.text = timeString
            } else {
                label.text = nil
            }
            
            layer.addSublayer(label.layer)
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
