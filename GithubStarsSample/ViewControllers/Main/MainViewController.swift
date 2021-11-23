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
    
    private let scrollView = UIScrollView()
    private let contentView = UIStackView()
    private let tabView = FixedWidthListTabView()
    
    private var currentScrollViewIndex: Int {
        let currentContentOffsetX = Int(scrollView.contentOffset.x)
        let screenWidth = Int(view.bounds.width)
        let index = currentContentOffsetX / screenWidth
        return index
    }
    
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
        addChildView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let scrollViewHeight = scrollView.bounds.height
        contentView.snp.updateConstraints { make in
            make.height.equalTo(scrollViewHeight)
        }
        
        searchViewController.view.frame.size.height = scrollViewHeight
        favoriteViewController.view.frame.size.height = scrollViewHeight
    }
    
    private func makeUI() {
        view.backgroundColor = .white
        
        let titleLabel = UILabel().then {
            view.addSubview($0)
            
            $0.text = "GitHub Stars"
            $0.font = .systemFont(ofSize: 25, weight: .bold)
            $0.snp.makeConstraints { make in
                make.top.equalTo(view.snp.topMargin)
                make.left.right.equalToSuperview().inset(20)
            }
        }
        
        let width = view.bounds.width
        tabView.do {
            view.addSubview($0)
            $0.setTitleList(fullWidth: view.bounds.width, titleList: ["API", "Local"])
            $0.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(20)
                make.left.right.equalToSuperview()
            }
            
            //상단 탭 클릭시 스크롤뷰 이동 처리
            $0.rx.tabIndexTap
                .distinctUntilChanged()
                .filter { self.currentScrollViewIndex != $0 }
                .observeOn(MainScheduler.instance)
                .bind { [weak self] index in
                    let offsetX = width * CGFloat(index)
                    self?.scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: false)
                }
                .disposed(by: disposeBag)
        }
        
        scrollView.do {
            view.addSubview($0)
            
            $0.showsHorizontalScrollIndicator = false
            $0.showsVerticalScrollIndicator = false
            $0.alwaysBounceVertical = false
            
            $0.isPagingEnabled = true
            $0.isDirectionalLockEnabled = true
            $0.contentInsetAdjustmentBehavior = .never
            
            $0.snp.makeConstraints { make in
                make.top.equalTo(tabView.snp.bottom)
                make.left.right.equalToSuperview()
                make.bottom.equalTo(view.snp.bottomMargin)
            }
        
            //스크롤뷰 스와이프시 상단 탭 UI 변경 처리
            $0.rx.contentOffset.map { $0.x / width }
                .distinctUntilChanged()
                .filter { [weak self] index in
                    if let selectedTabIndex = self?.tabView.selectedTabIndex.value {
                        return selectedTabIndex != Int(index)
                    }
                    return false
                }
                .observeOn(MainScheduler.instance)
                .bind { [weak self] index in
                    self?.tabView.setSelectTab(Int(index))
                }
                .disposed(by: disposeBag)
        }
        
        contentView.do {
            scrollView.addSubview($0)
            $0.spacing = 0
            
            $0.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.height.equalTo(scrollView.bounds.height)
                make.width.equalTo(width * 2)
            }
        }
    }
    
    private func addChildView() {
        let width = view.bounds.width
        
        let firstView = UIView().then {
            contentView.addArrangedSubview($0)
            $0.snp.makeConstraints { make in
                make.width.equalTo(width)
            }
        }
        
        let secondView = UIView().then {
            contentView.addArrangedSubview($0)
            $0.snp.makeConstraints { make in
                make.width.equalTo(width)
            }
        }
        
        view.layoutIfNeeded()
        
        self.addChild(searchViewController)
        firstView.addSubview(searchViewController.view)
        searchViewController.didMove(toParent: self)

        self.addChild(favoriteViewController)
        secondView.addSubview(favoriteViewController.view)
        favoriteViewController.didMove(toParent: self)
    }
}
