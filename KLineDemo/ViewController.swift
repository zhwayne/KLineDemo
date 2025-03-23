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
    
    private var client: WebSocketClient!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.addSubview(chartView)

        chartView.snp.makeConstraints { make in
            make.left.right.equalTo(view.safeAreaLayoutGuide)
            make.centerY.equalToSuperview()
        }
//        
//        let config = WebSocketClient.Configuration(url: URL(string: "wss://npush.bibox360.com")!)
//        client = WebSocketClient(config: config)
//        
//        Task {
//            for await message in client.messages {
//                print(message)
//            }
//        }
//        Task {
//            do {
//                try await client.connect()
//            } catch {
//                print(error)
//            }
//        }
//        
        
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
        
        chartView.reloadData(items: items.reversed(), scrollPosition: .end)
    }
}

import SwiftUI

@available(iOS 17.0, *)
#Preview {
    ViewController()
}
