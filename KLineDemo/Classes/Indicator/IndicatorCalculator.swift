//
//  IndicatorCalculator.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import Foundation

/// 指标计算协议
protocol IndicatorCalculator {
    associatedtype Value
    
    /// 指标的唯一键名。
    var key: IndicatorKey { get }
    
    /// 异步计算给定数据的指标值。
    ///
    /// - Parameter items: 数据项数组。
    /// - Returns: 指标值数组，若某个数据点无法计算则为 `nil`。
    func calculate(for items: [KLineItem]) async throws -> [Value?]
}

/// 枚举，表示指标计算过程中可能出现的错误。
enum IndicatorCalculationError: Error, CustomStringConvertible {
    case insufficientData(period: Int)                      // 数据不足
    case invalidData(reason: String)                        // 数据无效
    
    var description: String {
        switch self {
        case .insufficientData(let period):
            return "数据不足，周期：\(period)"
        case .invalidData(let reason):
            return "数据无效：\(reason)"
        }
    }
}
