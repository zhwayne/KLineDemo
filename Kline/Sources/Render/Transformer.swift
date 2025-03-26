//
//  ChartTransformer.swift
//  KLineDemo
//
//  Created by iya on 2024/11/6.
//

import UIKit
import CoreLocation

struct AxisInset {
    let top: CGFloat
    let bottom: CGFloat
    
    static var zero: AxisInset { .init(top: 0, bottom: 0) }
}

extension AxisInset {
    
    func merge(_ other: AxisInset) -> AxisInset {
        return AxisInset(top: top + other.top, bottom: bottom + other.bottom)
    }
}

protocol Transformer {
    
    var dataBounds: MetricBounds { get set }
    
    var itemWidth: CGFloat { get }
    
    var viewPort: CGRect { get }
        
    func transformX(at index: Int) -> CGFloat
        
    func transformY(value: Double, inset: AxisInset) -> CGFloat
}

extension Transformer {
    
    func transformY(value: Double) -> CGFloat {
        return transformY(value: value, inset: .zero)
    }
}

struct ChartTransformer: Transformer {

    private let contentInset: AxisInset
    var dataBounds: MetricBounds
    let itemWidth: CGFloat
    let viewPort: CGRect
    
    init(inset: AxisInset = .zero, dataBounds: MetricBounds, itemWidth: CGFloat, viewPort: CGRect) {
        self.contentInset = inset
        self.dataBounds = dataBounds
        self.itemWidth = itemWidth
        self.viewPort = viewPort
    }
    
    /// 将数据索引映射为图表上的 x 坐标。
    func transformX(at index: Int) -> CGFloat {
        return CGFloat(index) * itemWidth
    }
    
    /// 将数据值映射为图表上的 y 坐标。
    func transformY(value: Double, inset: AxisInset) -> CGFloat {
        // 将数据值映射到图表高度上的位置。
        // valueRatio 表示数据值在最小值和最大值之间的归一化比例。
        let valueRatio = CGFloat((value - dataBounds.minimum) / dataBounds.distance)
        let adjustedInset = contentInset.merge(inset)
        let height = viewPort.height - adjustedInset.top - adjustedInset.bottom
        return adjustedInset.top + (1.0 - valueRatio) * height
    }
}
