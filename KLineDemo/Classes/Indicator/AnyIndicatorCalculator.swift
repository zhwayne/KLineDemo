//
//  AnyIndicatorCalculator.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import Foundation

/// 类型擦除结构体，用于包装具体的 `IndicatorCalculator`。
struct AnyIndicatorCalculator: IndicatorCalculator {
    typealias Value = Any
    
    private let _key: IndicatorKey
    private let _calculate: ([KLineItem]) async throws -> [Any?]
    
    /// 初始化方法，接受任何符合 `IndicatorCalculator` 协议的计算器。
    ///
    /// - Parameter calculator: 具体的 `IndicatorCalculator` 实例。
    init<Calculator: IndicatorCalculator>(_ calculator: Calculator) {
        self._key = calculator.key
        self._calculate = { items in
            let values = try await calculator.calculate(for: items)
            return values.map { value in
                if let v = value {
                    return v
                } else {
                    return nil
                }
            }
        }
    }
    
    /// 获取指标的键名。
    var key: IndicatorKey {
        return _key
    }
    
    /// 计算指标值，返回 `[Any?]`。
    func calculate(for items: [KLineItem]) async throws -> [Any?] {
        return try await _calculate(items)
    }
}

extension IndicatorCalculator {
    
    func eraseToAnyCalculator() -> AnyIndicatorCalculator {
        AnyIndicatorCalculator(self)
    }
}
