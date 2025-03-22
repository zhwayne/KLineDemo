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
        contentView.frame = contentFrame.inset(by: contentInset)
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
        
        let newLineWidth = styleManager.candleStyle.lineWidth * (difValue + 1)
        guard (1...40).contains(newLineWidth) else { return }
        
        styleManager.candleStyle.lineWidth = newLineWidth
        oldScale = pinch.scale
        
        // 更新 contentSize
        let contentOffsetAtPinch = contentOffset.x + pinchCenterX
        let oldContentSize = contentSize
        updateScrollViewContentSize()
        
        
        // 算新的内容偏移量
        let newContentOffsetAtPinch = contentOffsetAtPinch * (contentSize.width / oldContentSize.width)
        var newContentOffsetX = newContentOffsetAtPinch - pinchCenterX
        
        // 限制偏移量的范围
        newContentOffsetX = max(0, newContentOffsetX)
        let maxContentOffsetX = contentSize.width - bounds.width
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
        let contentWidth = count * styleManager.candleStyle.lineWidth + styleManager.candleStyle.gap * (count - 1)
        contentSize = CGSize(width: max(contentWidth, bounds.width), height: bounds.height - contentInset.bottom)
    }
}

extension HorizontalScrollView {
    
    var visiableRange: Range<Int> {
        let itemWidth = styleManager.candleStyle.lineWidth + styleManager.candleStyle.gap
        let visiableWidth = if contentOffset.x > 0 {
            frame.width
        } else {
            max(frame.width + contentOffset.x, 0)
        }
        let itemCountToBeDrawn = max(Int(ceil(visiableWidth / itemWidth)) + 1, 0)
        let offsetX = max(contentOffset.x, 0)
        let startIndex = max(Int(floor(offsetX / itemWidth)), 0)
        guard startIndex < klineItemCount else { return 0..<0 }
        return startIndex..<min(startIndex + itemCountToBeDrawn, klineItemCount)
    }
    
    func scroll(to scrollPosition: ScrollPosition) {
        // 获取当前的显示位置比例
        let currentOffsetX = contentOffset.x
        let currentContentWidth = contentSize.width
        let offsetRatio = currentContentWidth > 0 ? currentOffsetX / currentContentWidth : 0

        // 更新内容大小
        updateScrollViewContentSize()
        
        var offsetX: CGFloat
        if scrollPosition == .top {
            offsetX = 0
        } else if scrollPosition == .end {
            // 显示最后一屏
            offsetX = contentSize.width - frame.width
        } else {
            // 保持当前显示位置不变
            let updatedContentWidth = contentSize.width
            offsetX = offsetRatio * updatedContentWidth
        }
        
        // 设置新的 contentOffset，确保不超出范围
        contentOffset.x = max(0, min(offsetX, contentSize.width - frame.width))
    }
}
