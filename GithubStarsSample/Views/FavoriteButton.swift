//
//  FavoriteButton.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/24.
//

import UIKit


//MARK: - 찜 버튼
final class FavoriteButton: UIButton {
    
    private let iconTextLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        makeUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func makeUI() {
        snp.makeConstraints { (make) in
            make.size.equalTo(60)
        }
        
        iconTextLabel.do {
            addSubview($0)
            $0.font = .systemFont(ofSize: 25)
            $0.isUserInteractionEnabled = false
            $0.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
        
        setFavoriteIcon(isFavorite: false)
    }
    
    func setFavoriteIcon(isFavorite: Bool) {
        let iconText = isFavorite ? "❤️" : "🖤"
        iconTextLabel.text = iconText
    }
}

