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

    // MARK: - Views
    private let chartView = UIView()
    private let scrollView = HorizontalScrollView()
    private let candleView = CanvasView()
    private let legendLabel = UILabel()
    private let timelineView = CanvasView()
    private let subIndicatorView = CanvasView()
    private var indicatorTypeView = IndicatorTypeView()
    
    // MARK: - Height defines
    private let candleHeight: CGFloat = 320
    private let timelineHeight: CGFloat = 16
    private let indicatorTypeHeight: CGFloat = 32
    private let indicatorHeight: CGFloat = 80
    private var chartHeightConstraint: Constraint!
    
    private let backgroundRenderer = BackgroundRenderer()
    private let candleRenderer = CandleRenderer()
    private let timelineRenderer = TimelineRenderer()
    private let longPressRengerer = LongPressRenderer()
    private var mainRenderers: [AnyIndicatorRenderer] = []
    private var subRenderers: [AnyIndicatorRenderer] = []
    
    // MARK: - Data
    private var mainIndicatorTypes: [IndicatorType] = []
    private var subIndicatorTypes: [IndicatorType] = []
    private var kLineItems: [KLineItem] = []
    private var indicatorDatas: [IndicatorData] = []
    private var calculators: [any IndicatorCalculator] = []
    private var styleManager: StyleManager { .shared }
    
    private var disposeBag = Set<AnyCancellable>()
    
    // MARK: - Initializers
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        
        /* 这个地方应该开放接口，让调用方决定启用哪些指标 */
        indicatorTypeView.mainIndicators = [.vol, .ma, .ema]
        indicatorTypeView.subIndicators = [.vol, .rsi]
        
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

        // 添加手势
        // tap
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(Self.handleTap(_:))
        )
        tap.cancelsTouchesInView = false
        tap.delegate = self
        scrollView.contentView.addGestureRecognizer(tap)
        // long press
        let longPress = UILongPressGestureRecognizer(
            target: self,
            action: #selector(Self.handleLongPress(_:))
        )
        longPress.minimumPressDuration = 0.3
        longPress.allowableMovement = 2
        longPress.cancelsTouchesInView = false
        longPress.delegate = self
        scrollView.contentView.addGestureRecognizer(longPress)
        
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

// MARK: - 对外提供的绘制接口
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

// MARK: - 绘制和擦除指标
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

// MARK: - 绘制内容
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
        guard !kLineItems.isEmpty else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(false)
        CATransaction.setAnimationDuration(0)
        defer {
            CATransaction.commit()
        }
        // 清除绘制内容
        candleView.clean()
        timelineView.clean()
        subIndicatorView.clean()
        
        let visibleRange = scrollView.visibleRange
        let visibleRect = scrollView.frameOfVisibleRangeInConentView
        let indices = scrollView.indices
            
        
        // MARK: - 绘制主图
        drawMainChartSection(
            in: visibleRect,
            range: visibleRange,
            indices: indices
        )
        
        // MARK: - 绘制时间轴
        drawTimeline(
            in: visibleRect,
            range: visibleRange,
            indices: indices
        )
        
        // MARK: - 绘制副图
        drawSubChartSection(
            in: visibleRect,
            range: visibleRange,
            indices: indices
        )
    }
    
    /// 绘制主图区域内的所有内容，包括图例，背景，蜡烛图，主图指标。
    private func drawMainChartSection(
        in visibleRect: CGRect,
        range: Range<Int>,
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
        
        let transformer = Transformer(
            contentInset: candleInset,
            dataBounds: dataBounds,
            viewPort: rect,
            itemCount: kLineItems.count,
            visibleRange: range,
            indices: indices
        )
        let itemRenderData = RenderData(
            items: kLineItems,
            visibleRange: range,
            indices: indices
        )
        let indicatorRenderData = RenderData(
            items: indicatorDatas as [Any],
            visibleRange: range,
            indices: indices
        )
        
        // 蜡烛图背景
        backgroundRenderer.transformer = transformer
        backgroundRenderer.draw(in: candleView.canvas, data: itemRenderData)
        
        // 蜡烛图
        candleRenderer.transformer = transformer
        candleRenderer.view = candleView
        candleRenderer.draw(in: candleView.canvas, data: itemRenderData)
        
        // 主图指标
        mainRenderers.forEach { renderer in
            renderer.transformer = transformer
            renderer.draw(in: candleView.canvas, data: indicatorRenderData)
        }
    }
    
    /// 绘制时间轴
    private func drawTimeline(in rect: CGRect, range: Range<Int>, indices: Range<Int>) {
        // 指标数据在 layer 中的可见区域
        let viewPort = CGRect(
            x: rect.minX, y: 0,
            width: rect.width,
            height: timelineHeight
        )
        // 创建一个新的 transformer
        let transformer = Transformer(
            dataBounds: .zero,
            viewPort: viewPort,
            itemCount: kLineItems.count,
            visibleRange: range,
            indices: indices
        )
        // 创建一个新的 RenderData
        let renderData = RenderData(
            items: kLineItems,
            visibleRange: range,
            indices: indices
        )
        // 绘制时间轴
        timelineRenderer.transformer = transformer
        timelineRenderer.draw(in: timelineView.canvas, data: renderData)
    }
    
    private func drawSubChartSection(in rect: CGRect, range: Range<Int>, indices: Range<Int>) {
        for (idx, renderer) in subRenderers.enumerated() {
            // 获取可见区域内数据的 metricBounds
            var dataBounds = MetricBounds.zero
            renderer.type.keys.forEach { key in
                if let indicatorMetricBounds = visibleDatas.bounds(for: key) {
                    dataBounds.combine(other: indicatorMetricBounds)
                }
            }
            // 指标数据在 layer 中的可见区域
            let viewPort = CGRect(
                x: rect.minX,
                y: CGFloat(idx) * indicatorHeight,
                width: rect.width,
                height: indicatorHeight
            )
            // 创建一个新的 transformer
            let transformer = Transformer(
                dataBounds: dataBounds,
                viewPort: viewPort,
                itemCount: indicatorDatas.count,
                visibleRange: range,
                indices: indices
            )
            // 创建一个新的 RenderData
            let renderData: RenderData<Any> = RenderData(
                items: indicatorDatas,
                visibleRange: range,
                indices: indices
            )
            // 绘制指标
            renderer.transformer = transformer
            renderer.draw(in: subIndicatorView.canvas, data: renderData)
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
                if let value = indicatorData.indicator(forKey: key) {
                    number = value.doubeValue
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
            if longPressRengerer.layer.superlayer != nil {
                longPressRengerer.layer.sublayers = nil
                longPressRengerer.layer.removeFromSuperlayer()
            }
        }
    }
}

// MARK: - 手势处理
extension KLineView: UIGestureRecognizerDelegate {
    
    @objc private func handleTap(_ tap: UITapGestureRecognizer) {
        handleTapHandleLongPressGesture(tap)
    }

    @objc private func handleLongPress(_ longPress: UILongPressGestureRecognizer) {
        switch longPress.state {
        case .began, .changed:
            handleTapHandleLongPressGesture(longPress)
        default: break
        }
    }
    
    private func handleTapHandleLongPressGesture(_ gesture: UIGestureRecognizer) {
        // MARK: - 绘制长按图层
        guard let view = gesture.view else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(false)
        CATransaction.setAnimationDuration(0)
        defer {
            CATransaction.commit()
        }
        
        var location = gesture.location(in: view)
        location.y = min(max(0, location.y), view.bounds.height - 1)
        
        var transformer: Transformer?
        // 判断当前是在哪个区域
        if candleView.frame.contains(location) {
            // 主图区域
            transformer = candleRenderer.transformer
        } else if timelineView.frame.contains(location) {
            // 时间轴区域
            transformer = timelineRenderer.transformer
        } else if !subRenderers.isEmpty {
            // 计算当前在副图区域的哪个指标上
            let offsetY = location.y - subIndicatorView.frame.minY
            let idx = min(Int(ceil(offsetY / indicatorHeight)), subRenderers.count - 1)
            let renderer = subRenderers[idx]
            transformer = renderer.transformer
        }
        
        guard let transformer = transformer else { return }
        
        longPressRengerer.transformer = transformer
        longPressRengerer.layer.frame = chartView.bounds
        longPressRengerer.layer.sublayers = nil
        if longPressRengerer.layer.superlayer == nil {
            chartView.layer.addSublayer(longPressRengerer.layer)
        }
        var data = RenderData(
            items: indicatorDatas,
            visibleRange: scrollView.visibleRange,
            indices: scrollView.indices
        )
        data.gestureLocation = location
        longPressRengerer.draw(in: longPressRengerer.layer, data: data)
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is UIControl {
            return false
        }
        return true
    }
}

final class LongPressRenderer: ChartRenderer {
    
    let layer = CALayer()
    
    private let dateLabel = UILabel()
    
    var transformer: Transformer?
    
    typealias Item = IndicatorData
    
    init() {
        dateLabel.font = .monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        dateLabel.textAlignment = .center
        dateLabel.backgroundColor = .label
        dateLabel.textColor = .systemBackground
        dateLabel.layer.cornerRadius = 4
        dateLabel.layer.masksToBounds = true
    }
    
    func draw(in layer: CALayer, data: RenderData<IndicatorData>) {
        guard let transformer = transformer else { return }
        let rect = layer.bounds
        
        // 绘制十字线的y轴，从最顶部一直到最底部
        let location: CGPoint = data.gestureLocation!
        
        // MARK: - 绘制y轴虚线
        let dashLine = CAShapeLayer()
        dashLine.strokeColor = UIColor.label.cgColor
        dashLine.lineWidth = 1 / UIScreen.main.scale
        dashLine.lineDashPattern = [2, 2]
        let path = UIBezierPath()
        path.move(to: CGPoint(x: location.x, y: 0))
        path.addLine(to: CGPoint(x: location.x, y: rect.height))
        dashLine.path = path.cgPath
        layer.addSublayer(dashLine)
        
        // MARK: - 绘制日期时间轴
        if let index = transformer.indexOfVisibleItem(at: location.x) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
            let item = data.items[index].item
            let date = Date(timeIntervalSince1970: TimeInterval(item.timestamp))
            let timeString = dateFormatter.string(from: date)
            dateLabel.text = timeString
            var size = dateLabel.systemLayoutSizeFitting(rect.size)
            size.width += 8
            var x = location.x - size.width * 0.5
            x = max(0, min(x, rect.width - size.width))
            dateLabel.frame = CGRect(x: x, y: 320, width: size.width, height: 16)
            layer.addSublayer(dateLabel.layer)
        }
    }
}
