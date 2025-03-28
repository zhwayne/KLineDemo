//
//  CandleRenderer.swift
//  KLineDemo
//
//  Created by iya on 2024/11/1.
//

import UIKit

final class CandleRenderer: ChartRenderer {
    
    var styleManager: StyleManager { .shared }
        
    var transformer: Transformer?
    
    weak var view: UIView?
    
    typealias Item = KLineItem
    
    private let priceIndicatorView = PriceIndicatorView()
    
    func draw(in layer: CALayer, data: RenderData<KLineItem>) {
        guard let transformer = transformer else { return }
        let viewPort = transformer.viewPort
        let candleStyle = styleManager.candleStyle
        let visibleItems = data.visibleItems
        let sublayer = CALayer()
        sublayer.frame = viewPort
        sublayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(sublayer)
        
        // MARK: - 顶部线条
        
        let lineHeight = 1 / UIScreen.main.scale
        let topLinePath = UIBezierPath()
        topLinePath.move(to: CGPoint(x: 0, y: lineHeight))
        topLinePath.addLine(to: CGPoint(x: layer.bounds.maxX, y: lineHeight))
        
        let topLineLayer = CAShapeLayer()
        topLineLayer.path = topLinePath.cgPath
        topLineLayer.lineWidth = lineHeight
        topLineLayer.fillColor = UIColor.clear.cgColor
        topLineLayer.strokeColor = UIColor.separator.cgColor
        layer.addSublayer(topLineLayer)
        
        // MARK: - 蜡烛图
        for (idx, item) in visibleItems.enumerated() {
            // 计算 x 坐标
            let x = transformer.xAxis(at: idx)
            
            // 计算开盘价和收盘价的 y 坐标
            let openY = transformer.yAxis(for: item.opening)
            let closeY = transformer.yAxis(for: item.closing)
            let y = min(openY, closeY)
            let h = abs(openY - closeY)
            
            let rect = CGRect(x: x, y: y, width: candleStyle.width, height: h)
            let path = UIBezierPath(rect: rect)
            
            // 计算最高价和最低价的 y 坐标
            let highY = transformer.yAxis(for: item.highest)
            let lowY = transformer.yAxis(for: item.lowest)
            
            let centerX = candleStyle.width / 2 + x
            let highestPoint = CGPoint(x: centerX, y: highY)
            let lowestPoint = CGPoint(x: centerX, y: lowY)
            
            path.move(to: highestPoint)
            path.addLine(to: CGPoint(x: centerX, y: y))
            path.move(to: lowestPoint)
            path.addLine(to: CGPoint(x: centerX, y: y + h))
            
            let shape = CAShapeLayer()
            shape.contentsScale = UIScreen.main.scale
            shape.path = path.cgPath
            shape.lineWidth = 1
            shape.strokeColor = item.trend == .up ? candleStyle.upColor.cgColor : candleStyle.downColor.cgColor
            shape.fillColor = item.trend == .up ? candleStyle.upColor.cgColor : candleStyle.downColor.cgColor
            
            sublayer.addSublayer(shape)
        }
        
        // MARK: - 最高价指示
        if let item = visibleItems.max(by: { $0.highest < $1.highest }),
           let index = visibleItems.firstIndex(of: item) {
            let x = transformer.xAxis(at: index) + candleStyle.width * 0.5
            let y = transformer.yAxis(for: item.highest)
            
            let rightSide = (x + transformer.viewPort.origin.x) < layer.bounds.midX
            let startPoint = CGPoint(x: x, y: y)
            let endPoint = CGPoint(x: x + (rightSide ? 30 : -30 ), y: y)
            
            let linePath = UIBezierPath()
            linePath.move(to: startPoint)
            linePath.addLine(to: endPoint)
            
            let lineLayer = CAShapeLayer()
            lineLayer.lineWidth = 1
            lineLayer.strokeColor = UIColor.label.withAlphaComponent(0.7).cgColor
            lineLayer.path = linePath.cgPath
            
            let textLayer = CATextLayer()
            textLayer.font = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular) as CTFont
            textLayer.fontSize = 10
            textLayer.foregroundColor = UIColor.label.withAlphaComponent(0.7).cgColor
            textLayer.alignmentMode = .center
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.string = styleManager.format(value: item.highest)
            let textSize = textLayer.preferredFrameSize()
            let textOrigin = CGPoint(
                x: endPoint.x + (rightSide ? 0 : -textSize.width),
                y: y - textSize.height * 0.5
            )
            textLayer.frame = CGRect(origin: textOrigin, size: textSize)
            
            sublayer.addSublayer(lineLayer)
            sublayer.addSublayer(textLayer)
        }
        
        // MARK: - 最低价指示
        if let item = visibleItems.max(by: { $0.lowest > $1.lowest }),
           let index = visibleItems.firstIndex(of: item) {
            let x = transformer.xAxis(at: index) + candleStyle.width * 0.5
            let y = transformer.yAxis(for: item.lowest)
            
            let rightSide = (x + transformer.viewPort.origin.x) < layer.bounds.midX
            let startPoint = CGPoint(x: x, y: y)
            let endPoint = CGPoint(x: x + (rightSide ? 30 : -30 ), y: y)
            
            let linePath = UIBezierPath()
            linePath.move(to: startPoint)
            linePath.addLine(to: endPoint)
            
            let lineLayer = CAShapeLayer()
            lineLayer.lineWidth = 1
            lineLayer.strokeColor = UIColor.label.withAlphaComponent(0.7).cgColor
            lineLayer.path = linePath.cgPath
            
            let textLayer = CATextLayer()
            textLayer.font = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular) as CTFont
            textLayer.fontSize = 10
            textLayer.foregroundColor = UIColor.label.withAlphaComponent(0.7).cgColor
            textLayer.alignmentMode = .center
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.string = styleManager.format(value: item.lowest)
            let textSize = textLayer.preferredFrameSize()
            let textOrigin = CGPoint(
                x: endPoint.x + (rightSide ? 0 : -textSize.width),
                y: y - textSize.height * 0.5
            )
            textLayer.frame = CGRect(origin: textOrigin, size: textSize)
            
            sublayer.addSublayer(lineLayer)
            sublayer.addSublayer(textLayer)
        }
        
        // MARK: - 最新价(悬浮在 layer 之上)
        if let item = data.items.last {
            let minY = transformer.yAxis(for: transformer.dataBounds.max)
            let maxY = transformer.yAxis(for: transformer.dataBounds.min)
            let rect = CGRectMake(0, viewPort.minY, layer.bounds.width, viewPort.height)
            var y = transformer.yAxis(for: item.closing)
            y = min(max(y, minY), maxY)
            let index = data.items.count - data.visibleRange.lowerBound - 1
            var x = transformer.xAxisInLayer(at: index)
            if x > rect.maxX { x = 0 }
            let end = CGPoint(x: x, y: y)
            let start = CGPoint(x: rect.width, y: y)
            let dashLine = CAShapeLayer()
            dashLine.strokeColor = UIColor.label.cgColor
            dashLine.lineWidth = 1 / UIScreen.main.scale
            dashLine.lineDashPattern = [2, 2]
            let path = UIBezierPath()
            path.move(to: start)
            path.addLine(to: end)
            dashLine.path = path.cgPath
            layer.addSublayer(dashLine)

            priceIndicatorView.showArrow = end.x == 0
            priceIndicatorView.label.text = styleManager.format(value: item.closing)
            let indicatorSize = priceIndicatorView.systemLayoutSizeFitting(rect.size)
            priceIndicatorView.bounds.size = indicatorSize
            priceIndicatorView.frame.origin.y = y - indicatorSize.height * 0.5
            priceIndicatorView.frame.origin.x = start.x - 12 - indicatorSize.width
            if priceIndicatorView.superview == nil, let view {
                view.addSubview(priceIndicatorView)
            }
        }
    }
}

private final class PriceIndicatorView: UIControl {
    
    let label = UILabel()
    
    private let arrowView = UIImageView(image: UIImage(systemName: "chevron.right"))
    var showArrow: Bool {
        get { !arrowView.isHidden }
        set { arrowView.isHidden = !newValue }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        label.textColor = UIColor.label.withAlphaComponent(0.7)
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        label.textAlignment = .center
        label.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        
        arrowView.tintColor = UIColor.label.withAlphaComponent(0.7)
        
        layer.borderWidth = 1 / UIScreen.main.scale
        layer.borderColor = UIColor.separator.cgColor
        layer.cornerRadius = 4
        layer.masksToBounds = true
        
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        visualEffectView.alpha = 0.9
        visualEffectView.isUserInteractionEnabled = false
        addSubview(visualEffectView)
        visualEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let stackView = UIStackView(arrangedSubviews: [label, arrowView])
        stackView.isUserInteractionEnabled = false
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 2
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4))
        }
        arrowView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 5, height: 12))
        }
        
        addTarget(self, action: #selector(Self.onClick), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func onClick() {
        NotificationCenter.default.post(name: .scrollToTop, object: nil)
    }
}
