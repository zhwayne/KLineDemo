//
//  KLineDataSource.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import Foundation

final class KLineDataSource {
    private(set) var indicators: [IndicatorData] = []
    private(set) var kLineItems: [KLineItem] = []
    
    private var calculators: [AnyIndicatorCalculator] = []
    
    init() { }
    
    func update(items: [KLineItem]) async {
        // TODO: 增量计算，减少计算量
        if let indicators = try? await items.decorateWithIndicators(calculators: calculators) {
            self.kLineItems = items
            self.indicators = indicators
        }
    }
    
    func install(calculator: any IndicatorCalculator) {
        if calculators.contains(where: { $0.key == calculator.key }) {
            return
        }
        calculators.append(calculator.eraseToAnyCalculator())
    }
    
    func removeCalculator(for key: IndicatorKey) {
        calculators.removeAll { $0.key == key }
    }
}

extension KLineDataSource {
    
    /// 获取特定类型的指标值数组。
    func indicatorValues<T>(for key: IndicatorKey) -> [T?] {
        let result: [T?] = indicators.map { data in
            data.getIndicator(forKey: key)
        }
        return result
    }
}
