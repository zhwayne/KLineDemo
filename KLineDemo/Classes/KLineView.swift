//
//  KLineView.swift
//  KLineDemo
//
//  Created by iya on 2024/10/31.
//

import UIKit
import SnapKit
import Combine

enum KLineChartSection: Sendable {
    case mainChart, subChart
}

@MainActor class KLineView: UIView {
    
    private let scrollView: HorizontalScrollView
    private let candlestickView = UIView()
    private let timelineView = UIView()
    private let legendLabel = UILabel()
    private let indicatorTypeView: IndicatorTypeView
    
    private var candlestickHeight: CGFloat = 300
    private var timelineHeight: CGFloat = 16
    private var indicatorHeight: CGFloat = 32
    
    private let candleRenderer = CandleRenderer()
    private let timelineRenderer = TimelineRenderer()
    private var mainRenderers: [AnyIndicatorRenderer<IndicatorData>] = []
    private var subRenderers: [AnyIndicatorRenderer<IndicatorData>] = []
    
    private var mainIndicatorTypes: [IndicatorType] = []
    private var subIndicatorTypes: [IndicatorType] = []
    private let styleManager: StyleManager
    
    private var indicatorDatas: [IndicatorData] = []
    private var kLineItems: [KLineItem] = []
    private var calculators: [any IndicatorCalculator] = []
    
    private var disposeBag = Set<AnyCancellable>()
    
    required init(styleManager: StyleManager = .shared) {
        self.styleManager = styleManager
        scrollView = HorizontalScrollView(styleManager: styleManager)
        indicatorTypeView = IndicatorTypeView(mainIndicators: [.vol, .ma, .ema])
        
        super.init(frame: .zero)
        scrollView.delegate = self
        
        addSubview(indicatorTypeView)
        indicatorTypeView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(indicatorHeight)
        }
        
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(indicatorTypeView.snp.top)
        }
        
        scrollView.contentView.addSubview(candlestickView)
        candlestickView.snp.makeConstraints { make in
            make.top.left.width.equalToSuperview()
            make.height.equalTo(candlestickHeight)
        }
        
        scrollView.contentView.addSubview(timelineView)
        timelineView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(candlestickView.snp.bottom)
            make.height.equalTo(timelineHeight)
        }
        
        legendLabel.numberOfLines = 0
        addSubview(legendLabel)
        legendLabel.snp.makeConstraints { make in
            make.left.equalTo(8)
            make.right.lessThanOrEqualTo(-100)
            make.top.equalTo(8)
        }

        setupBindings()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reloadData(items: [KLineItem], scrollPosition: ScrollPosition) {
        Task {
            do {
                kLineItems = items
                scrollView.klineItemCount = items.count
                indicatorDatas = try await items.decorateWithIndicators(calculators: calculators)
                scrollView.scroll(to: scrollPosition)
                drawVisiableItems()
            } catch {
                print(error)
            }
        }
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = [candlestickHeight, timelineHeight, indicatorHeight].reduce(0, +)
        return size
    }
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        drawVisiableItems()
    }
    
    private func setupBindings() {
        indicatorTypeView.drawMainIndicatorPublisher
            .sink { [unowned self] type in drawMainIndicator(type: type) }
            .store(in: &disposeBag)
        
        indicatorTypeView.eraseMainIndicatorPublisher
            .sink { [unowned self] type in eraseMainIndicator(type: type) }
            .store(in: &disposeBag)
    }
}

extension KLineView {
    
    private func drawMainIndicator(type: IndicatorType) {
        for key in type.keys {
            switch key {
            case .ma(let period):
                let render = MARenderer(period: period)
                addMainRenderer(AnyIndicatorRenderer(render))
                calculators.append(MACalculator(period: period))
            case .ema(let period):
                let render = EMARenderer(period: period)
                addMainRenderer(AnyIndicatorRenderer(render))
                calculators.append(EMACalculator(period: period))
            default:
                break
            }
        }
        if !mainIndicatorTypes.contains(type) {
            mainIndicatorTypes.append(type)
        }
        reloadData(items: kLineItems, scrollPosition: .current)
    }
    
    private func eraseMainIndicator(type: IndicatorType) {
        for key in type.keys {
            removeMainRenderer(for: key)
            calculators.removeAll(where: { $0.key == key })
        }
        if let index =  mainIndicatorTypes.firstIndex(of: type) {
            mainIndicatorTypes.remove(at: index)
        }
        reloadData(items: kLineItems, scrollPosition: .current)
    }
    
    private func drawSubIndicator(type: IndicatorType) {
        for key in type.keys {
            switch key {
            case .vol:
                break
            case .rsi(let period):
                let render = RSIRenderer(period: period)
                addSubRenderer(AnyIndicatorRenderer(render))
                calculators.append(RSICalculator(period: period))
            default:
                break
            }
        }
        if !subIndicatorTypes.contains(type) {
            subIndicatorTypes.append(type)
        }
        reloadData(items: kLineItems, scrollPosition: .current)
    }
    
    private func eraseSubIndicator(type: IndicatorType) {
        for key in type.keys {
            removeSubRenderer(for: key)
            calculators.removeAll(where: { $0.key == key })
        }
        if let index =  subIndicatorTypes.firstIndex(of: type) {
            subIndicatorTypes.remove(at: index)
        }
        reloadData(items: kLineItems, scrollPosition: .current)
    }
    
    // 添加主图绘制器
    private func addMainRenderer(_ renderer: AnyIndicatorRenderer<IndicatorData>) {
        mainRenderers.append(renderer)
    }
    
    // 添加副图绘制器
    private func addSubRenderer(_ renderer: AnyIndicatorRenderer<IndicatorData>) {
        subRenderers.append(renderer)
    }
    
    // 移除主图绘制器
    private func removeMainRenderer(for key: IndicatorKey) {
        mainRenderers.removeAll { $0.key == key }
    }
    
    // 移除副图绘制器
    private func removeSubRenderer(for key: IndicatorKey) {
        subRenderers.removeAll { $0.key == key }
    }
}

extension KLineView {
   
    private func drawVisiableItems() {
        drawVisiableItems(in: scrollView.visiableRect)
    }
    
    private var visiableKLineItems: [KLineItem] {
        if kLineItems.isEmpty { return [] }
        return Array(kLineItems[scrollView.visiableRange])
    }
    
    private var visiableIndicatorDatas: [IndicatorData] {
        if indicatorDatas.isEmpty { return [] }
        return Array(indicatorDatas[scrollView.visiableRange])
    }
    
    private func drawVisiableItems(in rect: CGRect) {
        candlestickView.layer.sublayers = nil
        timelineView.layer.sublayers = nil
        
        let visiableKLineItems = self.visiableKLineItems
        let visiableIndicatorDatas = self.visiableIndicatorDatas
                
        // 获取可见区域内数据的 metricBounds
        guard var metricBounds = visiableKLineItems.bounds else { return }
        mainRenderers.forEach { render in
            if let indicatorMetricBounds = visiableIndicatorDatas.bounds(for: render.key) {
                metricBounds.combine(other: indicatorMetricBounds)
            }
        }
        subRenderers.forEach { render in
            if let indicatorMetricBounds = visiableIndicatorDatas.bounds(for: render.key) {
                metricBounds.combine(other: indicatorMetricBounds)
            }
        }
                
        legendLabel.attributedText = legendText(for: mainIndicatorTypes)
        let legendSize = legendLabel.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        var offsetY = legendLabel.frame.origin.y
        if legendSize.height > 0 {
            offsetY += legendSize.height + 8
        }
        
        let itemWidth = styleManager.candleStyle.lineWidth + styleManager.candleStyle.gap
        let candlestickRect = CGRect(x: rect.minX, y: offsetY, width: rect.width, height: candlestickHeight - offsetY)

        // 创建转换器
        let candleTransformer = ChartTransformer(
            itemWidth: itemWidth,
            viewPort: candlestickRect,
            dataBounds: metricBounds,
            scrollView: scrollView
        )
        
        // 主图部分
        candleRenderer.draw(
            in: candlestickView.layer,
            items: visiableKLineItems,
            indices: scrollView.indices,
            context: RenderContext(
                transformer: candleTransformer,
                candleStyle: styleManager.candleStyle,
                chartStyle: nil
            )
        )
        
        let timelineRect = CGRect(x: rect.minX, y: 0, width: rect.width, height: timelineHeight)
        let tiemlineTransformer = ChartTransformer(
            itemWidth: itemWidth,
            viewPort: timelineRect,
            dataBounds: metricBounds,
            scrollView: scrollView
        )
        timelineRenderer.draw(
            in: timelineView.layer,
            items: visiableKLineItems,
            indices: scrollView.indices,
            context: RenderContext(
                transformer: tiemlineTransformer,
                candleStyle: styleManager.candleStyle,
                chartStyle: nil
            )
        )
        
        // 主图指标部分
        mainRenderers.forEach { renderer in
            renderer.draw(
                in: candlestickView.layer,
                items: visiableIndicatorDatas,
                indices: scrollView.indices,
                context: RenderContext(
                    transformer: candleTransformer,
                    candleStyle: styleManager.candleStyle,
                    chartStyle: styleManager.style(for: renderer.key)
                )
            )
        }
        
        subRenderers.forEach { renderer in
        }
    }
    
    private func legendText(for types: [IndicatorType]) -> NSAttributedString {
        let legendText = NSMutableAttributedString()
        guard let indicatorData = visiableIndicatorDatas.last else {
            return legendText
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 4
        formatter.minimumFractionDigits = 2
        
        types.enumerated().forEach { idx, type in
            let text = NSMutableAttributedString()
            for key in type.keys {
                if type == .vol {
                    let number = NSNumber(integerLiteral: indicatorData.item.volume)
                    let span = NSAttributedString(string: "\(key):\(formatter.string(from: number)!) ", attributes: [
                        .foregroundColor: styleManager.style(for: key)?.lineColor ?? .label,
                        .font: UIFont.systemFont(ofSize: 10)
                    ])
                    text.append(span)
                } else if let value: Double = indicatorData.getIndicator(forKey: key) {
                    let number = NSNumber(floatLiteral: value)
                    let span = NSAttributedString(string: "\(key):\(formatter.string(from: number)!) ", attributes: [
                        .foregroundColor: styleManager.style(for: key)?.lineColor ?? .label,
                        .font: UIFont.systemFont(ofSize: 10)
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
        if scrollView === self.scrollView {
            drawVisiableItems()
        }
    }
}
