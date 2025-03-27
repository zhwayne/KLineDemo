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
    let visibleRange: Range<Int>
    let indices: Range<Int>
    let styleManager: StyleManager
    let canvansView: UIView
    
    var visibleItems: [T] { Array(items[visibleRange]) }
    
    fileprivate var itemType: Any.Type { T.self } // 直接反射泛型类型
}

/// 定义绘制器协议 KLineRenderer，每种 Renderer 单独负责一种绘制任务，KLineView 通过聚合多个 Renderer 来实现多种绘制效果。
@MainActor protocol ChartRenderer {
    
    associatedtype Item
    
    func draw(in layer: CALayer, context: RenderContext<Item>)
}

protocol IndicatorRenderer: ChartRenderer {
    
    var type: IndicatorType { get }
}

extension ChartRenderer {
    
    func drawColumnBackground(in layer: CALayer, viewPort: CGRect) {
        let rect = CGRectMake(0, viewPort.minY, layer.bounds.width, viewPort.height)
        // (不包含第一列和最后一列)
        let gridLayer = CAShapeLayer()
        gridLayer.lineWidth = 1 / UIScreen.main.scale
        gridLayer.fillColor = UIColor.clear.cgColor
        gridLayer.strokeColor = UIColor.systemFill.cgColor
        gridLayer.contentsScale = UIScreen.main.scale
        
        let gridColumns = 6
        let columnWidth = rect.width / CGFloat(gridColumns - 1)
        
        let path = UIBezierPath()
        for idx in (1..<gridColumns - 1) {
            let x = CGFloat(idx) * columnWidth
            let start = CGPoint(x: x, y: rect.minY)
            let end = CGPoint(x: x, y: rect.maxY)
            path.move(to: start)
            path.addLine(to: end)
        }
        
        gridLayer.path = path.cgPath
        layer.addSublayer(gridLayer)
    }
}

struct AnyIndicatorRenderer: IndicatorRenderer {
    let type: IndicatorType
    
    private let _draw: (CALayer, RenderContext<Any>) -> Void
    
    fileprivate init<R: IndicatorRenderer>(_ renderer: R) {
        self.type = renderer.type
        self._draw = { layer, context in
            guard let items = context.items as? [R.Item] else {
                fatalError("Type mismatch. Expected: \(R.Item.self), Actual: \(context.itemType)")
            }
            let concreteContext = RenderContext(
                transformer: context.transformer,
                items: items,
                visibleRange: context.visibleRange,
                indices: context.indices,
                styleManager: context.styleManager,
                canvansView: context.canvansView
            )
            renderer.draw(in: layer, context: concreteContext)
        }
    }
    
    func draw(in layer: CALayer, context: RenderContext<Any>) {
        _draw(layer, context)
    }
}

extension IndicatorRenderer {
    
    func eraseToAnyRenderer() -> AnyIndicatorRenderer {
        AnyIndicatorRenderer(self)
    }
}
