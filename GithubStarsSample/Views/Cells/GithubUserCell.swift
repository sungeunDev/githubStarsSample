//
//  GithubUserCell.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/24.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit

extension Reactive where Base: GithubUserCell {
    
    var favoriteButtonTap: ControlEvent<Void> {
        return base.favoriteButton.rx.tap
    }
}

final class GithubUserCell: UITableViewCell, ReactorKit.View {
    var disposeBag: DisposeBag = DisposeBag()
    
    typealias Reactor = GithubUserCellReactor
    
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    let favoriteButton = FavoriteButton()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        makeUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
        nameLabel.text = nil
        profileImageView.image = nil
        favoriteButton.setFavoriteIcon(isFavorite: false)
    }
    
    func bind(reactor: GithubUserCellReactor) {
        
        reactor.state
            .map { $0.userName }
            .observeOn(MainScheduler.instance)
            .bind { [weak self] userName in
                self?.nameLabel.text = userName
            }
            .disposed(by: disposeBag)
        
        let profileImageView = self.profileImageView
        reactor.state
            .map { $0.imagePath }
            .filterNil()
            .observeOn(MainScheduler.instance)
            .bind { imagePath in
                
                profileImageView.layoutIfNeeded()
                let corenerRadius: CGFloat = profileImageView.bounds.height / 2
                profileImageView.setImage(path: imagePath, cornerRadius: corenerRadius) { error in
                    if let error = error {
                        print("----------- <\(#file), \(#function), \(#line)> -----------")
                        print(error.localizedDescription)
                        profileImageView.image = nil
                    }
                }
            }
            .disposed(by: disposeBag)
        
        reactor.state
            .map { $0.isFavorite }
            .observeOn(MainScheduler.instance)
            .bind { [weak self] isFavorite in
                self?.favoriteButton.setFavoriteIcon(isFavorite: isFavorite)
            }
            .disposed(by: disposeBag)
    }
    
    private func makeUI() {
        
        profileImageView.do {
            contentView.addSubview($0)
            
            $0.snp.makeConstraints { make in
                make.top.left.equalToSuperview().offset(20)
                make.size.equalTo(60)
            }
        }
        
        favoriteButton.do {
            contentView.addSubview($0)
            
            $0.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(20)
                make.centerY.equalToSuperview()
            }
        }
        
        nameLabel.do {
            contentView.addSubview($0)
            
            $0.snp.makeConstraints { make in
                make.left.equalTo(profileImageView.snp.right).offset(20)
                make.right.equalTo(favoriteButton.snp.left).inset(-20)
                make.centerY.equalToSuperview()
            }
        }
    }
}
