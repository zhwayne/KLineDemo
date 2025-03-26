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
    private let candleView = UIView()
    private let timelineView = UIView()
    private let legendLabel = UILabel()
    private let indicatorTypeView: IndicatorTypeView
    private let subIndicatorView = UIView()
    
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
            make.left.right.equalToSuperview()
            make.top.equalTo(candleView.snp.bottom)
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
    
    public func reloadData(items: [KLineItem], scrollPosition: ScrollPosition) {
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
        mainIndicatorTypes.append(type)
        if type != .vol {
            mainRenderers.append(type.renderer)
        }
        calculators.append(contentsOf: type.keys.map(\.calculator))
        reloadData(items: kLineItems, scrollPosition: .current)
    }
    
    private func eraseMainIndicator(type: IndicatorType) {
        mainIndicatorTypes.removeAll(where: { $0 == type })
        mainRenderers.removeAll { $0.type == type }
        for key in type.keys {
            calculators.removeAll(where: { $0.key == key })
        }
        reloadData(items: kLineItems, scrollPosition: .current)
    }
    
    private func drawSubIndicator(type: IndicatorType) {
        subIndicatorTypes.append(type)
        subRenderers.append(type.renderer)
        calculators.append(contentsOf: type.keys.map(\.calculator))
        reloadData(items: kLineItems, scrollPosition: .current)
    }
    
    private func eraseSubIndicator(type: IndicatorType) {
        subIndicatorTypes.removeAll(where: { $0 == type })
        subRenderers.removeAll { $0.type == type }
        for key in type.keys {
            calculators.removeAll(where: { $0.key == key })
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
        candleView.layer.sublayers = nil
        timelineView.layer.sublayers = nil
        subIndicatorView.layer.sublayers = nil
        
        let visiableKLineItems = self.visiableKLineItems
        let visiableIndicatorDatas = self.visiableIndicatorDatas
                
        // 获取可见区域内数据的 metricBounds
        guard var mainBounds = visiableKLineItems.priceBounds else { return }
        mainRenderers.forEach { renderer in
            renderer.type.keys.forEach { key in
                if let indicatorMetricBounds = visiableIndicatorDatas.bounds(for: key) {
                    mainBounds.combine(other: indicatorMetricBounds)
                }
            }
        }
             
        // TODO: 可以考虑将 legend 渲染方式替换成 ChartRenderer。
        legendLabel.attributedText = legendText(for: mainIndicatorTypes)
        let legendSize = legendLabel.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        var offsetY = legendLabel.frame.origin.y
        if legendSize.height > 0 {
            offsetY += legendSize.height + 8
        } else {
            offsetY = 12
        }
        
        let itemWidth = styleManager.candleStyle.width + styleManager.candleStyle.gap
        let candleRect = CGRect(x: rect.minX, y: 0, width: rect.width, height: candleHeight)
        let candleTransformer = ChartTransformer(
            inset: AxisInset(top: offsetY, bottom: 12),
            dataBounds: mainBounds,
            itemWidth: itemWidth,
            viewPort: candleRect
        )
        
        // MARK: - 蜡烛图背景
        backgroundRenderer.draw(
            in: candleView.layer,
            context: RenderContext(
                transformer: candleTransformer,
                items: visiableKLineItems,
                indices: scrollView.indices,
                styleManager: styleManager
            )
        )
        
        // MARK: - 蜡烛图
        candleRenderer.draw(
            in: candleView.layer,
            context: RenderContext(
                transformer: candleTransformer,
                items: visiableKLineItems,
                indices: scrollView.indices,
                styleManager: styleManager
            )
        )

        // MARK: - 主图指标
        mainRenderers.forEach { renderer in
            renderer.draw(
                in: candleView.layer,
                context: RenderContext(
                    transformer: candleTransformer,
                    items: visiableIndicatorDatas,
                    indices: scrollView.indices,
                    styleManager: styleManager
                )
            )
        }
        
        // MARK: - 时间轴
        let timelineRect = CGRect(x: rect.minX, y: 0, width: rect.width, height: timelineHeight)
        let timelineTransformer = ChartTransformer(
            dataBounds: mainBounds,
            itemWidth: itemWidth,
            viewPort: timelineRect
        )
        timelineRenderer.draw(
            in: timelineView.layer,
            context: RenderContext(
                transformer: timelineTransformer,
                items: visiableKLineItems,
                indices: scrollView.indices,
                styleManager: styleManager
            )
        )
        
        // MARK: - 副图
        for (idx, renderer) in subRenderers.enumerated() {
            let indicatorRect = CGRect(
                x: rect.minX,
                y: CGFloat(idx) * indicatorHeight,
                width: rect.width,
                height: indicatorHeight
            )
            var dataBounds = MetricBounds.initial
            renderer.type.keys.forEach { key in
                if let indicatorMetricBounds = visiableIndicatorDatas.bounds(for: key) {
                    dataBounds.combine(other: indicatorMetricBounds)
                }
            }
            let transformer = ChartTransformer(
                dataBounds: dataBounds,
                itemWidth: itemWidth,
                viewPort: indicatorRect
            )
            renderer.draw(
                in: subIndicatorView.layer,
                context: RenderContext(
                    transformer: transformer,
                    items: visiableIndicatorDatas,
                    indices: scrollView.indices,
                    styleManager: styleManager
                )
            )
        }
    }
    
    private func legendText(for types: [IndicatorType]) -> NSAttributedString {
        let legendText = NSMutableAttributedString()
        guard let indicatorData = visiableIndicatorDatas.last else {
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
            drawVisiableItems()
        }
    }
}
