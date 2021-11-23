//
//  SearchViewController.swift
//  GithubStarsSample
//
//  Created by Romie on 2021/11/20.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import ReactorKit
import RxOptional
import RxDataSources
import Toaster

final class SearchViewController: UIViewController, ReactorKit.View {
    
    typealias Reactor = SearchReactor
    
    var disposeBag = DisposeBag()
    
    //UI
    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .grouped)
 
    // MARK: - Initializing
    init(reactor: Reactor) {
        defer { self.reactor = reactor }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        makeUI()
    }
    
    // MARK: - Binding
    func bind(reactor: Reactor) {
        
        //페이징
        tableView.rx.contentOffset
            .distinctUntilChanged()
            .do(onNext: { [weak self] _ in
                self?.view.endEditing(true)
            })
            .filter { _ in return
                self.tableView.isNearBottomEdge()
                && reactor.currentState.isLoadingNextPage == false
                && reactor.currentState.nextPage != nil
            }
            .map { _ in Reactor.Action.loadMore }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        //검색
        searchBar.rx.text.orEmpty
            .filterEmpty()
            .debounce(RxTimeInterval.milliseconds(500), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .bind { searchText in
                reactor.action.onNext(.searchUserName(name: searchText))
            }
            .disposed(by: disposeBag)
        
        //키보드 검색버튼 클릭시 키보드 다운
        searchBar.rx.searchButtonClicked
            .bind { [weak self] _ in
                self?.view.endEditing(true)
            }
            .disposed(by: disposeBag)
        
        //dataSource
        let productList = reactor.state
            .map { $0.searchItems }
        
        let items = productList
            .enumerated()
            .map { [SearchSection(index: $0.0, items: $0.1)] }
        
        items.observeOn(MainScheduler.instance)
            .bind(to: tableView.rx.items(dataSource: SearchViewController.searchListDataSource(reactor: reactor)))
            .disposed(by: disposeBag)
        
        //찜처리
        reactor.state
            .map { $0.favoriteStatus }
            .distinctUntilChanged()
            .filterNil()
            .bind { status in
                let toastText = status == .added ? "찜이 완료됐어요." : "찜이 해제됐어요."
                Toast(text: toastText).show()
            }
            .disposed(by: disposeBag)
        
        //에러처리
        reactor.state
            .map { $0.error }
            .filterNil()
            .map { $0.localizedDescription }
            .distinctUntilChanged()
            .bind { error in
                Toast(text: "에러가 발생했어요. 네트워크 확인 후 다시 시도해 주세요.").show()
                print("----------- <\(#file), \(#function), \(#line)> -----------")
                print(error)
            }
            .disposed(by: disposeBag)
            
    }
    
    private func makeUI() {
        searchBar.do {
            view.addSubview($0)
            $0.snp.makeConstraints { make in
                make.top.left.right.equalToSuperview()
            }
        }
        
        tableView.do {
            view.addSubview($0)
            $0.register(GithubUserCell.self, forCellReuseIdentifier: "GithubUserCell")
            $0.rowHeight = 100
            $0.contentInsetAdjustmentBehavior = .never
            $0.sectionFooterHeight = 0
            
            $0.snp.makeConstraints { make in
                make.top.equalTo(searchBar.snp.bottom)
                make.left.right.bottom.equalToSuperview()
            }
        }
    }
    
    //MARK: - DataSource
    static func searchListDataSource(reactor: SearchReactor)
    -> RxTableViewSectionedReloadDataSource<SearchSection> {
        let dataSource = RxTableViewSectionedReloadDataSource<SearchSection>(
            configureCell: { (dataSource, tableView, indexPath, item: SearchItem) in
                
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "GithubUserCell") as? GithubUserCell else { return UITableViewCell() }
                
                let isFavorite = reactor.isFavoriteItem(item: item)
                cell.reactor = GithubUserCellReactor(userName: item.login, imagePath: item.avartarUrl, isFavorite: isFavorite)

                cell.rx.favoriteButtonTap
                    .bind { _ in
                        reactor.action.onNext(.clickFavoriteButton(item: item))
                    }
                    .disposed(by: cell.disposeBag)
                
                //찜 정보 변경될때 셀의 데이터와 비교해서 UI 갱신 처리
                reactor.favoriteService.changedFavoriteUserInfo
                    .filter { item.id == $0.userId }
                    .bind { info in
                        cell.reactor?.action.onNext(.changeFavoriteStatus(info.status))
                    }
                    .disposed(by: cell.disposeBag)
                
                return cell
            },
            titleForHeaderInSection: { dataSource, sectionIndex in
                if dataSource.sectionModels.count > 0 {
                    let section = dataSource[sectionIndex]
                    return "itemCount: \(section.items.count)"
                } else {
                    return "EMPTY"
                }
            }
        )
        
        return dataSource
    }
}


//MARK: - Datasource
struct SearchSection {
    var index: Int
    var items: [SearchItem]
    init(index: Int, items: [SearchItem]) {
        self.index = index
        self.items = items
    }
}

extension SearchSection: SectionModelType {
    typealias Item = SearchItem
    init(original: SearchSection, items: [SearchItem]) {
        self = original
        self.items = items
    }
}
