//
//  Styles.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import UIKit

public struct IndicatorStyle {
    fileprivate(set) var candleStyle: CandleStyle?
    
    public let lineColor: UIColor
    public let lineWidth: CGFloat
    public let fillColor: UIColor?
    public let font: UIFont
    
    public init(
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

public struct CandleStyle {
    public var upColor: UIColor = .systemPink
    public var downColor: UIColor = .systemTeal
    public var width: CGFloat = 16
    public var gap: CGFloat { 4 }
        
    fileprivate init() { }
}

@MainActor final public class StyleManager {
    
    public static let shared = StyleManager()
    
    private init() {}
    
    public var candleStyle = CandleStyle()
    
    private var indicatorStyles: [IndicatorKey: IndicatorStyle] = [
        .ma(period: 5): .init(lineColor: .systemPink),
        .ma(period: 20): .init(lineColor: .systemOrange),
        .ma(period: 30): .init(lineColor: .systemPurple),
        .ma(period: 50): .init(lineColor: .systemGreen),
        .ma(period: 120): .init(lineColor: .systemTeal),
        
        .ema(period: 5): .init(lineColor: .systemGreen),
        .ema(period: 10): .init(lineColor: .systemYellow),
        .ema(period: 20): .init(lineColor: .systemPurple),
        
        .rsi(period: 6): .init(lineColor: .systemGreen),
        .rsi(period: 12): .init(lineColor: .systemRed),
        .rsi(period: 24): .init(lineColor: .systemPurple)
    ]
    
    public func setIndicatorStyle(_ style: IndicatorStyle, for key: IndicatorKey) {
        indicatorStyles[key] = style
    }
    
    public func indicatorStyle(for key: IndicatorKey) -> IndicatorStyle? {
        if var style = indicatorStyles[key] {
            style.candleStyle = candleStyle
            return style
        }
        return nil
    }
}
