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

    private let chartView = UIView()
    private let scrollView: HorizontalScrollView
    private let candlestickView = UIView()
    private let timelineView = UIView()
    private let legendLabel = UILabel()
    private let indicatorTypeView: IndicatorTypeView
    private let subIndicatorView = UIView()
    
    private let candleHeight: CGFloat = 300
    private let timelineHeight: CGFloat = 16
    private let indicatorTypeHeight: CGFloat = 32
    private let indicatorHeight: CGFloat = 64
    private var chartHeightConstraint: Constraint!
    
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
        indicatorTypeView = IndicatorTypeView(
            mainIndicators: [.vol, .ma, .ema],
            subIndicators: [.vol, .rsi]
        )
        
        super.init(frame: .zero)
        scrollView.delegate = self
        
        candlestickView.layer.masksToBounds = true
        timelineView.layer.masksToBounds = true
        subIndicatorView.layer.masksToBounds = true
        
        addSubview(chartView)
        addSubview(indicatorTypeView)
        
        chartView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(indicatorTypeView.snp.top)
            chartHeightConstraint = make.height.equalTo(scrollViewHeight).constraint
        }
        indicatorTypeView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(indicatorTypeHeight)
        }
        
        chartView.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        scrollView.contentView.addSubview(candlestickView)
        candlestickView.snp.makeConstraints { make in
            make.top.left.width.equalToSuperview()
            make.height.equalTo(candleHeight)
        }
        
        scrollView.contentView.addSubview(timelineView)
        timelineView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(candlestickView.snp.bottom)
            make.height.equalTo(timelineHeight)
        }
        
        scrollView.contentView.addSubview(subIndicatorView)
        subIndicatorView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(timelineView.snp.bottom)
            make.bottom.equalToSuperview()
        }
        
        legendLabel.numberOfLines = 0
        chartView.addSubview(legendLabel)
        legendLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.lessThanOrEqualTo(-100)
            make.top.equalTo(8)
        }

        setupBindings()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    private var scrollViewHeight: CGFloat {
        let subIndicatorCount = CGFloat(subIndicatorTypes.count)
        return candleHeight + timelineHeight + subIndicatorCount * indicatorHeight
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        drawVisiableItems()
    }
   
    private func updateChartHeightConstraint() {
        chartHeightConstraint.update(offset: scrollViewHeight)
    }
    
    private func setupBindings() {
        indicatorTypeView.drawIndicatorPublisher
            .sink { [unowned self] section, type in
                if section == .mainChart {
                    drawMainIndicator(type: type)
                } else {
                    drawSubIndicator(type: type)
                }
                updateChartHeightConstraint()
            }
            .store(in: &disposeBag)
        
        indicatorTypeView.eraseIndicatorPublisher
            .sink { [unowned self] section, type in
                if section == .mainChart {
                    eraseMainIndicator(type: type)
                } else {
                    eraseSubIndicator(type: type)
                }
                updateChartHeightConstraint()
            }
            .store(in: &disposeBag)
    }
}

extension KLineView {
    
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
}

extension KLineView {
    
    private func drawMainIndicator(type: IndicatorType) {
        for key in type.keys {
            switch key {
            case .ma(let period):
                let render = MARenderer(period: period)
                mainRenderers.append(AnyIndicatorRenderer(render))
                calculators.append(MACalculator(period: period))
            case .ema(let period):
                let render = EMARenderer(period: period)
                mainRenderers.append(AnyIndicatorRenderer(render))
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
            mainRenderers.removeAll { $0.key == key }
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
                let render = VOLRender()
                subRenderers.append(AnyIndicatorRenderer(render))
                calculators.append(VOLCalculator())
            case .rsi(let period):
                let render = RSIRenderer(period: period)
                subRenderers.append(AnyIndicatorRenderer(render))
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
            subRenderers.removeAll { $0.key == key }
            calculators.removeAll(where: { $0.key == key })
        }
        if let index =  subIndicatorTypes.firstIndex(of: type) {
            subIndicatorTypes.remove(at: index)
        }
        reloadData(items: kLineItems, scrollPosition: .current)
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
        subIndicatorView.layer.sublayers = nil
        
        let visiableKLineItems = self.visiableKLineItems
        let visiableIndicatorDatas = self.visiableIndicatorDatas
                
        // 获取可见区域内数据的 metricBounds
        guard var mainBounds = visiableKLineItems.priceBounds else { return }
        mainRenderers.forEach { renderer in
            if let indicatorMetricBounds = visiableIndicatorDatas.bounds(for: renderer.key) {
                mainBounds.combine(other: indicatorMetricBounds)
            }
        }
                
        legendLabel.attributedText = legendText(for: mainIndicatorTypes)
        let legendSize = legendLabel.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        var offsetY = legendLabel.frame.origin.y
        if legendSize.height > 0 {
            offsetY += legendSize.height + 8
        }
        
        let itemWidth = styleManager.candleStyle.lineWidth + styleManager.candleStyle.gap
        let candlestickRect = CGRect(x: rect.minX, y: offsetY, width: rect.width, height: candleHeight - offsetY)
        
        // 主图部分
        candleRenderer.draw(
            in: candlestickView.layer,
            items: visiableKLineItems,
            indices: scrollView.indices,
            context: RenderContext(
                transformer: ChartTransformer(
                    dataBounds: mainBounds,
                    itemWidth: itemWidth,
                    viewPort: candlestickRect
                ),
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
                    transformer: ChartTransformer(
                        dataBounds: mainBounds,
                        itemWidth: itemWidth,
                        viewPort: candlestickRect
                    ),
                    candleStyle: styleManager.candleStyle,
                    chartStyle: styleManager.style(for: renderer.key)
                )
            )
        }
        
        // 时间轴部分
        let timelineRect = CGRect(x: rect.minX, y: 0, width: rect.width, height: timelineHeight)
        timelineRenderer.draw(
            in: timelineView.layer,
            items: visiableKLineItems,
            indices: scrollView.indices,
            context: RenderContext(
                transformer: ChartTransformer(
                    dataBounds: mainBounds,
                    itemWidth: itemWidth,
                    viewPort: timelineRect
                ),
                candleStyle: styleManager.candleStyle,
                chartStyle: nil
            )
        )
        
        // 副图指标部分
        for (idx, renderer) in subRenderers.enumerated() {
            let subIndicatorRect = CGRect(
                x: rect.minX,
                y: CGFloat(idx) * indicatorHeight,
                width: rect.width,
                height: indicatorHeight
            )
            var subBounds = MetricBounds(maximum: -Double.infinity, minimum: Double.infinity)
            if let indicatorMetricBounds = visiableIndicatorDatas.bounds(for: renderer.key) {
                subBounds.combine(other: indicatorMetricBounds)
            }
            renderer.draw(
                in: subIndicatorView.layer,
                items: visiableIndicatorDatas,
                indices: scrollView.indices,
                context: RenderContext(
                    transformer: ChartTransformer(
                        dataBounds: subBounds,
                        itemWidth: itemWidth,
                        viewPort: subIndicatorRect
                    ),
                    candleStyle: styleManager.candleStyle,
                    chartStyle: styleManager.style(for: renderer.key)
                )
            )
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
                } else if let value = indicatorData.getIndicator(forKey: key) as? Double {
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
