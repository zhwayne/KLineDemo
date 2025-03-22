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
    var lineWidth: CGFloat = 10
    var gap: CGFloat { 1 }
        
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
    ]
    
    func setStyle(_ style: ChartStyle, for key: IndicatorKey) {
        styles[key] = style
    }
    
    func style(for key: IndicatorKey) -> ChartStyle? {
        return styles[key]
    }
}

protocol CandlestickStyleConfigurable: AnyObject {
    var style: CandleStyle { get set }
}

/// 让绘制器能够接收样式配置，而又不直接依赖于 StyleManager，定义一个 StyleConfigurable 协议
protocol IndicatorStyleConfigurable: AnyObject {
    var indicatorKey: IndicatorKey { get }
    var chartStyle: ChartStyle? { get set }
    var candleWidth: CGFloat { get set }
}
