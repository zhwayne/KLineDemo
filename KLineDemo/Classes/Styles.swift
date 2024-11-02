//
//  KLineStyle.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import UIKit

struct KLineStyle {
    var upColor: UIColor = .green
    var downColor: UIColor = .red
    var lineWidth: CGFloat = 10
    var gap: CGFloat { 1 }
    
    init() { }
}

struct IndicatorStyle {
    var color: UIColor
    var lineWidth: CGFloat
    
    init(color: UIColor, lineWidth: CGFloat) {
        self.color = color
        self.lineWidth = lineWidth
    }
}

final class StyleConfiguration {
    
    static let shared = StyleConfiguration()
    
    var padding: UIEdgeInsets = .init(top: 20, left: 0, bottom: 20, right: 0)
    
    var kLineStyle = KLineStyle()
    
    var indicatorStyle: [IndicatorKey: IndicatorStyle] = [:]
}
