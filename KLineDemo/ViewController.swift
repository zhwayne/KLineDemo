//
//  ViewController.swift
//  KLineDemo
//
//  Created by iya on 2024/10/31.
//

import UIKit
import SwiftyJSON

class ViewController: UIViewController {
    
    private let chartView = KLineView()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.addSubview(chartView)
        
//        chartView.translatesAutoresizingMaskIntoConstraints = false
//        chartView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
//        chartView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
//        chartView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
//        chartView.heightAnchor.constraint(equalToConstant: 250).isActive = true
//
        chartView.snp.makeConstraints { make in
            make.left.right.equalTo(view.safeAreaLayoutGuide)
            make.centerY.equalToSuperview()
            make.width.equalTo(chartView.snp.height).multipliedBy(16.0 / 9)
        }
        
        // 解析 plist
        let filePath = Bundle.main.path(forResource: "kline", ofType: "plist")!
        let data = NSDictionary(contentsOfFile: filePath)!
        let json = JSON(data)
        let datas = json["data"].arrayValue
        
        let items = datas.map { json -> KLineItem in
            KLineItem(
                opening: json.arrayValue[0].doubleValue,
                closing: json.arrayValue[1].doubleValue,
                highest: json.arrayValue[2].doubleValue,
                lowest: json.arrayValue[3].doubleValue,
                volume: json.arrayValue[4].intValue,
                value: 0,
                timestamp: json.arrayValue[5].intValue
            )
        }
        
        StyleConfiguration.shared.indicatorStyle[.ma(period: 10)] = .init(color: .orange, lineWidth: 1)
        StyleConfiguration.shared.indicatorStyle[.ma(period: 30)] = .init(color: .red, lineWidth: 1)
        StyleConfiguration.shared.indicatorStyle[.ma(period: 60)] = .init(color: .purple, lineWidth: 1)
        
        chartView.reloadData(items: items.reversed())
    }
}

