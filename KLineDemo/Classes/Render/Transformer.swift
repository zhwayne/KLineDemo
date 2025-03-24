//
//  ChartTransformer.swift
//  KLineDemo
//
//  Created by iya on 2024/11/6.
//

import UIKit
import CoreLocation

enum ChartCoordinateSpace {
    case scrollView
    case layer
}

protocol Transformer {
    
    func frame(in space: ChartCoordinateSpace) -> CGRect
    
    func transformIndex(offset: CGFloat) -> Int
    
    func transformX(at index: Int) -> CGFloat
    
    func transformY(value: Double) -> CGFloat
}

struct ChartTransformer: Transformer {

    private let itemWidth: CGFloat
    private let viewPort: CGRect
    private let dataBounds: MetricBounds
    private let scrollView: HorizontalScrollView
    
    init(itemWidth: CGFloat, viewPort: CGRect, dataBounds: MetricBounds, scrollView: HorizontalScrollView) {
        self.itemWidth = itemWidth
        self.viewPort = viewPort
        self.dataBounds = dataBounds
        self.scrollView = scrollView
    }

    func frame(in space: ChartCoordinateSpace) -> CGRect {
        if space == .layer {
            return viewPort
        } else {
            let rect = scrollView.contentView.convert(viewPort, to: scrollView)
            return rect
        }
    }
    
    func transformIndex(offset: CGFloat) -> Int {
        let index = Int(ceil(offset / itemWidth))
        return index
    }
    
    /// 将数据索引映射为图表上的 x 坐标。
    func transformX(at index: Int) -> CGFloat {
        return CGFloat(index) * itemWidth
    }
    
    /// 将数据值映射为图表上的 y 坐标。
    func transformY(value: Double) -> CGFloat {
        // 将数据值映射到图表高度上的位置。
        // valueRatio 表示数据值在最小值和最大值之间的归一化比例。
        let valueRatio = CGFloat((value - dataBounds.minimum) / dataBounds.distance)
        return /*viewPort.origin.y +*/ (1.0 - valueRatio) * viewPort.height
    }
}
