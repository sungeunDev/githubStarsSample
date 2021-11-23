//
//  MainViewController.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/20.
//

import Foundation
import UIKit
import Then
import SnapKit
import RxSwift
import RxCocoa

final class MainViewController: UIViewController {
    
    var disposeBag = DisposeBag()
    
    let searchViewController: SearchViewController
    let favoriteViewController: FavoriteViewController
    
    
    // MARK: - Initializing
    init(searchViewController: SearchViewController,
         favoriteViewController: FavoriteViewController) {
        self.searchViewController = searchViewController
        self.favoriteViewController = favoriteViewController
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        makeUI()
    }
    
    private func makeUI() {
        view.backgroundColor = .white
        
        let titleLabel = UILabel().then {
            view.addSubview($0)
            
            $0.text = "GitHub Stars"
            $0.snp.makeConstraints { make in
                make.top.equalTo(view.snp.topMargin).offset(20)
                make.left.right.equalToSuperview().inset(20)
            }
        }
        
        let tabView = FixedWidthListTabView().then {
            view.addSubview($0)
            $0.setTitleList(fullWidth: view.bounds.width, titleList: ["API", "Local"])
            $0.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(20)
                make.left.right.equalToSuperview()
            }
        }
        
        let scrollView = UIScrollView().then {
            view.addSubview($0)
            $0.backgroundColor = .blue
            $0.showsHorizontalScrollIndicator = false
            $0.showsVerticalScrollIndicator = false
            $0.alwaysBounceVertical = false
            
            $0.isPagingEnabled = true
            $0.isDirectionalLockEnabled = true
            $0.contentInsetAdjustmentBehavior = .never
            
            $0.snp.makeConstraints { make in
                make.top.equalTo(tabView.snp.bottom)
                make.left.right.bottom.equalToSuperview()
            }
        }
        
        scrollView.layoutIfNeeded()
        let width = view.bounds.width
        let contentView = UIStackView().then {
            scrollView.addSubview($0)
            $0.backgroundColor = .green
            $0.spacing = 0
            
            $0.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.height.equalTo(scrollView.bounds.height)
                make.width.equalTo(width * 2)
            }
        }
        
        let firstView = UIView().then {
            contentView.addArrangedSubview($0)
            $0.backgroundColor = .brown
            $0.snp.makeConstraints { make in
                make.width.equalTo(width)
            }
        }
        
        let secondView = UIView().then {
            contentView.addArrangedSubview($0)
            $0.backgroundColor = .gray
            $0.snp.makeConstraints { make in
                make.width.equalTo(width)
            }
        }
        
        contentView.layoutIfNeeded()
        
        self.addChild(searchViewController)
        firstView.addSubview(searchViewController.view)
        searchViewController.didMove(toParent: self)

        self.addChild(favoriteViewController)
        secondView.addSubview(favoriteViewController.view)
        favoriteViewController.didMove(toParent: self)
    }
    
    
}

final class FixedWidthListTabView: UIView {
    
    private let stackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 0
    }
    
    var tabButtons: [ListTabButton] = []
    var disposeBag = DisposeBag()
    
    private var fullWidth: CGFloat = 0
    
    let lineView = UIView().then {
        $0.backgroundColor = .clear
    }
    
    //버튼 탭 액션(for rx)
    private let selectedTabIndex: BehaviorRelay<Int> = BehaviorRelay(value: 0)
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        makeUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func makeUI() {
        stackView.do {
            addSubview($0)
            $0.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    func setTitleList(fullWidth: CGFloat, titleList: [String]) {
        self.fullWidth = fullWidth
        let width = fullWidth / CGFloat(titleList.count)
        
        for (idx, title) in titleList.enumerated() {
            ListTabButton(title: title).do { button in
                stackView.addArrangedSubview(button)
                tabButtons.append(button)
                
                button.snp.makeConstraints { make in
                    make.width.equalTo(width)
                }
                
                button.rx.tap.bind(onNext: { [weak self] _ in
                    self?.setSelectTab(idx)
                })
                .disposed(by: disposeBag)
            }
        }
        
        self.lineView.backgroundColor = .black
        self.addSubview(self.lineView)
        
        setSelectTab(0)
    }
    
    
    func setSelectTab(_ index: Int) {
        if index > self.tabButtons.count || tabButtons.isEmpty {
            return
        }
        
        self.selectedTabIndex.accept(index)
        
        DispatchQueue.main.async {
            self.layoutIfNeeded()
            
            // 탭 선택
            for (count, button) in self.tabButtons.enumerated() {
                let isSelected =  count == index
                button.isSelected = isSelected
            }
            
            let selectedTabButton = self.tabButtons[index]
            
            self.lineView.snp.remakeConstraints { (make) in
                make.centerX.width.equalTo(selectedTabButton)
                make.bottom.equalToSuperview()
                make.height.equalTo(3)
            }
            
            // 라인 애니메이션
            UIView.animate(withDuration: 0.2) {
                self.layoutIfNeeded()
            }
        }
    }
}


final class ListTabButton: UIButton {
    
    private let titleTextLabel = UILabel().then {
        $0.textAlignment = .center
    }
    
    override var isSelected: Bool {
          willSet (isSelected) {
              if isSelected == true {
                  self.titleTextLabel.font = .systemFont(ofSize: 15, weight: .bold)
              } else {
                  self.titleTextLabel.font = .systemFont(ofSize: 15, weight: .regular)
              }
          }
      }
    
    private static let tabHeight: CGFloat = 48
    
    init(title: String) {
        super.init(frame: .zero)
        
        makeUI()
        setTitleText(title)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func makeUI() {
        self.snp.makeConstraints { make in
            make.height.equalTo(ListTabButton.tabHeight)
        }
        
        titleTextLabel.do {
            addSubview($0)
            $0.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(8)
                make.centerY.equalToSuperview()
            }
        }
    }
    
    func setTitleText(_ text: String) {
        titleTextLabel.text = text
    }
}

