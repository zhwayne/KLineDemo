//
//  ChartTransformer.swift
//  KLineDemo
//
//  Created by iya on 2024/11/6.
//

import UIKit
import CoreLocation

struct VerticalInset {
    let top: CGFloat
    let bottom: CGFloat
    
    static var zero: VerticalInset { .init(top: 0, bottom: 0) }
}

protocol Transformer {
    
    var dataBounds: MetricBounds { get }
    
    var itemWidth: CGFloat { get }
    
    var viewPort: CGRect { get }
        
    func transformX(at index: Int) -> CGFloat
        
    func transformY(value: Double, inset: VerticalInset) -> CGFloat
}

extension Transformer {
    
    func transformY(value: Double) -> CGFloat {
        return transformY(value: value, inset: .zero)
    }
}

struct ChartTransformer: Transformer {

    let dataBounds: MetricBounds
    let itemWidth: CGFloat
    let viewPort: CGRect
    
    init(dataBounds: MetricBounds, itemWidth: CGFloat, viewPort: CGRect) {
        self.dataBounds = dataBounds
        self.itemWidth = itemWidth
        self.viewPort = viewPort
    }
    
    /// 将数据索引映射为图表上的 x 坐标。
    func transformX(at index: Int) -> CGFloat {
        return CGFloat(index) * itemWidth
    }
    
    /// 将数据值映射为图表上的 y 坐标。
    func transformY(value: Double, inset: VerticalInset) -> CGFloat {
        // 将数据值映射到图表高度上的位置。
        // valueRatio 表示数据值在最小值和最大值之间的归一化比例。
        let valueRatio = CGFloat((value - dataBounds.minimum) / dataBounds.distance)
        return inset.top + (1.0 - valueRatio) * (viewPort.height - inset.top - inset.bottom)
    }
}
