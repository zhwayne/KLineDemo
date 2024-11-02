//
//  KLineDataProvider.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import Foundation

protocol KLineDataProvider {
    var kLineItems: [KLineItem] { get }  // K 线数据数组
    var indicators: [IndicatorData<KLineItem>] { get }  // 包含各种计算出的指标
}

extension KLineDataProvider {
    
    /// 获取特定类型的指标值数组。
    func indicatorValues<T>(for key: IndicatorKey, as type: T.Type) -> [T?] {
        let result = indicators.map { data in
            data.getIndicator(forKey: key, as: type)
        }
        return result
    }
}

final class KLineDataSource: KLineDataProvider {
    private(set) var indicators: [IndicatorData<KLineItem>] = []
    private(set) var kLineItems: [KLineItem] = []
    
    private var calculators: [AnyIndicatorCalculator]
    
    init(calculators: [any IndicatorCalculator]) {
        self.calculators = calculators.map { $0.eraseToAnyCalculator() }
    }
    
    func update(items: [KLineItem]) async throws {
        let indicators = try await items.decorateWithIndicators(calculators: calculators)
        self.kLineItems = items
        self.indicators = indicators
    }
}
