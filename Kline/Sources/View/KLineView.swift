//
//  KLineView.swift
//  KLineDemo
//
//  Created by iya on 2024/10/31.
//

import UIKit
import SnapKit
import Combine

enum ChartSection: Sendable {
    case mainChart, subChart
}

@MainActor public final class KLineView: UIView {

    private let chartView = UIView()
    private let scrollView: HorizontalScrollView
    private let candleView = CanvansView()
    private let timelineView = CanvansView()
    private let legendLabel = UILabel()
    private let indicatorTypeView: IndicatorTypeView
    private let subIndicatorView = CanvansView()
    
    private let candleHeight: CGFloat = 320
    private let timelineHeight: CGFloat = 16
    private let indicatorTypeHeight: CGFloat = 32
    private let indicatorHeight: CGFloat = 80
    private var chartHeightConstraint: Constraint!
    
    private let backgroundRenderer = BackgroundRenderer()
    private let candleRenderer = CandleRenderer()
    private let timelineRenderer = TimelineRenderer()
    private var mainRenderers: [AnyIndicatorRenderer] = []
    private var subRenderers: [AnyIndicatorRenderer] = []
    
    private var mainIndicatorTypes: [IndicatorType] = []
    private var subIndicatorTypes: [IndicatorType] = []
    private let styleManager: StyleManager
    
    private var indicatorDatas: [IndicatorData] = []
    private var kLineItems: [KLineItem] = []
    private var calculators: [any IndicatorCalculator] = []
    
    private var disposeBag = Set<AnyCancellable>()
    
    public required init(styleManager: StyleManager) {
        self.styleManager = styleManager
        scrollView = HorizontalScrollView(styleManager: styleManager)
        indicatorTypeView = IndicatorTypeView(
            mainIndicators: [.vol, .ma, .ema],
            subIndicators: [.vol, .rsi]
        )
        
        super.init(frame: .zero)
        scrollView.delegate = self
        
        candleView.layer.masksToBounds = true
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
        
        scrollView.contentView.addSubview(candleView)
        candleView.snp.makeConstraints { make in
            make.top.left.width.equalToSuperview()
            make.height.equalTo(candleHeight)
        }
        
        scrollView.contentView.addSubview(timelineView)
        timelineView.snp.makeConstraints { make in
            make.left.width.equalToSuperview()
            make.top.equalTo(candleView.snp.bottom)
            make.height.equalTo(timelineHeight)
        }
        
        scrollView.contentView.addSubview(subIndicatorView)
        subIndicatorView.snp.makeConstraints { make in
            make.left.width.equalToSuperview()
            make.top.equalTo(timelineView.snp.bottom)
            make.bottom.equalToSuperview()
        }
        
        legendLabel.numberOfLines = 0
        chartView.addSubview(legendLabel)
        legendLabel.snp.makeConstraints { make in
            make.left.equalTo(12)
            make.width.equalToSuperview().multipliedBy(0.8)
            make.top.equalTo(8)
        }

        setupBindings()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    private var scrollViewHeight: CGFloat {
        let subIndicatorCount = CGFloat(subIndicatorTypes.count)
        return candleHeight + timelineHeight + subIndicatorCount * indicatorHeight
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        drawVisibleContent()
    }
   
    private func updateChartHeightConstraint() {
        chartHeightConstraint.update(offset: scrollViewHeight)
    }
    
    private func setupBindings() {
        indicatorTypeView.drawIndicatorPublisher
            .sink { [unowned self] section, type in
                Task(priority: .userInitiated) {
                    if section == .mainChart {
                        await drawMainIndicator(type: type)
                    } else {
                        await drawSubIndicator(type: type)
                    }
                    updateChartHeightConstraint()
                }
            }
            .store(in: &disposeBag)
        
        indicatorTypeView.eraseIndicatorPublisher
            .sink { [unowned self] section, type in
                Task(priority: .userInitiated) {
                    if section == .mainChart {
                        await eraseMainIndicator(type: type)
                    } else {
                        await eraseSubIndicator(type: type)
                    }
                    updateChartHeightConstraint()
                }
            }
            .store(in: &disposeBag)
        
        NotificationCenter.default.publisher(for: .scrollToTop)
            .sink { [weak self] _ in
                self?.scrollView.scroll(to: .right, animated: true)
            }
            .store(in: &disposeBag)
    }
}

extension KLineView {
    
    public func draw(items: [KLineItem], scrollPosition: ScrollPosition) {
        Task {
            kLineItems = items
            scrollView.klineItemCount = items.count
            await redrawContent(scrollPosition: scrollPosition)
        }
    }
    
    private func redrawContent(scrollPosition: ScrollPosition) async {
        do {
            indicatorDatas = try await kLineItems.decorateWithIndicators(calculators: calculators)
            scrollView.scroll(to: scrollPosition, animated: false)
            drawVisibleContent()
        } catch {
            print(error)
        }
    }
}

extension KLineView {
    
    private func drawMainIndicator(type: IndicatorType) async {
        mainIndicatorTypes.append(type)
        if type != .vol {
            mainRenderers.append(type.renderer)
        }
        calculators.append(contentsOf: type.keys.map(\.calculator))
        await redrawContent(scrollPosition: .current)
    }
    
    private func eraseMainIndicator(type: IndicatorType) async {
        mainIndicatorTypes.removeAll(where: { $0 == type })
        mainRenderers.removeAll { $0.type == type }
        for key in type.keys {
            calculators.removeAll(where: { $0.key == key })
        }
        await redrawContent(scrollPosition: .current)
    }
    
    private func drawSubIndicator(type: IndicatorType) async {
        subIndicatorTypes.append(type)
        subRenderers.append(type.renderer)
        calculators.append(contentsOf: type.keys.map(\.calculator))
        await redrawContent(scrollPosition: .current)
    }
    
    private func eraseSubIndicator(type: IndicatorType) async {
        subIndicatorTypes.removeAll(where: { $0 == type })
        subRenderers.removeAll { $0.type == type }
        for key in type.keys {
            calculators.removeAll(where: { $0.key == key })
        }
        await redrawContent(scrollPosition: .current)
    }
}

extension KLineView {
   
    private var visibleItems: ArraySlice<KLineItem> {
        if kLineItems.isEmpty { return [] }
        return kLineItems[scrollView.visibleRange]
    }
    
    private var visibleDatas: ArraySlice<IndicatorData> {
        if indicatorDatas.isEmpty { return [] }
        return indicatorDatas[scrollView.visibleRange]
    }
    
    private func drawVisibleContent() {
        CATransaction.begin()
        CATransaction.setDisableActions(false)
        CATransaction.setAnimationDuration(0)
        defer {
            CATransaction.commit()
        }
        candleView.canvans.sublayers = nil
        timelineView.canvans.sublayers = nil
        subIndicatorView.canvans.sublayers = nil
        
        let visibleRange = scrollView.visibleRange
        let visibleRect = scrollView.frameOfVisibleRangeInConentView
        let indices = scrollView.indices
            
        
        // MARK: - 绘制主图
        drawMainChartSection(
            in: visibleRect,
            visibleRange: visibleRange,
            indices: indices
        )
        
        // MARK: - 绘制时间轴
        drawTimeline(
            in: visibleRect,
            visibleRange: visibleRange,
            indices: indices
        )
        
        // MARK: - 绘制副图
        drawSubChartSection(
            in: visibleRect,
            visibleRange: visibleRange,
            indices: indices
        )
    }
    
    /// 绘制主图区域内的所有内容，包括图例，背景，蜡烛图，主图指标。
    private func drawMainChartSection(
        in visibleRect: CGRect,
        visibleRange: Range<Int>,
        indices: Range<Int>
    ) {
        
        // 绘制图例。可以考虑将 legend 渲染方式替换成 ChartRenderer。
        legendLabel.attributedText = legendText(for: mainIndicatorTypes)
        let legendSize = legendLabel.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        var offsetY: CGFloat = 16
        if legendSize.height > 0 {
            offsetY = legendLabel.frame.origin.y + legendSize.height + 8
        }
        
        let candleInset = AxisInset(top: offsetY, bottom: 16)
        let itemWidth = styleManager.candleStyle.width + styleManager.candleStyle.gap
        let rect = CGRect(
            x: visibleRect.minX,
            y: 0,
            width: visibleRect.width,
            height: candleHeight
        )
        
        // 获取可见区域内数据的 metricBounds
        var dataBounds = visibleItems.priceBounds
        
        mainRenderers.forEach { renderer in
            renderer.type.keys.forEach { key in
                if let indicatorMetricBounds = visibleDatas.bounds(for: key) {
                    dataBounds.combine(other: indicatorMetricBounds)
                }
            }
        }
        
        let candleTransform = ChartTransformer(
            inset: candleInset,
            dataBounds: dataBounds,
            itemWidth: itemWidth,
            viewPort: rect
        )
        let itemCtx = RenderContext(
            transformer: candleTransform,
            items: kLineItems,
            visibleRange: visibleRange,
            indices: scrollView.indices,
            styleManager: styleManager,
            canvansView: candleView
        )
        let dataCtx: RenderContext<Any> = RenderContext(
            transformer: candleTransform,
            items: indicatorDatas,
            visibleRange: visibleRange,
            indices: indices,
            styleManager: styleManager,
            canvansView: candleView
        )
        
        // 蜡烛图背景
        backgroundRenderer.draw(in: candleView.canvans, context: itemCtx)
        
        // 蜡烛图
        candleRenderer.draw(in: candleView.canvans, context: itemCtx)
        
        // 主图指标
        mainRenderers.forEach { renderer in
            renderer.draw(in: candleView.canvans, context: dataCtx)
        }
    }
    
    /// 绘制时间轴
    private func drawTimeline(
        in visibleRect: CGRect,
        visibleRange: Range<Int>,
        indices: Range<Int>
    ) {
        let rect = CGRect(
            x: visibleRect.minX,
            y: 0,
            width: visibleRect.width,
            height: timelineHeight
        )
        let itemWidth = styleManager.candleStyle.width + styleManager.candleStyle.gap
        
        let transformer = ChartTransformer(
            dataBounds: .zero,
            itemWidth: itemWidth,
            viewPort: rect
        )
        let itemCtx = RenderContext(
            transformer: transformer,
            items: kLineItems,
            visibleRange: visibleRange,
            indices: indices,
            styleManager: styleManager,
            canvansView: timelineView
        )
        timelineRenderer.draw(in: timelineView.canvans, context: itemCtx)
    }
    
    private func drawSubChartSection(
        in visibleRect: CGRect,
        visibleRange: Range<Int>,
        indices: Range<Int>
    ) {
        let itemWidth = styleManager.candleStyle.width + styleManager.candleStyle.gap
        for (idx, renderer) in subRenderers.enumerated() {
            let indicatorRect = CGRect(
                x: visibleRect.minX,
                y: CGFloat(idx) * indicatorHeight,
                width: visibleRect.width,
                height: indicatorHeight
            )
            var dataBounds = MetricBounds.zero
            renderer.type.keys.forEach { key in
                if let indicatorMetricBounds = visibleDatas.bounds(for: key) {
                    dataBounds.combine(other: indicatorMetricBounds)
                }
            }
            let transformer = ChartTransformer(
                dataBounds: dataBounds,
                itemWidth: itemWidth,
                viewPort: indicatorRect
            )
            let dataCtx: RenderContext<Any> = RenderContext(
                transformer: transformer,
                items: indicatorDatas,
                visibleRange: visibleRange,
                indices: indices,
                styleManager: styleManager,
                canvansView: subIndicatorView
            )
            renderer.draw(in: subIndicatorView.canvans, context: dataCtx)
        }
    }
    
    private func legendText(for types: [IndicatorType]) -> NSAttributedString {
        let legendText = NSMutableAttributedString()
        guard let indicatorData = visibleDatas.last else {
            return legendText
        }
        
        types.enumerated().forEach { idx, type in
            let text = NSMutableAttributedString()
            for key in type.keys {
                var number: Double = 0
                if let value = indicatorData.getIndicator(forKey: key) {
                    number = NSDecimalNumber(string: "\(value)").doubleValue
                }
                let indicatorStyle = styleManager.indicatorStyle(for: key)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineHeightMultiple = 1.1
                let span = NSAttributedString(
                    string: "\(key):\(styleManager.format(value: number))  ",
                    attributes: [
                        .foregroundColor: indicatorStyle.strokeColor,
                        .font: indicatorStyle.font,
                        .paragraphStyle: paragraphStyle
                    ]
                )
                text.append(span)
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
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === self.scrollView {
            drawVisibleContent()
        }
    }
}
