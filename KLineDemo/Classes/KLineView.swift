//
//  KLineView.swift
//  KLineDemo
//
//  Created by iya on 2024/10/31.
//

import UIKit
import SnapKit

@MainActor class KLineView: UIView {
    
    private let scrollView = UIScrollView()
    private let canvasView = UIView()
    private let legendLabel = UILabel()
    
    private var canvasLeftConstraint: Constraint!
    
    private var styleConfig: StyleConfiguration { .shared }
    
    private var displayingIndicatorTypes: [IndicatorType] = []
    private var dataProvider: KLineDataSource!
    private var mainRenderers: [KLineRenderer] = []
    private var subRenderers: [KLineRenderer] = []
    
    // pinch
    private var pinchCenterX: CGFloat = 0
    private var oldScale: CGFloat = 1
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemFill.cgColor
        
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.delaysContentTouches = false
        
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        scrollView.addSubview(canvasView)
        canvasView.snp.makeConstraints { make in
            make.top.width.height.equalToSuperview()
            canvasLeftConstraint = make.left.equalTo(scrollView).offset(0).constraint
        }
        
        legendLabel.numberOfLines = 0
        addSubview(legendLabel)
        legendLabel.snp.makeConstraints { make in
            make.left.equalTo(12)
            make.right.lessThanOrEqualTo(-12)
            make.top.equalTo(12)
        }
        
        // pinch
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(Self.handlePinch(_:)))
        scrollView.addGestureRecognizer(pinch)
        
        let calculators: [AnyIndicatorCalculator] = [
            MACalculator(period: 5).eraseToAnyCalculator(),
            MACalculator(period: 20).eraseToAnyCalculator(),
            MACalculator(period: 30).eraseToAnyCalculator(),
            MACalculator(period: 60).eraseToAnyCalculator(),
            MACalculator(period: 120).eraseToAnyCalculator(),
        ]
        dataProvider = KLineDataSource(calculators: calculators)
        
        // 添加蜡烛图
        addMainRenderer(CandleRender(styleConfig: styleConfig))
        // 默认添加 MA 主图指标
        addMainRenderer(MARender(styleConfig: styleConfig))
        
        displayingIndicatorTypes = [.vol, .ma]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reloadData(items: [KLineItem], scrollPosition: ScrollPosition = .top) {
        Task {
            try? await dataProvider.update(items: items)
            redrawContent(scrollPosition: scrollPosition)
        }
    }
}

extension KLineView {
    
    // 添加主图绘制器
    private func addMainRenderer(_ renderer: KLineRenderer) {
        mainRenderers.append(renderer)
        redrawContent(scrollPosition: .none)
    }
    
    // 添加副图绘制器
    private func addSubRenderer(_ renderer: KLineRenderer) {
        subRenderers.append(renderer)
        redrawContent(scrollPosition: .none)
    }
    
    // 移除主图绘制器
    private func removeMainRenderer<T: KLineRenderer>(ofType type: T.Type) {
        mainRenderers.removeAll { $0 is T }
        redrawContent(scrollPosition: .none)
    }
    
    // 移除副图绘制器
    private func removeSubRenderer<T: KLineRenderer>(ofType type: T.Type) {
        subRenderers.removeAll { $0 is T }
        redrawContent(scrollPosition: .none)
    }
}

extension KLineView {
    
    @objc private func handlePinch(_ pinch: UIPinchGestureRecognizer) {
        switch pinch.state {
        case .began:
            scrollView.isScrollEnabled = false
            let p1 = pinch.location(ofTouch: 0, in: canvasView)
            let p2 = pinch.location(ofTouch: 1, in: canvasView)
            pinchCenterX = (p1.x + p2.x) / 2
            oldScale = 1.0
        case .changed:
            break;
            
        default:
            scrollView.isScrollEnabled = true
        }
        
        let difValue = pinch.scale - oldScale
        
        let newLineWidth = styleConfig.kLineStyle.lineWidth * (difValue + 1)
        guard newLineWidth >= 1 else { return }
        
        styleConfig.kLineStyle.lineWidth = newLineWidth
        oldScale = pinch.scale
        
        // 更新 contentSize
        let contentOffsetAtPinch = scrollView.contentOffset.x + pinchCenterX
        let oldContentSize = scrollView.contentSize
        updateScrollViewContentSize()
        
        
        // 算新的内容偏移量
        let newContentOffsetAtPinch = contentOffsetAtPinch * (scrollView.contentSize.width / oldContentSize.width)
        var newContentOffsetX = newContentOffsetAtPinch - pinchCenterX
        
        // 限制偏移量的范围
        newContentOffsetX = max(0, newContentOffsetX)
        let maxContentOffsetX = scrollView.contentSize.width - scrollView.bounds.width
        newContentOffsetX = min(maxContentOffsetX, newContentOffsetX)

        // 更新 contentOffset 并重绘内容
        if scrollView.contentOffset.x == newContentOffsetX {
            scrollViewDidScroll(scrollView)
        } else {
            scrollView.contentOffset.x = newContentOffsetX
        }
    }
}

extension KLineView {
    
    private var visiableRange: Range<Int> {
        let itemCountToBeDrawn = max(Int(ceil(scrollView.frame.width / (styleConfig.kLineStyle.gap + styleConfig.kLineStyle.lineWidth))) + 2, 0)
        let offsetX = max(scrollView.contentOffset.x, 0)
        let startIndex = max(Int(floor(offsetX / (styleConfig.kLineStyle.gap + styleConfig.kLineStyle.lineWidth))) - 1, 0)
        guard startIndex < dataProvider.kLineItems.count else { return 0..<0 }
        return startIndex..<min(startIndex + itemCountToBeDrawn, dataProvider.kLineItems.count)
    }
    
    private func redrawContent(scrollPosition: ScrollPosition) {
        updateScrollViewContentSize()
        // 显示最后一屏
        let offsetX = scrollView.contentSize.width - scrollView.frame.width
        scrollView.contentOffset.x = max(0, offsetX)
        drawVisiableItems()
    }
    
    private func updateScrollViewContentSize() {
        let count = CGFloat(dataProvider.kLineItems.count)
        let contentWidth = count * styleConfig.kLineStyle.lineWidth + styleConfig.kLineStyle.gap * (count - 1)
        scrollView.contentSize = CGSize(
            width: max(contentWidth, scrollView.bounds.width),
            height: scrollView.bounds.height
        )
    }
    
    private func drawVisiableItems() {
        guard !visiableRange.isEmpty else { return }
        let offset = CGFloat(visiableRange.lowerBound) * (styleConfig.kLineStyle.gap + styleConfig.kLineStyle.lineWidth) - scrollView.contentOffset.x
        let rect = CGRect(x: offset, y: 0, width: canvasView.frame.width, height: canvasView.frame.height)
        drawVisiableItems(in: rect.inset(by: UIEdgeInsets(top: 24, left: 0, bottom: 0, right: 0)))
    }
    
    private var visiableItems: [KLineItem] {
        Array(dataProvider.kLineItems[visiableRange])
    }
    
    private var visiableIndicatorDatas: [IndicatorData<KLineItem>] {
        Array(dataProvider.indicators[visiableRange])
    }
    
    private func drawVisiableItems(in rect: CGRect) {
        canvasView.layer.sublayers = nil
        
        // 获取可见区域内数据的 metricBounds
        guard var metricBounds = visiableItems.bounds else { return }

        displayingIndicatorTypes.forEach { type in
            type.keys.forEach { key in
                if let indicatorMetricBounds = visiableIndicatorDatas.bounds(for: key) {
                    metricBounds.combine(other: indicatorMetricBounds)
                }
            }
        }
        
        legendLabel.attributedText = legendText(for: displayingIndicatorTypes)
        let legendLabelSize = legendLabel.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
        let rect = rect.inset(by: UIEdgeInsets(top: legendLabelSize.height, left: 0, bottom: 0, right: 0))
        
        mainRenderers.forEach { renderer in
            renderer.draw(in: canvasView.layer, for: dataProvider, range: visiableRange, in: rect, metricBounds: metricBounds)
        }
        
        // TODO: 附图指标
        subRenderers.forEach { renderer in
            renderer.draw(in: canvasView.layer, for: dataProvider, range: visiableRange, in: rect, metricBounds: metricBounds)
        }
    }
    
    private func legendText(for types: [IndicatorType]) -> NSAttributedString {
        let legendText = NSMutableAttributedString()
        guard let indicatorData = visiableIndicatorDatas.last else {
            return legendText
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        types.enumerated().forEach { idx, type in
            let text = NSMutableAttributedString()
            type.keys.forEach { key in
                if type == .vol {
                    let number = NSNumber(integerLiteral: indicatorData.item.volume)
                    let span = NSAttributedString(string: "\(key):\(formatter.string(from: number)!) ", attributes: [
                        .foregroundColor: styleConfig.indicatorStyle[key]?.color ?? .label,
                        .font: UIFont.systemFont(ofSize: 11)
                    ])
                    text.append(span)
                } else if let value = indicatorData.getIndicator(forKey: key, as: Double.self) {
                    let number = NSNumber(floatLiteral: value)
                    let span = NSAttributedString(string: "\(key):\(formatter.string(from: number)!) ", attributes: [
                        .foregroundColor: styleConfig.indicatorStyle[key]?.color ?? .label,
                        .font: UIFont.systemFont(ofSize: 11)
                    ])
                    text.append(span)
                }
            }
            if idx != 0 {
                text.insert(NSAttributedString(string: "\n"), at: 0)
            }
            legendText.append(text)
        }
        return legendText
    }
}

extension KLineView: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        canvasLeftConstraint.update(offset: max(scrollView.contentOffset.x, 0))
        drawVisiableItems()
    }
}

extension KLineView {
    
    enum ScrollPosition {
        case top, end, none
    }
}
