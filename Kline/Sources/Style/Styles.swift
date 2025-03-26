//
//  Styles.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import UIKit

public struct IndicatorStyle {
    fileprivate(set) var candleStyle: CandleStyle?
    
    public let strokeColor: UIColor
    public let lineWidth: CGFloat
    public let fillColor: UIColor?
    public let font: UIFont
    
    public init(
        strokeColor: UIColor,
        lineWidth: CGFloat = 1,
        fillColor: UIColor? = nil,
        font: UIFont = .systemFont(ofSize: 10)
    ) {
        self.strokeColor = strokeColor
        self.lineWidth = lineWidth
        self.fillColor = fillColor
        self.font = font
    }
}

public struct CandleStyle {
    public var upColor: UIColor = .systemPink
    public var downColor: UIColor = .systemTeal
    public var width: CGFloat = 16
    public var gap: CGFloat = 4
        
    fileprivate init() { }
}

@MainActor final public class StyleManager {
    
    public static let shared = StyleManager()
    
    private init() {}
    
    public var candleStyle = CandleStyle()
    
    private var indicatorStyles: [IndicatorKey: IndicatorStyle] = [
        .vol: .init(strokeColor: UIColor.darkText),
        
        .ma(period: 5): .init(strokeColor: .systemPink),
        .ma(period: 20): .init(strokeColor: .systemOrange),
        .ma(period: 30): .init(strokeColor: .systemPurple),
        .ma(period: 50): .init(strokeColor: .systemGreen),
        .ma(period: 120): .init(strokeColor: .systemTeal),
        
        .ema(period: 5): .init(strokeColor: .systemGreen),
        .ema(period: 10): .init(strokeColor: .systemYellow),
        .ema(period: 20): .init(strokeColor: .systemPurple),
        
        .rsi(period: 6): .init(strokeColor: .systemGreen),
        .rsi(period: 12): .init(strokeColor: .systemRed),
        .rsi(period: 24): .init(strokeColor: .systemPurple)
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
