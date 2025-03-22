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
    
    private let candlestickRenderer: CandlestickRenderer
    private let timelineRenderer: TimelineRenderer
    private var mainRenderers: [AnyChartRenderer<IndicatorData>] = []
    private var subRenderers: [AnyChartRenderer<IndicatorData>] = []
    
    private var mainIndicatorTypes: [IndicatorType] = []
    private var subIndicatorTypes: [IndicatorType] = []
    private let styleManager: StyleManager
    private var dataProvider: KLineDataSource!
    
    private var disposeBag = Set<AnyCancellable>()
    
    required init(styleManager: StyleManager = .shared) {
        self.styleManager = styleManager
        scrollView = HorizontalScrollView(styleManager: styleManager)
        indicatorTypeView = IndicatorTypeView(mainIndicators: [.ma, .ema])
        candlestickRenderer = CandlestickRenderer(style: styleManager.candleStyle)
        timelineRenderer = TimelineRenderer(style: styleManager.candleStyle)
        
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
        
        dataProvider = KLineDataSource(calculators: [])
        setupBindings()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reloadData(items: [KLineItem], scrollPosition: ScrollPosition = .end) {
        Task {
            scrollView.klineItemCount = items.count
            await dataProvider.update(items: items)
            scrollView.scroll(to: scrollPosition)
            drawVisiableItems()
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
                let renderer = MARenderer(period: period)
                injectIndicatorStyleIfNeeded(to: renderer)
                addMainRenderer(AnyChartRenderer(renderer, id: key))
                dataProvider.install(calculator: MACalculator(period: period))
            case .ema(let period):
                let renderer = EMARenderer(period: period)
                injectIndicatorStyleIfNeeded(to: renderer)
                addMainRenderer(AnyChartRenderer(renderer, id: key))
                dataProvider.install(calculator: EMACalculator(period: period))
            default:
                break
            }
        }
        if !mainIndicatorTypes.contains(type) {
            mainIndicatorTypes.append(type)
        }
        reloadData(items: dataProvider.kLineItems, scrollPosition: .current)
    }
    
    private func eraseMainIndicator(type: IndicatorType) {
        for key in type.keys {
            removeMainRenderer(for: key)
            dataProvider.removeCalculator(for: key)
        }
        if let index =  mainIndicatorTypes.firstIndex(of: type) {
            mainIndicatorTypes.remove(at: index)
        }
        reloadData(items: dataProvider.kLineItems, scrollPosition: .current)
    }
    
    private func drawSubIndicator(type: IndicatorType) {
        for key in type.keys {
            switch key {
            case .vol:
                break
            case .rsi(let period):
                let renderer = RSIRenderer(period: period)
                injectIndicatorStyleIfNeeded(to: renderer)
                addSubRenderer(AnyChartRenderer(renderer, id: key))
                dataProvider.install(calculator: RSICalculator(period: period))
            case .macd(let shortPeriod, let longPeriod, let signalPeriod):
                break
            default:
                break
            }
        }
        if !subIndicatorTypes.contains(type) {
            subIndicatorTypes.append(type)
        }
        reloadData(items: dataProvider.kLineItems, scrollPosition: .current)
    }
    
    private func eraseSubIndicator(type: IndicatorType) {
        for key in type.keys {
            removeSubRenderer(for: key)
            dataProvider.removeCalculator(for: key)
        }
        if let index =  subIndicatorTypes.firstIndex(of: type) {
            subIndicatorTypes.remove(at: index)
        }
        reloadData(items: dataProvider.kLineItems, scrollPosition: .current)
    }
    
    // 添加主图绘制器
    private func addMainRenderer(_ renderer: AnyChartRenderer<IndicatorData>) {
        mainRenderers.append(renderer)
    }
    
    // 添加副图绘制器
    private func addSubRenderer(_ renderer: AnyChartRenderer<IndicatorData>) {
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
    
    private func injectIndicatorStyleIfNeeded(to renderer: any ChartRenderer) {
        if let configurableReader = renderer as? IndicatorStyleConfigurable {
            configurableReader.candleWidth = styleManager.candleStyle.lineWidth
            if let style = styleManager.style(for: configurableReader.indicatorKey) {
                configurableReader.chartStyle = style
            }
        }
    }
    
    private func injectMainStyleIfNeeded(to renderer: any ChartRenderer) {
        if let configurableReader = renderer as? CandlestickStyleConfigurable {
            configurableReader.style = styleManager.candleStyle
        }
    }
}

extension KLineView {
   
    private func drawVisiableItems() {
        guard !scrollView.visiableRange.isEmpty else { return }
        let lowerBound = CGFloat(scrollView.visiableRange.lowerBound)
        let width = styleManager.candleStyle.gap + styleManager.candleStyle.lineWidth
        let offset = lowerBound * (width) - scrollView.contentOffset.x
        let rect = CGRect(x: offset, y: 0,
                          width: scrollView.contentView.bounds.width,
                          height: scrollView.contentView.bounds.height
        )
        drawVisiableItems(in: rect)
    }
    
    private var visiableItems: [KLineItem] {
        Array(dataProvider.kLineItems[scrollView.visiableRange])
    }
    
    private var visiableIndicatorDatas: [IndicatorData] {
        Array(dataProvider.indicators[scrollView.visiableRange])
    }
    
    private func drawVisiableItems(in rect: CGRect) {
        candlestickView.layer.sublayers = nil
        timelineView.layer.sublayers = nil
        
        // 获取可见区域内数据的 metricBounds
        guard var metricBounds = visiableItems.bounds else { return }
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
        
        let candlestickRect = CGRect(x: rect.minX, y: offsetY, width: rect.width, height: candlestickHeight - offsetY)

        // 创建转换器
        let candlestickTransformer = DefaultChartTransformer(
            itemWidth: styleManager.candleStyle.lineWidth + styleManager.candleStyle.gap,
            dataMin: metricBounds.minimum,
            dataMax: metricBounds.maximum,
            viewPort: candlestickRect
        )
        
        // 主图部分
        injectMainStyleIfNeeded(to: candlestickRenderer)
        candlestickRenderer.draw(
            in: candlestickView.layer,
            rect: candlestickRect,
            transformer: candlestickTransformer,
            items: dataProvider.kLineItems,
            range: scrollView.visiableRange
        )
        
        let timelineRect = timelineView.bounds
        injectMainStyleIfNeeded(to: timelineRenderer)
        let tiemlineTransformer = DefaultChartTransformer(
            itemWidth: styleManager.candleStyle.lineWidth + styleManager.candleStyle.gap,
            dataMin: metricBounds.minimum,
            dataMax: metricBounds.maximum,
            viewPort: timelineRect
        )
        timelineRenderer.draw(
            in: timelineView.layer,
            rect: timelineRect,
            transformer: candlestickTransformer,
            items: dataProvider.kLineItems,
            range: scrollView.visiableRange
        )
        
        // 主图指标部分
        mainRenderers.forEach { renderer in
            injectIndicatorStyleIfNeeded(to: renderer)
            renderer.draw(
                in: candlestickView.layer,
                rect: candlestickRect,
                transformer: candlestickTransformer,
                items: dataProvider.indicators,
                range: scrollView.visiableRange
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
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        types.enumerated().forEach { idx, type in
            let text = NSMutableAttributedString()
            type.keys.forEach { key in
                if type == .vol {
                    let number = NSNumber(integerLiteral: indicatorData.item.volume)
                    let span = NSAttributedString(string: "\(key):\(formatter.string(from: number)!) ", attributes: [
                        .foregroundColor: styleManager.style(for: key)?.lineColor ?? .label,
                        .font: UIFont.systemFont(ofSize: 10)
                    ])
                    text.append(span)
                } else if let value = indicatorData.getIndicator(forKey: key, as: Double.self) {
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
