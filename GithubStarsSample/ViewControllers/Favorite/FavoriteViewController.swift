//
//  FavoriteViewController.swift
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

final class FavoriteViewController: UIViewController, ReactorKit.View {
    
    typealias Reactor = FavoriteReactor
 
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
        reactor?.action.onNext(.loadFavoriteUsers)
    }
    
    // MARK: - Binding
    func bind(reactor: Reactor) {
        
        //찜 정보 변경될때 리액터에서 찜리스트 데이터 로드
        GlobalStates.shared.changedFavoriteUserInfo
            .map { _ in Reactor.Action.loadFavoriteUsers }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        searchBar.rx.text.orEmpty
            .debounce(RxTimeInterval.milliseconds(500), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .bind { searchText in
                if searchText.isEmpty {
                    reactor.action.onNext(.loadFavoriteUsers)
                } else {
                    reactor.action.onNext(.searchFavoriteUser(keyword: searchText))
                }
            }
            .disposed(by: disposeBag)
        
        // 키보드 처리
        tableView.rx.contentOffset
            .distinctUntilChanged()
            .bind(onNext: { [weak self] _ in
                self?.view.endEditing(true)
            })
            .disposed(by: disposeBag)
        
        searchBar.rx.searchButtonClicked
            .bind { [weak self] _ in
                self?.view.endEditing(true)
            }
            .disposed(by: disposeBag)
        
        //dataSource
        let productList = reactor.state
            .map { $0.favoriteUsers }
        
        let items: Observable<[FavoriteUserSectionModel]> =  productList
            .map { (items) -> [FavoriteUserSectionModel] in
                
                if items.isEmpty {
                    let emptyCell = FavoriteUserCellModel.empty(index: 0)
                    return [
                        FavoriteUserSectionModel(items: [emptyCell])
                    ]
                } else {
                    let cellItems = items.map { FavoriteUserCellModel.list($0) }
                    return [
                        FavoriteUserSectionModel(items: cellItems)
                    ]
                }
            }
        
        items.observeOn(MainScheduler.instance)
            .bind(to: tableView.rx.items(dataSource: FavoriteViewController.favoriteListDataSource(reactor: reactor)))
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - UI
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
            $0.register(FavoriteEmptyCell.self, forCellReuseIdentifier: "FavoriteEmptyCell")
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
    static func favoriteListDataSource(reactor: FavoriteReactor)
    -> RxTableViewSectionedReloadDataSource<FavoriteUserSectionModel> {
        let dataSource = RxTableViewSectionedReloadDataSource<FavoriteUserSectionModel>(
            configureCell: { (dataSource, tableView, indexPath, item) in
                
                switch item {
                case .empty: ()
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteEmptyCell") as? FavoriteEmptyCell else { return UITableViewCell() }
                    return cell
                case .list(let favoriteUser):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: "GithubUserCell") as? GithubUserCell else { return UITableViewCell() }
                    cell.reactor = GithubUserCellReactor(userName: favoriteUser.userId,
                                                         imagePath: favoriteUser.avartarUrl,
                                                         isFavorite: true)

                    cell.rx.favoriteButtonTap
                        .observeOn(MainScheduler.instance)
                        .bind { _ in
                            reactor.action.onNext(.removeFavoriteUser(user: favoriteUser))
                        }
                        .disposed(by: cell.disposeBag)
                    return cell
                }
            },
            titleForHeaderInSection: { dataSource, sectionIndex in
                
                let items = dataSource.sectionModels.first?.items
                let isEmpty = items?.contains { cellType in
                    switch cellType {
                    case .empty: return true
                    case .list: return false
                    }
                }
                if isEmpty == false {
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
struct FavoriteUserSectionModel: SectionModelType {
    
    var items: [FavoriteUserCellModel]
    
    typealias Item = FavoriteUserCellModel
}

extension FavoriteUserSectionModel {
    init(original: FavoriteUserSectionModel, items: [Item]) {
        self = original
        self.items = items
    }
}

enum FavoriteUserCellModel {
    typealias Identity = Int
    
    var identity : Identity {
        switch self {
        case .empty(let index):
            return index
        case .list(let data):
            return data.id
        }
    }
    
    case list(FavoriteUser)
    case empty(index: Int)
}

