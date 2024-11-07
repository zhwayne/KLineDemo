//
//  ChartRenderer.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import UIKit

/// 定义绘制器协议 KLineRenderer，每种 Renderer 单独负责一种绘制任务，KLineView 通过聚合多个 Renderer 来实现多种绘制效果。
protocol ChartRenderer {
    
    associatedtype Value
        
    func draw(in layer: CALayer, rect: CGRect, transformer: ChartTransformer, values: [Value])
}

/// 类型擦除类 AnyChartRenderer
class AnyChartRenderer<T>: ChartRenderer {
    typealias Value = T
    let key: IndicatorKey  // 新增属性，用于标识 Renderer

    private let _draw: (CALayer, CGRect, ChartTransformer, [T]) -> Void

    init<R: ChartRenderer>(_ renderer: R, id: IndicatorKey) where R.Value == T {
        self.key = id
        self._draw = renderer.draw
    }
    
    func draw(in layer: CALayer, rect: CGRect, transformer: ChartTransformer, values: [Value]) {
        _draw(layer, rect, transformer, values)
    }
}
