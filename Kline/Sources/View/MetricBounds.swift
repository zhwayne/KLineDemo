//
//  MetricBounds.swift
//  KLineDemo
//
//  Created by iya on 2024/10/31.
//

import Foundation

/// 表示特定指标的最大值和最小值。
struct MetricBounds: Sendable {
    var maximum: Double      // 最大值
    var minimum: Double      // 最小值
}

extension MetricBounds {
    /// 最大值与最小值的距离。
    var distance: Double { maximum - minimum }
    
    /// 合并另一个 `MetricBounds`，更新最大值和最小值。
    ///
    /// - Parameter other: 需要合并的另一个 `MetricBounds`。
    mutating func combine(other bounds: MetricBounds) {
        maximum = max(maximum, bounds.maximum)
        minimum = min(minimum, bounds.minimum)
    }
}
