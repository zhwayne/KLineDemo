//
//  HorizontalScrollView.swift
//  KLineDemo
//
//  Created by work on 2025/3/22.
//

import Foundation
import UIKit

enum ScrollPosition {
    case top, end, current
}

final class HorizontalScrollView: UIScrollView {
    final class ContentView: UIView { }
    
    var klineItemCount: Int = 0 {
        didSet { updateScrollViewContentSize() }
    }
    
    // 样式管理器
    private let styleManager: StyleManager
    private var candleStyle: CandleStyle { styleManager.candleStyle }
    
    let contentView = ContentView()
    
    // pinch
    private var pinchCenterX: CGFloat = 0
    private var oldScale: CGFloat = 1
    
    required init(styleManager: StyleManager) {
        self.styleManager = styleManager
        super.init(frame: .zero)
        alwaysBounceHorizontal = true
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        delaysContentTouches = false
        alwaysBounceVertical = false
                
        addSubview(contentView)
        
        // pinch
        let pinch = UIPinchGestureRecognizer(
            target: self,
            action: #selector(Self.handlePinch(_:))
        )
        addGestureRecognizer(pinch)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let origin = CGPoint(x: contentOffset.x, y: 0)
        let contentFrame = CGRect(origin: origin, size: bounds.size)
        contentView.frame = contentFrame
        let padding = (bounds.width) / 2
        contentInset = UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
    }
    
    @objc private func handlePinch(_ pinch: UIPinchGestureRecognizer) {
        switch pinch.state {
        case .began:
            isScrollEnabled = false
            let p1 = pinch.location(ofTouch: 0, in: contentView)
            let p2 = pinch.location(ofTouch: 1, in: contentView)
            pinchCenterX = (p1.x + p2.x) / 2
            oldScale = 1.0
        case .changed:
            break;
            
        default:
            isScrollEnabled = true
        }
        
        let difValue = pinch.scale - oldScale
        
        let newLineWidth = candleStyle.lineWidth * (difValue + 1)
        guard (1...40).contains(newLineWidth) else { return }
        
        styleManager.candleStyle.lineWidth = newLineWidth
        oldScale = pinch.scale
        
        // 更新 contentSize
        let contentOffsetAtPinch = contentOffset.x + pinchCenterX
        let oldContentSize = contentSize
        updateScrollViewContentSize()
        
        
        // 算新的内容偏移量
        let scale = contentSize.width / oldContentSize.width
        let newContentOffsetAtPinch = contentOffsetAtPinch * scale
        var newContentOffsetX = newContentOffsetAtPinch - pinchCenterX
        
        // 限制偏移量的范围
        newContentOffsetX = max(-contentInset.left, newContentOffsetX)
        let maxContentOffsetX = contentSize.width - bounds.width + contentInset.right
        newContentOffsetX = min(maxContentOffsetX, newContentOffsetX)

        // 更新 contentOffset 并重绘内容
        if contentOffset.x == newContentOffsetX {
            setNeedsLayout()
            layoutIfNeeded()
            delegate?.scrollViewDidScroll?(self)
        } else {
            contentOffset.x = newContentOffsetX
        }
    }
    
    private func updateScrollViewContentSize() {
        let count = CGFloat(klineItemCount)
        let itemWidth = candleStyle.lineWidth + candleStyle.gap
        let contentWidth = count * itemWidth - candleStyle.gap
        let width = max(contentWidth, bounds.width)
        let height = bounds.height
        contentSize = CGSize(width: width, height: height)
    }
}

extension HorizontalScrollView {
    
    var indices: Range<Int> {
        let itemWidth = candleStyle.lineWidth + candleStyle.gap
        let visiableWidth = frame.width + itemWidth
        let itemCountToBeDrawn = Int(ceil(visiableWidth / itemWidth))
        let startIndex = Int(floor(contentOffset.x / itemWidth))
        guard startIndex < klineItemCount else { return 0..<0 }
        return startIndex..<(startIndex + itemCountToBeDrawn)
    }
    
    var visiableRange: Range<Int> {
        let range = indices
        let lowerBound = min(max(range.lowerBound, 0), klineItemCount)
        let upperBound = max(min(range.upperBound, klineItemCount), 0)
        return lowerBound..<upperBound
//        let itemWidth = candleStyle.lineWidth + candleStyle.gap
//        var visiableWidth = if contentOffset.x < 0 {
//            max(frame.width + contentOffset.x, 0)
//        } else if contentOffset.x > contentSize.width - bounds.width {
//            max(contentSize.width - contentOffset.x, 0)
//        } else {
//            frame.width
//        }
//        visiableWidth += itemWidth
//        let itemCountToBeDrawn = max(Int(ceil(visiableWidth / itemWidth)), 0)
//        let startIndex = max(Int(floor(contentOffset.x / itemWidth)), 0)
//        guard startIndex < klineItemCount else { return 0..<0 }
//        return startIndex..<min(startIndex + itemCountToBeDrawn, klineItemCount)
    }
    
    var visiableRect: CGRect {
        guard !visiableRange.isEmpty else { return .zero }
        let lowerBound = CGFloat(visiableRange.lowerBound)
        let upperBound = CGFloat(visiableRange.upperBound)
        let itemWidth = candleStyle.lineWidth + candleStyle.gap
        let offset = lowerBound * (itemWidth) - contentOffset.x
        let width = (upperBound - lowerBound) * itemWidth
        let height = contentView.bounds.height
        return CGRect(x: offset, y: 0, width: width, height: height)
    }
    
    func scroll(to scrollPosition: ScrollPosition) {
        // 获取当前的显示位置比例
        var offsetRatio: CGFloat = 0
        if contentSize.width > 0 {
            offsetRatio = contentOffset.x / contentSize.width
        }

        // 更新内容大小
        // updateScrollViewContentSize()
        
        var offsetX: CGFloat = 0
        if scrollPosition == .top {
            offsetX = -contentInset.left
        } else if scrollPosition == .end {
            // 显示最后一屏
            offsetX = contentSize.width - frame.width + contentInset.right
        } else {
            // 保持当前显示位置不变
            offsetX = offsetRatio * contentSize.width
        }
        
        // 设置新的 contentOffset，确保不超出范围
        contentOffset.x = offsetX
    }
}
