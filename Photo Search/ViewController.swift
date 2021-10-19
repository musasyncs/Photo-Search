//
//  ViewController.swift
//  Photo Search
//
//  Created by Ewen on 2021/7/4.
//

import UIKit

class ViewController: UIViewController {
    var apiResults = [APIResult]()
    private let searchController = UISearchController(searchResultsController: nil)
    
    private let collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.showsVerticalScrollIndicator   = false
        collectionView.backgroundColor                = .clear
        return collectionView
    }()
    
    static func createLayout() -> UICollectionViewLayout {
        let itemSpace: CGFloat = 1
        let columnCount: CGFloat = 3
        let flowLayout = UICollectionViewFlowLayout()
        
        let width = floor((UIScreen.main.bounds.width - (columnCount-1) * itemSpace) / columnCount)
        flowLayout.itemSize = CGSize(width: width, height: width)
        flowLayout.estimatedItemSize = .zero
        flowLayout.minimumInteritemSpacing  = itemSpace
        flowLayout.minimumLineSpacing       = itemSpace
        
        flowLayout.scrollDirection          = .vertical
        return flowLayout
    }
    
    private let spinner = UIActivityIndicatorView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Photo Search"
        
        view.addSubview(collectionView)
        collectionView.dataSource = self
        collectionView.fillSuperView()
        
        view.addSubview(spinner)
        spinner.center = view.center
        
        createSearchBar()
        
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture))
        collectionView.addGestureRecognizer(gesture)
    }
    
    private func createSearchBar() {
        navigationItem.searchController = searchController
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "搜尋圖片"
        searchController.searchBar.searchTextField.autocapitalizationType = .none
    }
    
    @objc func handleLongPressGesture(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            guard let targetIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else { return }
            collectionView.beginInteractiveMovementForItem(at: targetIndexPath)
        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: collectionView))
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }
    
    
}

//MARK: - UISearchBarDelegate
extension ViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text?.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: ""), !query.isEmpty else { return }
        ///
        spinner.startAnimating()
        ///
        
        NetworkHelper.shared.fetchPhotos(query: query) { [weak self] result in
            switch result{
            case .success(let apiResults):
                self?.apiResults = apiResults
                DispatchQueue.main.async {
                    self?.collectionView.reloadData()
                    ///
                    self?.spinner.stopAnimating()
                    self?.spinner.hidesWhenStopped = true
                    ///
                }
            case .failure(let networkError):
                switch networkError {
                case .invalidUrl:
                    print(networkError)
                case .requestFailed(let error):
                    print(networkError, error)
                case .invalidData:
                    print(networkError)
                }
            }
        }
    }
    
}

//MARK: - UICollectionViewDataSource
extension ViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return apiResults.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        let result = apiResults[indexPath.row]
        guard let url = URL(string: result.urls.regular) else { return UICollectionViewCell() }
        
        NetworkHelper.shared.fetchImage(url: url) { result in
            switch result{
            case .success(let image):
                DispatchQueue.main.async {
                    var bgConfig = UIBackgroundConfiguration.listPlainCell()
                    bgConfig.image = image //下載的圖片
                    bgConfig.imageContentMode = .scaleAspectFill
                    cell.backgroundConfiguration = bgConfig
                }
            case .failure(let networkError):
                switch networkError {
                case .invalidUrl:
                    print(networkError) //不會遇到這個case，因為前面已經判斷過了
                case .requestFailed(let error):
                    print(networkError, error)
                case .invalidData:
                    print(networkError)
                }
            }
        }
        
        return cell
    }
    
    // Drag and drop
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let item = apiResults.remove(at: sourceIndexPath.row)
        apiResults.insert(item, at: destinationIndexPath.row)
    }
}

