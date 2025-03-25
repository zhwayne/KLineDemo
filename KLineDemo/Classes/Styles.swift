//
//  Styles.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import UIKit

protocol StyleConfigurable { }

extension Never: StyleConfigurable { }

struct IndicatorStyle: StyleConfigurable {
    fileprivate(set) var candleStyle: CandleStyle?
    
    let lineColor: UIColor
    let lineWidth: CGFloat
    let fillColor: UIColor?
    let font: UIFont
    
    init(
        lineColor: UIColor,
        lineWidth: CGFloat = 1,
        fillColor: UIColor? = nil,
        font: UIFont = .systemFont(ofSize: 10)
    ) {
        self.lineColor = lineColor
        self.lineWidth = lineWidth
        self.fillColor = fillColor
        self.font = font
    }
}

struct CandleStyle: StyleConfigurable {
    var upColor: UIColor = .systemPink
    var downColor: UIColor = .systemTeal
    var width: CGFloat = 16
    var gap: CGFloat { 4 }
        
    fileprivate init() { }
}

class StyleManager {
    
    static let shared = StyleManager()
    
    private init() {}
    
    var candleStyle = CandleStyle()
    
    private var indicatorStyles: [IndicatorKey: IndicatorStyle] = [
        .ma(period: 5): .init(lineColor: .systemPink),
        .ma(period: 20): .init(lineColor: .systemOrange),
        .ma(period: 30): .init(lineColor: .systemPurple),
        .ma(period: 50): .init(lineColor: .systemGreen),
        .ma(period: 120): .init(lineColor: .systemTeal),
        
        .ema(period: 5): .init(lineColor: .systemCyan),
        .ema(period: 10): .init(lineColor: .systemYellow),
        .ema(period: 20): .init(lineColor: .systemMint),
        
        .rsi(period: 6): .init(lineColor: .systemMint),
        .rsi(period: 12): .init(lineColor: .systemRed),
        .rsi(period: 24): .init(lineColor: .systemPurple)
    ]
    
    func setIndicatorStyle(_ style: IndicatorStyle, for key: IndicatorKey) {
        indicatorStyles[key] = style
    }
    
    func indicatorStyle(for key: IndicatorKey) -> IndicatorStyle? {
        if var style = indicatorStyles[key] {
            style.candleStyle = candleStyle
            return style
        }
        return nil
    }
}
