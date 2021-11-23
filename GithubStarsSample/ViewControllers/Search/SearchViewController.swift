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
        
        reactor.state
            .map { $0.error }
            .filterNil()
            .map { $0.localizedDescription }
            .distinctUntilChanged()
            .bind { error in
                print("----------- <\(#file), \(#function), \(#line)> -----------")
                print(error)
            }
            .disposed(by: disposeBag)
        
        searchBar.rx.text.orEmpty
            .filterEmpty()
            .debounce(RxTimeInterval.milliseconds(500), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .bind { searchText in
                print("----------- <\(#file), \(#function), \(#line)> -----------")
                print(searchText)
                reactor.action.onNext(.searchUserName(name: searchText))
            }
            .disposed(by: disposeBag)
        
        let productList = reactor.state
            .map { $0.searchItems }
        
//            .distinctUntilChanged()
//            .bind { items in
//                print("----------- <\(#file), \(#function), \(#line)> -----------")
//                print(items.count)
//                print(items)
//            }
//            .disposed(by: disposeBag)
        
        //dataSource
        let items = productList
            .enumerated()
            .map { [SearchSection(index: $0.0, items: $0.1)] }
        
        items.observeOn(MainScheduler.instance)
            .bind(to: tableView.rx.items(dataSource: SearchViewController.searchListDataSource()))
            .disposed(by: disposeBag)
            
        //셀 선택 처리
        Observable.zip(tableView.rx.itemSelected,
                       tableView.rx.modelSelected(SearchItem.self))
            .bind { [weak self] (indexPath, item) in
                
                print("----------- <\(#file), \(#function), \(#line)> -----------")
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
            
            $0.snp.makeConstraints { make in
                make.top.equalTo(searchBar.snp.bottom)
                make.left.right.bottom.equalToSuperview()
            }
        }
    }
    
    //MARK: - DataSource
    static func searchListDataSource()
    -> RxTableViewSectionedReloadDataSource<SearchSection> {
        let dataSource = RxTableViewSectionedReloadDataSource<SearchSection>(
            configureCell: { (dataSource, tableView, indexPath, item: SearchItem) in
                
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "GithubUserCell") as? GithubUserCell else { return UITableViewCell() }                
                cell.reactor = GithubUserCellReactor(searchItem: item)

                return cell
            },
            titleForHeaderInSection: { dataSource, sectionIndex in
                if dataSource.sectionModels.count > 0 {
                    let section = dataSource[sectionIndex]
                    return "\(section.index) (\(section.items.count))"
                } else {
                    print("----------- <\(#file), \(#function), \(#line)> -----------")
                    return "has no section"
                }
            }
        )
        
        return dataSource
    }
}


final class GithubUserCellReactor: Reactor {
    typealias Action = NoAction
    
    struct State {
        let searchItem: SearchItem
    }
    
    var initialState: State
    
    init(searchItem: SearchItem) {
        initialState = State(searchItem: searchItem)
    }
}

final class GithubUserCell: UITableViewCell, ReactorKit.View {
    var disposeBag: DisposeBag = DisposeBag()
    
    typealias Reactor = GithubUserCellReactor
    
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let favoriteButton = FavoriteButton()
    
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
    }
    
    func bind(reactor: GithubUserCellReactor) {
        let searchItem = reactor.state
            .map { $0.searchItem }
        
        searchItem
            .observeOn(MainScheduler.instance)
            .bind { [weak self] item in
                self?.nameLabel.text = (item.login ?? "") + "/ id: " + String(item.id ?? 0)
            }
            .disposed(by: disposeBag)
        
        favoriteButton.rx.tap
            .withLatestFrom(searchItem)
            .bind(onNext: { searchItem in
                print(searchItem.login, searchItem.id)
            })
            .disposed(by: disposeBag)
    }
    
    private func makeUI() {
        
        profileImageView.do {
            contentView.addSubview($0)
            $0.backgroundColor = .yellow
            
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
            $0.backgroundColor = .gray
            
            $0.snp.makeConstraints { make in
                make.left.equalTo(profileImageView.snp.right).offset(20)
                make.right.equalTo(favoriteButton.snp.left).inset(-20)
                make.centerY.equalToSuperview()
            }
        }
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




//MARK: - 좋아요 버튼
final class FavoriteButton: UIButton {
    
    private let iconImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        makeUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("-----------<찜 deinit>-----------")
    }
    
    private func makeUI() {
        snp.makeConstraints { (make) in
            make.size.equalTo(60)
        }
        
        iconImageView.do {
            addSubview($0)
            $0.isUserInteractionEnabled = false
            $0.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
        
        setFavoriteIcon(isFavorite: false)
    }
    
    private func setFavoriteIcon(isFavorite: Bool) {
        iconImageView.backgroundColor = isFavorite ? .red : .black
    }
}

