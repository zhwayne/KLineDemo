//
//  MACalculator.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import Foundation

/// 简单移动平均线 (SMA) 的计算器。
struct MACalculator: IndicatorCalculator {
    typealias Value = Double
    
    let period: Int       // 移动平均线的周期
    
    var key: IndicatorKey {
        return .ma(period: period)
    }
    
    func calculate(for items: [KLineItem]) async throws -> [Double?] {
        guard period > 0 else {
            throw IndicatorCalculationError.invalidData(reason: "周期必须大于 0。")
        }
        guard items.count >= period else {
            throw IndicatorCalculationError.insufficientData(period: period)
        }
        
        var result = [Double?](repeating: nil, count: items.count)
        var sum: Double = 0
        
        for i in 0..<items.count {
            sum += items[i].closing
            
//            if i >= period {
//                sum -= items[i - period].closing
//            }
//            
//            if i >= period - 1 {
//                result[i] = sum / Double(period)
//            }
            
            // 前几个数据使用部分平均值
            if i < period - 1 {
                result[i] = sum / Double(i + 1)
            } else {
                // 正常计算 MA
                if i >= period {
                    sum -= items[i - period].closing
                }
                result[i] = sum / Double(period)
            }
        }
        
        return result
    }
}