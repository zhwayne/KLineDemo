//
//  CanvansView.swift
//  KLine
//
//  Created by work on 2025/3/27.
//

import UIKit

final class CanvansView: UIView {
    let canvans = CALayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(canvans)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        canvans.frame = bounds
    }
}
