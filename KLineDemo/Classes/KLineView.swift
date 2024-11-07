//
//  KLineView.swift
//  KLineDemo
//
//  Created by iya on 2024/10/31.
//

import UIKit
import SnapKit

enum KLineChartSection: Sendable {
    case mainChart, subChart
}

@MainActor class KLineView: UIView {
    
    private let scrollView = UIScrollView()
    private let canvasView = UIView()
    private let legendLabel = UILabel()
    
    private lazy var indicatorContainer = UICollectionView(frame: .zero, collectionViewLayout: makeIndicatorContainerLayout())
    private var indicatorListDataSource: UICollectionViewDiffableDataSource<Int, IndicatorType>!
    private var canvasLeftConstraint: Constraint!
    
    private var styleManager: StyleManager { .shared }
    private var dataProvider: KLineDataSource!
    private lazy var candlestickRenderer = CandlestickRenderer(style: styleManager.candlestickStyle)
    private var mainRenderers: [AnyChartRenderer<IndicatorData>] = []
    private var subRenderers: [AnyChartRenderer<IndicatorData>] = []
    private var mainIndicatorTypes: [IndicatorType] = []
    private var subIndicatorTypes: [IndicatorType] = []
    
    // pinch
    private var pinchCenterX: CGFloat = 0
    private var oldScale: CGFloat = 1
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        indicatorContainer.backgroundColor = .clear
        indicatorContainer.allowsMultipleSelection = true
        indicatorContainer.register(IndicatorCell.self, forCellWithReuseIdentifier: "cell")
        indicatorContainer.delegate = self
        addSubview(indicatorContainer)
        indicatorContainer.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(32)
        }
        setupIndicatorListDataSource()
        
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.delaysContentTouches = false
        scrollView.alwaysBounceVertical = false
        scrollView.layer.borderWidth = 1 / UIScreen.main.scale
        scrollView.layer.borderColor = UIColor.systemFill.cgColor
        
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(indicatorContainer.snp.top)
        }
        
        scrollView.addSubview(canvasView)
        canvasView.snp.makeConstraints { make in
            make.top.width.height.equalToSuperview()
            canvasLeftConstraint = make.left.equalTo(scrollView).offset(0).constraint
        }
        
        legendLabel.numberOfLines = 0
        addSubview(legendLabel)
        legendLabel.snp.makeConstraints { make in
            make.left.equalTo(8)
            make.right.lessThanOrEqualTo(-12)
            make.top.equalTo(8)
        }
        
        // pinch
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(Self.handlePinch(_:)))
        scrollView.addGestureRecognizer(pinch)
        
        dataProvider = KLineDataSource(calculators: [])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reloadData(items: [KLineItem], scrollPosition: ScrollPosition = .top) {
        Task {
            await dataProvider.update(items: items)
            redrawContent(scrollPosition: scrollPosition)
        }
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = 320
        return size
    }
}

extension KLineView: UICollectionViewDelegate {
    
    private func makeIndicatorContainerLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(50), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .estimated(50), heightDimension: .fractionalHeight(1))
        let group: NSCollectionLayoutGroup = if #available(iOS 16, *) {
            .horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 1)
        } else {
            .horizontal(layoutSize: groupSize, subitem: item, count: 1)
        }
        let section = NSCollectionLayoutSection(group: group)
        //section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 16
        section.contentInsets = .init(top: 0, leading: 12, bottom: 0, trailing: 12)
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal
        let layout = UICollectionViewCompositionalLayout(section: section, configuration: config)
        return layout
    }
    
    private func setupIndicatorListDataSource() {
        indicatorListDataSource = .init(collectionView: indicatorContainer, cellProvider: { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! IndicatorCell
            cell.label.text = itemIdentifier.rawValue
            return cell
        })
        
        // 配置主图指标
        let indicators: [IndicatorType] = [
            .ma, .ema
        ]
        var snapshot = NSDiffableDataSourceSnapshot<Int, IndicatorType>()
        snapshot.appendSections([0])
        snapshot.appendItems(indicators)
        indicatorListDataSource.apply(snapshot)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let snapshot = indicatorListDataSource.snapshot()
        let type = snapshot.itemIdentifiers[indexPath.item]
        drawMainIndicator(type: type)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let snapshot = indicatorListDataSource.snapshot()
        let type = snapshot.itemIdentifiers[indexPath.item]
        eraseMainIndicator(type: type)
    }
}

extension KLineView {
    
    private func drawMainIndicator(type: IndicatorType) {
        type.keys.forEach { key in
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
        reloadData(items: dataProvider.kLineItems, scrollPosition: .none)
    }
    
    private func eraseMainIndicator(type: IndicatorType) {
        type.keys.forEach { key in
            removeMainRenderer(for: key)
            dataProvider.removeCalculator(for: key)
        }
        if let index =  mainIndicatorTypes.firstIndex(of: type) {
            mainIndicatorTypes.remove(at: index)
        }
        reloadData(items: dataProvider.kLineItems, scrollPosition: .none)
    }
    
    private func drawSubIndicator(type: IndicatorType) {
        type.keys.forEach { key in
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
        reloadData(items: dataProvider.kLineItems, scrollPosition: .none)
    }
    
    private func eraseSubIndicator(type: IndicatorType) {
        type.keys.forEach { key in
            removeSubRenderer(for: key)
            dataProvider.removeCalculator(for: key)
        }
        if let index =  subIndicatorTypes.firstIndex(of: type) {
            subIndicatorTypes.remove(at: index)
        }
        reloadData(items: dataProvider.kLineItems, scrollPosition: .none)
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
        if let configurableReader = renderer as? StyleConfigurable {
            configurableReader.candlestickWidth = styleManager.candlestickStyle.lineWidth
            if let style = styleManager.style(for: configurableReader.indicatorKey) {
                configurableReader.chartStyle = style
            }
        }
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
        
        let newLineWidth = styleManager.candlestickStyle.lineWidth * (difValue + 1)
        guard (1...20).contains(newLineWidth) else { return }
        
        styleManager.candlestickStyle.lineWidth = newLineWidth
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
        let itemCountToBeDrawn = max(Int(ceil(scrollView.frame.width / (styleManager.candlestickStyle.gap + styleManager.candlestickStyle.lineWidth))) + 1, 0)
        let offsetX = max(scrollView.contentOffset.x, 0)
        let startIndex = max(Int(floor(offsetX / (styleManager.candlestickStyle.gap + styleManager.candlestickStyle.lineWidth))), 0)
        guard startIndex < dataProvider.kLineItems.count else { return 0..<0 }
        return startIndex..<min(startIndex + itemCountToBeDrawn, dataProvider.kLineItems.count)
    }
    
    private func redrawContent(scrollPosition: ScrollPosition) {
        // 获取当前的显示位置比例
        let currentOffsetX = scrollView.contentOffset.x
        let currentContentWidth = scrollView.contentSize.width
        let offsetRatio = currentContentWidth > 0 ? currentOffsetX / currentContentWidth : 0

        // 更新内容大小
        updateScrollViewContentSize()
        
        var offsetX: CGFloat
        if scrollPosition == .top {
            offsetX = 0
        } else if scrollPosition == .end {
            // 显示最后一屏
            offsetX = scrollView.contentSize.width - scrollView.frame.width
        } else {
            // 保持当前显示位置不变
            let updatedContentWidth = scrollView.contentSize.width
            offsetX = offsetRatio * updatedContentWidth
        }
        
        // 设置新的 contentOffset，确保不超出范围
        scrollView.contentOffset.x = max(0, min(offsetX, scrollView.contentSize.width - scrollView.frame.width))
        
        // 绘制可见的项目
        drawVisiableItems()
    }
    
    private func updateScrollViewContentSize() {
        let count = CGFloat(dataProvider.kLineItems.count)
        let contentWidth = count * styleManager.candlestickStyle.lineWidth + styleManager.candlestickStyle.gap * (count - 1)
        scrollView.contentSize = CGSize(
            width: max(contentWidth, scrollView.bounds.width),
            height: scrollView.bounds.height
        )
    }
    
    private func drawVisiableItems() {
        guard !visiableRange.isEmpty else { return }
        let offset = CGFloat(visiableRange.lowerBound) * (styleManager.candlestickStyle.gap + styleManager.candlestickStyle.lineWidth) - scrollView.contentOffset.x
        let rect = CGRect(x: offset, y: 0, width: canvasView.frame.width, height: canvasView.frame.height)
        drawVisiableItems(in: rect)
    }
    
    private var visiableItems: [KLineItem] {
        Array(dataProvider.kLineItems[visiableRange])
    }
    
    private var visiableIndicatorDatas: [IndicatorData] {
        Array(dataProvider.indicators[visiableRange])
    }
    
    private func drawVisiableItems(in rect: CGRect) {
        canvasView.layer.sublayers = nil
        
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
        let adjustedRect = rect.inset(by: .init(top: offsetY, left: 0, bottom: 0, right: 0))

        // 创建转换器
        let transformer = DefaultChartTransformer(
            itemWidth: styleManager.candlestickStyle.lineWidth + styleManager.candlestickStyle.gap,
            dataMin: metricBounds.minimum,
            dataMax: metricBounds.maximum,
            viewPort: adjustedRect
        )
        
        print(canvasView.frame.width)
        
        candlestickRenderer.style = styleManager.candlestickStyle
        candlestickRenderer.draw(in: canvasView.layer, rect: adjustedRect, transformer: transformer, values: visiableItems)
        
        mainRenderers.forEach { renderer in
            renderer.draw(in: canvasView.layer, rect: adjustedRect, transformer: transformer, values: visiableIndicatorDatas)
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
        canvasLeftConstraint.update(offset: max(scrollView.contentOffset.x, 0))
        drawVisiableItems()
    }
}

extension KLineView {
    
    enum ScrollPosition {
        case top, end, none
    }
}


private class IndicatorCell: UICollectionViewCell {
    
    let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isSelected: Bool {
        didSet {
            label.textColor = isSelected ? .label : .tertiaryLabel
        }
    }
}

import SwiftUI

#Preview {
    ViewController()
}
