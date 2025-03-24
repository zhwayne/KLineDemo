//
//  VOLCalculator.swift
//  KLineDemo
//
//  Created by work on 2025/3/24.
//

import Foundation

struct VOLCalculator: IndicatorCalculator {
    
    typealias Value = Int
    
    var key: IndicatorKey { .vol }
    
    func calculate(for items: [KLineItem]) async throws -> [Int] {
        return items.map(\.volume)
    }
}
