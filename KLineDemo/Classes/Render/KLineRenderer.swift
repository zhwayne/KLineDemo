//
//  KLineRenderer.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import UIKit

/// 定义绘制器协议 KLineRenderer，每种 Renderer 单独负责一种绘制任务，KLineView 通过聚合多个 Renderer 来实现多种绘制效果。
protocol KLineRenderer {
    
    var styleConfig: StyleConfiguration { get }
    
    func draw(in layer: CALayer, for dataProvider: KLineDataProvider, range: Range<Int>, in rect: CGRect, metricBounds: MetricBounds)
}
