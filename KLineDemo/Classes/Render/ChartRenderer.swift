//
//  ChartRenderer.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import UIKit

struct RenderContext {
    let transformer: Transformer
    let candleStyle: CandleStyle
    let chartStyle: ChartStyle?
}

/// 定义绘制器协议 KLineRenderer，每种 Renderer 单独负责一种绘制任务，KLineView 通过聚合多个 Renderer 来实现多种绘制效果。
protocol ChartRenderer {
    
    associatedtype Item
        
    func draw(in layer: CALayer, items: [Item], indices: Range<Int>, context: RenderContext)
}

protocol IndicatorRender: ChartRenderer {
    
    var key: IndicatorKey { get }
}

struct AnyIndicatorRenderer<T>: IndicatorRender {
    typealias Item = T
    let key: IndicatorKey
    
    private let _draw: (CALayer, [T], Range<Int>, RenderContext) -> Void
    
    init<R: IndicatorRender>(_ renderer: R) where R.Item == T {
        self.key = renderer.key
        self._draw = renderer.draw
    }
    
    func draw(in layer: CALayer, items: [T], indices: Range<Int>, context: RenderContext) {
        _draw(layer, items, indices, context)
    }
}
