//
//  IndicatorKey.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import Foundation

/// 枚举，表示不同类型的指标及其相关参数。
public enum IndicatorKey: Hashable, CustomStringConvertible, Sendable {
    case vol    // 成交量
    case ma(period: Int)                          // 移动平均线
    case ema(period: Int)
    case rsi(period: Int)                         // 相对强弱指数
    case macd(shortPeriod: Int, longPeriod: Int, signalPeriod: Int) // 移动平均线收敛/散度
    
    public var description: String {
        switch self {
        case .vol:
            return "VOL"
        case .ma(let period):
            return "MA\(period)"
        case .ema(let period):
            return "EMA\(period)"
        case .rsi(let period):
            return "RSI\(period)"
        case .macd(let short, let long, let signal):
            return "MACD(\(short),\(long),\(signal))"
        }
    }
}

public enum IndicatorType: String, CaseIterable, Sendable {
    case vol = "VOL"
    case ma = "MA"
    case ema = "EMA"
    case rsi = "RSI"
    case macd = "MACD"
    
    public var keys: [IndicatorKey] {
        switch self {
        case .vol:  return [.vol]
        case .ma:   return [5, 20, 30, 60, 120].map { .ma(period: $0) }
        case .ema:  return [5, 10, 20].map { .ema(period: $0) }
        case .rsi:  return [6, 12, 24].map { IndicatorKey.rsi(period: $0) }
        case .macd: return [.macd(shortPeriod: 12, longPeriod: 26, signalPeriod: 9)]
        }
    }
}
