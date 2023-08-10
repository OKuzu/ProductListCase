//
//  MainViewController.swift
//  TwoViewCaseMVVM2.0
//
//  Created by Oğuz Kuzu on 8.08.2023.
//

import UIKit

class MainViewController: UIViewController, UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    var tableView = UITableView()
    var collectionView: UICollectionView!
    let viewModel = ProductListViewModel()
    let nextButton = UIButton()
    let scrollView = UIScrollView()
    let toggleButton = UIButton()
    let spacing: CGFloat = 10.0
    var isTwoColumns = false
    var productID: Int = 0
    var favoritedProductIDs: Set<Int> = []
    var isLoadingContent = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        scrollView.delegate = self
        self.tableView.register(MainCustomListCell.self, forCellReuseIdentifier: "cell")
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: view.frame.width/2 - 20, height: 200)
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView.register(MainCustomGridCell.self, forCellWithReuseIdentifier: "grid-cell")
        tableView.delegate = self
        tableView.dataSource = self
        collectionView.delegate = self
        collectionView.dataSource = self
        setUpView()
        loadContent()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.products.count
    }

    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: MainCustomGridCell = collectionView.dequeueReusableCell(withReuseIdentifier: "grid-cell", for: indexPath) as! MainCustomGridCell

        let product = viewModel.products[indexPath.row]

        let imageUrl = URL(string: product.ImageUrl ?? "")!

        cell.nameLabel.text = product.DisplayName

        let isLiked = UserDefaultsManager.shared.isProductLiked(productId: product.ProductId ?? 0, userId: "user123")
        if isLiked {
            favoritedProductIDs.insert(product.ProductId ?? 0)
        } else {
            favoritedProductIDs.remove(product.ProductId ?? 0)
        }

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGestureRecognizer.cancelsTouchesInView = false
        cell.addGestureRecognizer(tapGestureRecognizer)
        cell.tag = indexPath.row

        cell.starButton.setImage(UIImage(systemName: favoritedProductIDs.contains(product.ProductId ?? 0) ? "star.fill" : "star"), for: .normal)
        cell.starButton.isUserInteractionEnabled = true
        cell.starButton.tag = indexPath.row
        cell.starButton.addTarget(self, action: #selector(starButtonTapped(_:)), for: .touchUpInside)

        // Fetch and display the image
        URLSession.shared.dataTask(with: imageUrl) { data, _, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    cell.image.image = image
                }
            }
        }.resume()

        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: MainCustomListCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MainCustomListCell
        
        let product = viewModel.products[indexPath.row]
        
        let imageUrl = URL(string: product.ImageUrl ?? "")!
        
        cell.nameLabel.text = product.DisplayName
        
        let isLiked = UserDefaultsManager.shared.isProductLiked(productId: product.ProductId ?? 0, userId: "user123")
        if isLiked {
            favoritedProductIDs.insert(product.ProductId ?? 0)
        } else {
            favoritedProductIDs.remove(product.ProductId ?? 0)
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGestureRecognizer.cancelsTouchesInView = false
        cell.addGestureRecognizer(tapGestureRecognizer)
        cell.tag = indexPath.row
        
        cell.starButton.setImage(UIImage(systemName: favoritedProductIDs.contains(product.ProductId ?? 0) ? "star.fill" : "star"), for: .normal)
        cell.starButton.isUserInteractionEnabled = true
        cell.starButton.tag = indexPath.row
        cell.starButton.addTarget(self, action: #selector(starButtonTapped(_:)), for: .touchUpInside)
        
        // Fetch and display the image
        URLSession.shared.dataTask(with: imageUrl) { data, _, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    cell.image.image = image
                }
            }
        }.resume()

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        300
    }
    
    func loadContent(completion: (() -> Void)? = nil) {
        viewModel.fetchProducts() { err in
            if err == nil {
                DispatchQueue.main.async {
                    if self.isTwoColumns {
                        self.collectionView.reloadData()
                    } else {
                        self.tableView.reloadData()
                    }
                }
                completion?()
            }
        }
    }
    
    func updateLayout() {
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        setUpView()
        loadContent()
    }
    
    @objc func toggleButtonTapped() {
        isTwoColumns.toggle()
        if isTwoColumns {
            toggleButton.setImage(UIImage(systemName: "list.bullet"), for: .normal)
        } else {
            toggleButton.setImage(UIImage(systemName: "square.grid.2x2"), for: .normal)
        }
        updateLayout()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pos = scrollView.contentOffset.y
        if !isLoadingContent {
            if self.isTwoColumns {
                if pos > collectionView.contentSize.height - 50 - scrollView.frame.size.height {
                    isLoadingContent = true
                    self.loadContent() {
                        self.isLoadingContent = false
                        DispatchQueue.main.async {
                            self.collectionView.reloadData()
                        }
                    }
                }
            } else {
                if pos > tableView.contentSize.height - 50 - scrollView.frame.size.height {
                    isLoadingContent = true
                    self.loadContent() {
                        self.isLoadingContent = false
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    func setUpView() {
        let topBar = UIView()
        topBar.backgroundColor = .white
        
        let titleLabel = UILabel()
        titleLabel.text = "Contents"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18.0)
        
        toggleButton.setTitleColor( .blue, for: .normal)
        toggleButton.setImage(isTwoColumns ? UIImage(systemName: "list.bullet") : UIImage(systemName: "square.grid.2x2") , for: .normal)
        toggleButton.addTarget(self, action: #selector(toggleButtonTapped), for: .touchUpInside)
        
        topBar.addSubview(titleLabel)
        topBar.addSubview(toggleButton)
        
        view.addSubview(topBar)
        
        topBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -20),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 44.0)
        ])
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: topBar.centerXAnchor)
        ])
        
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toggleButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            toggleButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -16.0)
        ])
        
        if self.isTwoColumns {
            view.addSubview(collectionView)
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.topAnchor.constraint(equalTo: topBar.bottomAnchor).isActive = true
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10).isActive = true
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10).isActive = true
        } else {
            view.addSubview(tableView)
            tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
            tableView.translatesAutoresizingMaskIntoConstraints = false
            tableView.topAnchor.constraint(equalTo: topBar.bottomAnchor).isActive = true
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10).isActive = true
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10).isActive = true
        }
    }
    
    @objc func starButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        let product = viewModel.products[index]
        
        if let prodID = product.ProductId {
            let isLiked = UserDefaultsManager.shared.isProductLiked(productId: prodID, userId: "user123")
            
            if isLiked {
                favoritedProductIDs.remove(prodID)
            } else {
                favoritedProductIDs.insert(prodID)
            }
            
            UserDefaultsManager.shared.toggleLike(forProductId: prodID, userId: "user123")
            
            sender.setImage(UIImage(systemName: favoritedProductIDs.contains(prodID) ? "star.fill" : "star"), for: .normal)
        }
    }
}

extension MainViewController {
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        if let view = sender.view {
            let index = view.tag
            let product = viewModel.products[index]
            let detailsViewController = ProductDetailsViewController(ProductId: product.ProductId)
            navigationController?.pushViewController(detailsViewController, animated: true)
        }
    }
}

