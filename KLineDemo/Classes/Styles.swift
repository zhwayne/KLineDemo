//
//  Styles.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import UIKit

struct ChartStyle {
    var lineColor: UIColor
    var lineWidth: CGFloat
    var fillColor: UIColor?
    var font: UIFont?
    // 可以根据需要添加更多样式属性
}

struct CandleStyle {
    var upColor: UIColor = .systemPink
    var downColor: UIColor = .systemTeal
    var lineWidth: CGFloat = 16
    var gap: CGFloat { 4 }
        
    init() { }
}

class StyleManager {
    static let shared = StyleManager()
    
    private init() {}
    
    var candleStyle = CandleStyle()
    
    private var styles: [IndicatorKey: ChartStyle] = [
        .ma(period: 5): .init(lineColor: .systemPink, lineWidth: 1),
        .ma(period: 20): .init(lineColor: .systemOrange, lineWidth: 1),
        .ma(period: 30): .init(lineColor: .systemPurple, lineWidth: 1),
        .ma(period: 50): .init(lineColor: .systemGreen, lineWidth: 1),
        .ma(period: 120): .init(lineColor: .systemTeal, lineWidth: 1),
        
        .ema(period: 5): .init(lineColor: .systemCyan, lineWidth: 1),
        .ema(period: 10): .init(lineColor: .systemYellow, lineWidth: 1),
        .ema(period: 20): .init(lineColor: .systemMint, lineWidth: 1),
        
        .rsi(period: 6): .init(lineColor: .systemMint, lineWidth: 1),
        .rsi(period: 12): .init(lineColor: .systemRed, lineWidth: 1),
        .rsi(period: 24): .init(lineColor: .systemPurple, lineWidth: 1)
    ]
    
    func setStyle(_ style: ChartStyle, for key: IndicatorKey) {
        styles[key] = style
    }
    
    func style(for key: IndicatorKey) -> ChartStyle? {
        return styles[key]
    }
}
