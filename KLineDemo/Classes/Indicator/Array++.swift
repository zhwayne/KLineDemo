//
//  Array++.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import Foundation

extension Array where Element == KLineItem {
    /// 使用提供的计算器数组计算指标，并将结果装饰到数据中。
    ///
    /// - Parameter calculators: 用于计算指标的 `IndicatorCalculator` 数组。
    /// - Returns: 包含原始 `KLineItem` 和关联指标的 `IndicatorData` 数组。
    func decorateWithIndicators<Calculator: IndicatorCalculator>(
        calculators: [Calculator]
    ) async throws -> [IndicatorData] {
        var decoratedItems = self.map { IndicatorData(item: $0) }
        
        // 使用抛出任务组进行并发计算
        try await withThrowingTaskGroup(of: (IndicatorKey, [Any?]).self) { group in
            for calculator in calculators {
                group.addTask {
                    let values = try await calculator.calculate(for: self)
                    // 使用类型擦除包装指标值
                    let typeErasedValues: [Any?] = values.map { value in
                        if let v = value {
                            return v
                        } else {
                            return nil
                        }
                    }
                    return (calculator.key, typeErasedValues)
                }
            }
            
            for try await (key, values) in group {
                for i in 0..<decoratedItems.count {
                    decoratedItems[i].setIndicator(value: values[i], forKey: key)
                }
            }
        }
        
        return decoratedItems
    }
}

extension Collection where Element == IndicatorData {
    /// 计算特定数值型指标的范围（最大值和最小值）。
    ///
    /// - Parameter key: 要计算范围的 `IndicatorKey`。
    /// - Returns: 包含最大值和最小值的 `MetricBounds`，若无有效数据则返回 `nil`。
    func bounds(for key: IndicatorKey) -> MetricBounds? {
        // 提取特定指标的所有非 nil 值，并尝试转换为 Double
        let indicatorValues: [Double] = self.compactMap { data in
            data.getIndicator(forKey: key)
        }
        
        // 如果没有有效的数据，返回 nil
        guard !indicatorValues.isEmpty,
              let minVal = indicatorValues.min(),
              let maxVal = indicatorValues.max() else {
            return nil
        }
        
        return MetricBounds(maximum: maxVal, minimum: minVal)
    }
}

extension Collection where Element == KLineItem {
    
    /// 计算数组中的价格范围（最大值和最小值）。
    var bounds: MetricBounds? {
        guard !isEmpty else { return nil }
        
        let minPrice = self.map { Swift.min($0.opening, $0.closing, $0.highest, $0.lowest) }.min() ?? 0
        let maxPrice = self.map { Swift.max($0.opening, $0.closing, $0.highest, $0.lowest) }.max() ?? 0
        
        return MetricBounds(maximum: maxPrice, minimum: minPrice)
    }
}
