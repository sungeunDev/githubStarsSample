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
    }
    
    // MARK: - Binding
    func bind(reactor: Reactor) {
        
        searchBar.rx.text.orEmpty
            .filterEmpty()
            .debounce(RxTimeInterval.milliseconds(500), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .bind { searchText in
                print("----------- <\(#file), \(#function), \(#line)> -----------")
                print(searchText)
                reactor.action.onNext(.searchFavoriteUser(keyword: searchText))
            }
            .disposed(by: disposeBag)
        
        searchBar.rx.cancelButtonClicked
            .bind { _ in
                reactor.action.onNext(.resetSearchResult)
            }
            .disposed(by: disposeBag)
        
        let productList = reactor.state
            .map { $0.favoriteUsers }
        
        //dataSource
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
            .bind(to: tableView.rx.items(dataSource: FavoriteViewController.searchListDataSource()))
            .disposed(by: disposeBag)
            
        //셀 선택 처리
        Observable.zip(tableView.rx.itemSelected,
                       tableView.rx.modelSelected(SearchItem.self))
            .bind { [weak self] (indexPath, item) in
                
                print("----------- <\(#file), \(#function), \(#line)> -----------")
            }
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
            $0.rowHeight = 100
            $0.contentInsetAdjustmentBehavior = .never
            
            $0.snp.makeConstraints { make in
                make.top.equalTo(searchBar.snp.bottom)
                make.left.right.bottom.equalToSuperview()
            }
        }
    }
    
    //MARK: - DataSource
    static func searchListDataSource()
    -> RxTableViewSectionedReloadDataSource<FavoriteUserSectionModel> {
        let dataSource = RxTableViewSectionedReloadDataSource<FavoriteUserSectionModel>(
            configureCell: { (dataSource, tableView, indexPath, item) in
                
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "GithubUserCell") as? GithubUserCell else { return UITableViewCell() }
                
//                switch item {
//                case .header, .empty:
//                case .list(let favoriteUser):
//
//                }
                
//                cell.reactor = GithubUserCellReactor(searchItem: item)

                return cell
            },
            titleForHeaderInSection: { dataSource, sectionIndex in
                
                
                
                if dataSource.sectionModels.count > 0 {
                    let section = dataSource[sectionIndex]
                    return "test"
//                    return "\(section.index) (\(section.items.count))"
                } else {
                    print("----------- <\(#file), \(#function), \(#line)> -----------")
                    return "has no section"
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
        case .header(let index), .empty(let index):
            return index
        case .list(let data):
            return data.id
        }
    }
    
    case header(index: Int)
    case list(FavoriteUser)
    case empty(index: Int)
}

