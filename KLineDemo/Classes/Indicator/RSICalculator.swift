//
//  RSICalculator.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import Foundation

/// 相对强弱指数 (RSI) 的计算器。
struct RSICalculator: IndicatorCalculator {
    typealias Value = Double
    
    let period: Int       // RSI 的周期
    
    var key: IndicatorKey {
        return .rsi(period: period)
    }
    
    func calculate(for items: [KLineItem]) async throws -> [Double?] {
        guard period > 0 else {
            throw IndicatorCalculationError.invalidData(reason: "周期必须大于 0。")
        }
        guard items.count > period else {
            throw IndicatorCalculationError.insufficientData(period: period)
        }
        
        var result = [Double?](repeating: nil, count: items.count)
        var gains: [Double] = []
        var losses: [Double] = []
        
        for i in 1..<items.count {
            let change = items[i].closing - items[i - 1].closing
            let gain = max(0, change)
            let loss = max(0, -change)
            gains.append(gain)
            losses.append(loss)
            
            if i >= period {
                let start = i - period + 1
                let end = i + 1
                
                let periodGains = gains[(start - 1)..<end]
                let periodLosses = losses[(start - 1)..<end]
                
                let avgGain = periodGains.reduce(0, +) / Double(period)
                let avgLoss = periodLosses.reduce(0, +) / Double(period)
                
                if avgLoss == 0 {
                    result[i] = 100
                } else {
                    let rs = avgGain / avgLoss
                    result[i] = 100 - (100 / (1 + rs))
                }
            }
        }
        
        return result
    }
}
