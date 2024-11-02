//
//  KLineItem.swift
//  KLineDemo
//
//  Created by iya on 2024/10/31.
//

import UIKit

enum KLineTrend: Sendable {
    case up, down, equal
}

/// 表示单个 K 线数据点。
struct KLineItem: Equatable, Sendable {
    let opening: Double      // 开盘价
    let closing: Double      // 收盘价
    let highest: Double      // 最高价
    let lowest: Double       // 最低价
    let volume: Int          // 成交量
    let value: Double        // 成交额
    let timestamp: Int       // 时间戳
}

extension KLineItem {
    
    var trend: KLineTrend {
        if opening > closing { return .down }
        if opening < closing { return .up }
        return .equal
    }
}
