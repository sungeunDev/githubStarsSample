//
//  FavoriteEmptyCell.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/24.
//

import UIKit

final class FavoriteEmptyCell: UITableViewCell {
    private let titleLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        makeUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeUI() {
        titleLabel.do {
            contentView.addSubview($0)
            $0.text = "찜 목록이 없습니다."
            $0.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
        }
    }
}
