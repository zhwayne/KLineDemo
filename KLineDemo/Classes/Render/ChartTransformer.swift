//
//  ChartTransformer.swift
//  KLineDemo
//
//  Created by iya on 2024/11/6.
//

import Foundation

protocol ChartTransformer {
    
    /// 将数据索引映射为图表上的 x 坐标。
    func transformX(index: Int) -> CGFloat
    
    /// 将数据值映射为图表上的 y 坐标。
    func transformY(value: Double) -> CGFloat
}

struct DefaultChartTransformer: ChartTransformer {
    
    private let itemWidth: CGFloat
    private let dataMin: Double
    private let dataMax: Double
    private let viewPort: CGRect

    init(itemWidth: CGFloat, dataMin: Double, dataMax: Double, viewPort: CGRect) {
        self.itemWidth = itemWidth
        self.dataMin = dataMin
        self.dataMax = dataMax
        self.viewPort = viewPort
    }

    func transformX(index: Int) -> CGFloat {
        return CGFloat(index) * itemWidth
    }

    func transformY(value: Double) -> CGFloat {
        // 将数据值映射到图表高度上的位置。
        // valueRatio 表示数据值在最小值和最大值之间的归一化比例。
        let valueRatio = CGFloat((value - dataMin) / (dataMax - dataMin))
        return /*viewPort.origin.y +*/ (1.0 - valueRatio) * viewPort.height
    }
}
