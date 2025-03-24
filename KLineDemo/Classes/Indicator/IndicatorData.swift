//
//  IndicatorData.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import Foundation

/// 将 `KLineItem` 与其计算出的指标关联起来。
struct IndicatorData {
    let item: KLineItem
    private var indicators: [IndicatorKey: Any] = [:] // 存储不同指标的值
    
    /// 为特定的指标键设置指标值。
    ///
    /// - Parameters:
    ///   - value: 指标值。
    ///   - key: 指标键。
    mutating func setIndicator(value: Any?, forKey key: IndicatorKey) {
        indicators[key] = value
    }
    
    /// 获取特定指标键的指标值，指定类型。
    ///
    /// - Parameters:
    ///   - key: 指标键。
    ///   - type: 指标值的类型。
    /// - Returns: 指标值，若不存在或类型不匹配则返回 `nil`。
    func getIndicator(forKey key: IndicatorKey) -> Any? {
        return indicators[key]
    }
    
    init(item: KLineItem) {
        self.item = item
    }
}
