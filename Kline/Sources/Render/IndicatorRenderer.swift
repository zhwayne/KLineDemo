//
//  IndicatorRenderer.swift
//  KLine
//
//  Created by work on 2025/3/27.
//

import UIKit

protocol IndicatorRenderer: ChartRenderer {
    
    var type: IndicatorType { get }
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
