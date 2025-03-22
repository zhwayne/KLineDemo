//
//  IndicatorTypeView.swift
//  KLineDemo
//
//  Created by work on 2025/3/22.
//

import UIKit
import Combine

final class IndicatorTypeView: UIView, UICollectionViewDelegate {
    
    var drawMainIndicatorPublisher: AnyPublisher<IndicatorType, Never> {
        drawPublisher
            .filter { $0.0 == .mainChart }
            .map { $0.1 }
            .eraseToAnyPublisher()
    }
    
    var eraseMainIndicatorPublisher: AnyPublisher<IndicatorType, Never> {
        erasePublisher
            .filter { $0.0 == .mainChart }
            .map { $0.1 }
            .eraseToAnyPublisher()
    }
    
    let mainIndicators: [IndicatorType]
    private let drawPublisher = PassthroughSubject<(KLineChartSection, IndicatorType), Never>()
    private let erasePublisher = PassthroughSubject<(KLineChartSection, IndicatorType), Never>()
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, IndicatorType>!
    
    required init(mainIndicators: [IndicatorType]) {
        self.mainIndicators = mainIndicators
        super.init(frame: .zero)
        let layout = makeLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.allowsMultipleSelection = true
        collectionView.register(IndicatorCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.delegate = self
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        setupIndicatorListDataSource()
        
        addSubview(collectionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeLayout() -> UICollectionViewLayout {
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
        dataSource = .init(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! IndicatorCell
            cell.label.text = itemIdentifier.rawValue
            return cell
        })
        
        // 配置主图指标
        var snapshot = NSDiffableDataSourceSnapshot<Int, IndicatorType>()
        snapshot.appendSections([0])
        snapshot.appendItems(mainIndicators)
        dataSource.apply(snapshot)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let snapshot = dataSource.snapshot()
        let type = snapshot.itemIdentifiers[indexPath.item]
        drawPublisher.send((.mainChart, type))
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let snapshot = dataSource.snapshot()
        let type = snapshot.itemIdentifiers[indexPath.item]
        erasePublisher.send((.mainChart, type))
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
            label.textColor = isSelected ? .label : .secondaryLabel
        }
    }
}
