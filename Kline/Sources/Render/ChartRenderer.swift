//
//  ChartRenderer.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import UIKit

struct RenderContext<T> {
    let transformer: Transformer
    let items: [T]
    let indices: Range<Int>
    let styleManager: StyleManager
}

/// 定义绘制器协议 KLineRenderer，每种 Renderer 单独负责一种绘制任务，KLineView 通过聚合多个 Renderer 来实现多种绘制效果。
@MainActor protocol ChartRenderer {
    
    associatedtype Item
    
    func draw(in layer: CALayer, context: RenderContext<Item>)
}

protocol IndicatorRenderer: ChartRenderer {
    
    var type: IndicatorType { get }
}

//extension ChartRenderer {
//    
//    func drawColumnBackground(in layer: CALayer) {
//        // (不包含第一列和最后一列)
//        let gridLayer = CAShapeLayer()
//        gridLayer.lineWidth = 1 / UIScreen.main.scale
//        gridLayer.fillColor = UIColor.clear.cgColor
//        gridLayer.strokeColor = UIColor.secondarySystemFill.cgColor
//        gridLayer.contentsScale = UIScreen.main.scale
//        
//        let gridColumns = 6
//        let columnWidth = layer.bounds.width / CGFloat(gridColumns - 1)
//        
//        let path = UIBezierPath()
//        for idx in (1..<gridColumns - 1) {
//            let x = CGFloat(idx) * columnWidth
//            let start = CGPoint(x: x, y: 0)
//            let end = CGPoint(x: x, y: layer.bounds.height)
//            path.move(to: start)
//            path.addLine(to: end)
//        }
//        
//        gridLayer.path = path.cgPath
//        layer.addSublayer(gridLayer)
//    }
//}

struct AnyIndicatorRenderer<T>: IndicatorRenderer {
    typealias Item = T
    let type: IndicatorType
    
    private let _draw: (CALayer, RenderContext<T>) -> Void
    
    init<R: IndicatorRenderer>(_ renderer: R) where R.Item == T {
        self.type = renderer.type
        self._draw = renderer.draw
    }
    
    func draw(in layer: CALayer, context: RenderContext<T>) {
        _draw(layer, context)
    }
}
