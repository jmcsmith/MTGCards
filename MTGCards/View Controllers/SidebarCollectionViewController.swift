//
//  SidebarCollectionViewController.swift
//  MTGCards
//
//  Created by Joseph Smith on 10/19/20.
//  Copyright © 2020 Robotic Snail Software. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices
import UniformTypeIdentifiers
import SwiftUI
#if !targetEnvironment(macCatalyst)
@objc protocol NSToolbarDelegate {
}
#endif


class SidebarCollectionViewController: UICollectionViewController, UIDocumentPickerDelegate, UICollectionViewDropDelegate, NSToolbarDelegate {
    struct Item: Hashable {
        let title: String?
        
        private let identifier = UUID()
    }
    struct HeaderItem: Hashable {
        let title: String?
    }
    var sectionItems = [HeaderItem(title: "Tools"), HeaderItem(title: "Collections"), HeaderItem(title: "Decks")]
    let sections = ["Tools","Collections","Decks"]
    var collections = ["Collections"]
    var cdCollections: [Collection] = []
    var decks = ["Decks"]
    var cdDecks: [Deck] = []
    var search = ["Tools", "Search"]
    
    var addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButton))
    
    var dataSource: UICollectionViewDiffableDataSource<HeaderItem, Item>! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dropDelegate = self
        if !(self.splitViewController?.traitCollection.horizontalSizeClass == .regular) {
            self.title = "Collections"
        }
        
#if !targetEnvironment(macCatalyst)
        self.navigationItem.setRightBarButton(addBarButton, animated: true)
        let settingsButton = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(self.settings))
        self.navigationItem.setLeftBarButton(settingsButton, animated: true)
#endif
        
        
        if let nav = self.navigationController {
#if !targetEnvironment(macCatalyst)
            nav.setToolbarHidden(true, animated: false)
#else
            nav.navigationBar.isHidden = true
            nav.setToolbarHidden(false, animated: false)
            self.toolbarItems = [addBarButton]
#endif
        }
        
        createDataSource()
        
    }
    
    
    private func reloadDecksFromCoreData(){
        let request = NSFetchRequest<Deck>(entityName: "Deck")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        do {
            let results = try CoreDataStack.handler.privateContext.fetch(request)
            cdDecks = results
        } catch {
            print(error)
        }
    }
    private func reloadCollectionsFromCoreData(){
        let request = NSFetchRequest<Collection>(entityName: "Collection")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        do {
            let results = try CoreDataStack.handler.privateContext.fetch(request)
            cdCollections = results
        } catch {
            print(error)
        }
    }
    //    @objc func addButton(sender: Any) {
    //        let menuAlert = UIAlertController(title: "Create Deck(s)", message: nil, preferredStyle: .actionSheet)
    //        menuAlert.addAction(UIAlertAction(title: "New Empty Deck", style: .default, handler: {action in  self.addBlankDeck()}))
    //        let pasteboard = UIPasteboard.general
    //        if pasteboard.string != nil {
    //            menuAlert.addAction(UIAlertAction(title: "New Deck from Clipboard", style: .default, handler: {action in  self.addDeckFromClipboard()}))
    //        }
    //        menuAlert.addAction(UIAlertAction(title: "New Deck(s) from File(s)", style: .default, handler: {action in  self.addDecksFromFiles()}))
    //        menuAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    //        if let sender = sender as? UIBarButtonItem {
    //            menuAlert.popoverPresentationController?.barButtonItem = sender
    //        }
    ////        else {
    ////            menuAlert.popoverPresentationController?.barButtonItem = addBarButton
    ////        }
    //        #if targetEnvironment(macCatalyst)
    //        if let sender = sender as? UIButton {
    //            menuAlert.popoverPresentationController?.sourceView = sender
    //        }
    //        #endif
    //        self.present(menuAlert, animated: true)
    //    }
    @objc public func addButton() {
        let menuAlert = UIAlertController(title: "Create Deck(s)", message: nil, preferredStyle: .actionSheet)
        menuAlert.addAction(UIAlertAction(title: "New Empty Deck", style: .default, handler: {action in  self.addBlankDeck()}))
        let pasteboard = UIPasteboard.general
        if pasteboard.string != nil {
            menuAlert.addAction(UIAlertAction(title: "New Deck from Clipboard", style: .default, handler: {action in  self.addDeckFromClipboard()}))
        }
        menuAlert.addAction(UIAlertAction(title: "New Deck(s) from File(s)", style: .default, handler: {action in  self.addDecksFromFiles()}))
        menuAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        menuAlert.popoverPresentationController?.barButtonItem = addBarButton
#if targetEnvironment(macCatalyst)
        menuAlert.popoverPresentationController?.sourceView = collectionView.cellForItem(at: IndexPath(row: 0, section: 2))?.contentView
#endif
        self.present(menuAlert, animated: true)
    }
    func addBlankDeck(){
        let alert = UIAlertController(title: "Deck Name?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "Deck Name"
            textField.autocapitalizationType = .words
        })
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { action in
            if let name = alert.textFields?.first?.text {
                guard  let entity = NSEntityDescription.entity(forEntityName: "Deck", in:  CoreDataStack.handler.managedObjectContext) else {
                    fatalError("Failed to decode Card")
                }
                let newDeck = Deck.init(entity: entity, insertInto: CoreDataStack.handler.managedObjectContext)
                newDeck.name = name
                newDeck.uuid = UUID()
                try? CoreDataStack.handler.managedObjectContext.save()
                self.reloadDecksFromCoreData()
                DispatchQueue.main.async {
                    self.reloadCollectionsFromCoreData()
                    self.createDataSource()
                }
            }
        }))
        self.present(alert, animated: true)
    }
    func addDeckFromClipboard() {
        let alert = UIAlertController(title: "Deck Name?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "Deck Name"
            textField.autocapitalizationType = .words
        })
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { action in
            if let name = alert.textFields?.first?.text {
                guard  let entity = NSEntityDescription.entity(forEntityName: "Deck", in:  CoreDataStack.handler.privateContext) else {
                    fatalError("Failed to decode Card")
                }
                let newDeck = Deck.init(entity: entity, insertInto: CoreDataStack.handler.privateContext)
                newDeck.name = name
                newDeck.uuid = UUID()
                //get clipboard
                let pasteboard = UIPasteboard.general
                if let string = pasteboard.string {
                    let lines = string.components(separatedBy: CharacterSet.newlines)
                    var previousline = ""
                    var isSideboard = false
                    for line in lines {
                        if line != "" {
                            var parts = line.split(separator: " ")
                            let quantity = parts[0]
                            parts.remove(at: 0)
                            var name = ""
                            var setCode = ""
                            for p in parts {
                                if p.contains("(") {
                                    setCode = String(p)
                                    break
                                } else {
                                    name += " "+p
                                }
                            }
                            while let range = setCode.range(of: "(") {
                                setCode.removeSubrange(range.lowerBound..<range.upperBound)
                            }
                            while let range = setCode.range(of: ")") {
                                setCode.removeSubrange(range.lowerBound..<range.upperBound)
                            }
                            self.addCard(name: name, setCode: setCode, quantity: Int(quantity) ?? 1, isSideboard: isSideboard, newDeck: newDeck)
                        } else if previousline == "" {
                            isSideboard = true
                        }
                        previousline = line
                    }
                }
                do {
                    try CoreDataStack.handler.privateContext.save()
                } catch {
                    print(error)
                }
                self.reloadDecksFromCoreData()
                DispatchQueue.main.async {
                    self.createDataSource()
                }
            }
        }))
        self.present(alert, animated: true)
    }
    func addDecksFromFiles(){
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.text])
        documentPicker.allowsMultipleSelection = true
        documentPicker.delegate = self
        self.present(documentPicker, animated: true)
    }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            importFile(url: url)
        }
    }
    private func importFile(url: URL){
        do {
            guard  let entity = NSEntityDescription.entity(forEntityName: "Deck", in:  CoreDataStack.handler.privateContext) else {
                fatalError("Failed to decode Card")
            }
            let newDeck = Deck.init(entity: entity, insertInto: CoreDataStack.handler.privateContext)
            let name = url.absoluteURL.deletingPathExtension().lastPathComponent
            newDeck.name = name
            newDeck.uuid = UUID()
            _ = url.startAccessingSecurityScopedResource()
            let contents = try String.init(contentsOf: url)
            
            let lines = contents.components(separatedBy: CharacterSet.newlines)
            var previousline = ""
            var isSideboard = false
            for line in lines {
                if line != "" {
                    var parts = line.split(separator: " ")
                    let quantity = parts[0]
                    parts.remove(at: 0)
                    var name = ""
                    var setCode = ""
                    for p in parts {
                        if p.contains("(") {
                            setCode = String(p)
                            break
                        } else {
                            name += " "+p
                        }
                    }
                    while let range = setCode.range(of: "(") {
                        setCode.removeSubrange(range.lowerBound..<range.upperBound)
                    }
                    while let range = setCode.range(of: ")") {
                        setCode.removeSubrange(range.lowerBound..<range.upperBound)
                    }
                    addCard(name: name, setCode: setCode, quantity: Int(quantity) ?? 1, isSideboard: isSideboard, newDeck: newDeck)
                } else if previousline == "" {
                    isSideboard = true
                }
                previousline = line
            }
            do {
                try CoreDataStack.handler.privateContext.save()
            } catch {
                print(error)
            }
            self.reloadDecksFromCoreData()
            self.reloadCollectionsFromCoreData()
            DispatchQueue.main.async {
                self.createDataSource()
            }
        } catch {
            print(error)
        }
        
    }
    private func addCard(name: String, setCode: String, quantity: Int, isSideboard: Bool, newDeck: Deck){
        let card = DataManager.getCard(name: name, setCode: setCode)
        //let card = getCard(name: name, setCode: setCode)
        if let card = card {
            guard  let entity = NSEntityDescription.entity(forEntityName: "DeckCard", in:  CoreDataStack.handler.privateContext) else {
                fatalError("Failed to decode Card")
            }
            let deckCard = DeckCard.init(entity: entity, insertInto: CoreDataStack.handler.privateContext)
            deckCard.card = card
            deckCard.quantity = Int16(quantity)
            deckCard.isSideboard = isSideboard
            newDeck.addToCards(deckCard)
        }
    }
    
    @objc func settings(){
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        guard let settingsVC = storyboard.instantiateInitialViewController() as? SettingsTableViewController else {
            fatalError("Error going to settings")
        }
        //self.navigationController?.pushViewController(settingsVC, animated: true)
        self.present(settingsVC, animated: true, completion: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //        if indexPath.row == 0 {
        //            collectionView.deselectItem(at: indexPath, animated: false)
        //            return
        //        }
        if !(self.splitViewController?.traitCollection.horizontalSizeClass == .regular) {
            if indexPath.section == 0 {
                //StateCoordinator.shared.didSelectCollection(collection: "Search")
                if indexPath.item == 0 {
                    self.navigationController?.pushViewController(CardListTableViewController.freshCardList(), animated: true)
                } else {
                    self.navigationController?.pushViewController(TokenListTableViewController.freshTokenList(), animated: true)
                    //                    let vc = UIHostingController(rootView: SearchResultsView().environment(\.managedObjectContext, CoreDataStack.handler.privateContext))
                    //                    self.navigationController?.pushViewController(vc, animated: true)
                }
            } else if indexPath.section == 2 {
                //StateCoordinator.shared.didSelectDeck(d: cdDecks[indexPath.row].objectID)
                self.navigationController?.pushViewController(DeckTableViewController.freshDeck(deck: cdDecks[indexPath.row].objectID), animated: true)
            } else if indexPath.section == 1 {
                //StateCoordinator.shared.didSelectCollection(collection: cdCollections[indexPath.row].objectID)
                self.navigationController?.pushViewController(CollectionTableViewController.freshCollection(collection: cdCollections[indexPath.row].objectID), animated: true)
            }
            //self.navigationController?.pushViewController(details, animated: true)
        } else {
            
            if indexPath.section == 0 {
                if indexPath.item == 0 {
                    self.splitViewController?.setViewController(nil, for: .supplementary)
                    self.splitViewController?.setViewController(CardListTableViewController.freshCardList(), for: .supplementary)
                } else {
                    //                    let vc = UIHostingController(rootView: SearchResultsView().environment(\.managedObjectContext, CoreDataStack.handler.privateContext))
                    //                    self.splitViewController?.setViewController(vc, for: .supplementary)
                    self.splitViewController?.setViewController(nil, for: .supplementary)
                    self.splitViewController?.setViewController(TokenListTableViewController.freshTokenList(), for: .supplementary)
                }
            } else if indexPath.section == 2 {
                //StateCoordinator.shared.didSelectDeck(d: cdDecks[indexPath.row].objectID)
                self.splitViewController?.setViewController(nil, for: .supplementary)
                self.splitViewController?.setViewController(DeckTableViewController.freshDeck(deck: cdDecks[indexPath.row].objectID), for: .supplementary)
                
                self.splitViewController?.setViewController(nil, for: .secondary)
                //self.splitViewController?.setViewController(DeckStatsTableViewController.refreshDeckStats(id: cdDecks[indexPath.row-1].objectID), for: .secondary)
                let vc = UIHostingController(rootView: DeckStatsView(deck: cdDecks[indexPath.row]))
                self.splitViewController?.setViewController(vc, for: .secondary)
                
            } else if indexPath.section == 1 {
                //StateCoordinator.shared.didSelectCollection(collection: cdCollections[indexPath.row].objectID)
                self.splitViewController?.setViewController(nil, for: .supplementary)
                self.splitViewController?.setViewController(CollectionTableViewController.freshCollection(collection: cdCollections[indexPath.row].objectID), for: .supplementary)
            }
        }
    }
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return sections.count
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        if section == 2 {
            return cdDecks.count
        } else if section == 1 {
            return cdCollections.count
        } else {
            return sections[section].count - 1
        }
    }
    
    private func configureHierarchy() {
        collectionView.collectionViewLayout = createLayout()
    }
    private func createLayout() -> UICollectionViewLayout {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.headerMode = .supplementary
        config.footerMode = .none
        let list =  UICollectionViewCompositionalLayout.list(using: config)
        
        return list
    }
    func createDataSource(){
        reloadDecksFromCoreData()
        reloadCollectionsFromCoreData()
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, String> { (cell, indexPath, item) in
            var content = UIListContentConfiguration.sidebarCell()
            content.text = "\(item)"
            content.textProperties.numberOfLines = 2
            cell.contentConfiguration = content
        }
        dataSource = UICollectionViewDiffableDataSource<HeaderItem, Item>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: Item) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item.title)
        }
        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader){ (headerView, elementKind, indexPath) in
            
            // Obtain header item using index path
            let headerItem = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
            
            // Configure header view content based on headerItem
            var configuration = headerView.defaultContentConfiguration()
            configuration.text = headerItem.title
            
            // Customize header appearance to make it more eye-catching
            configuration.textProperties.font = .boldSystemFont(ofSize: 16)
            
            //configuration.textProperties.color = .systemBlue
            configuration.directionalLayoutMargins = .init(top: 20.0, leading: 0.0, bottom: 10.0, trailing: 0.0)
            
            // Apply the configuration to header view
            headerView.contentConfiguration = configuration
        }
        dataSource.supplementaryViewProvider = { (collectionView, elementKind, indexPath) in
            if elementKind == UICollectionView.elementKindSectionHeader {
                
                // Dequeue header view
                return self.collectionView.dequeueConfiguredReusableSupplementary(
                    using: headerRegistration, for: indexPath)
                
            } else {
                
                // Dequeue footer view
                return nil
            }
        }
        var dataSourceSnapshot = NSDiffableDataSourceSnapshot<HeaderItem, Item>()
        
        // Create collection view section based on number of HeaderItem in modelObjects
        dataSourceSnapshot.appendSections(sectionItems)
        
        // Loop through each header item to append symbols to their respective section
        for headerItem in sectionItems {
            
            if headerItem.title == "Tools" {
                dataSourceSnapshot.appendItems([Item(title: "Search"), Item(title: "Tokens")], toSection: headerItem)
                
            } else if headerItem.title == "Collections" {
                dataSourceSnapshot.appendItems([Item(title: "Collection"), Item(title: "Wish List")], toSection: headerItem)
            } else {
                var decks: [Item] = []
                for deck in cdDecks {
                    decks.append(Item(title: deck.name))
                }
                dataSourceSnapshot.appendItems(decks, toSection: headerItem)
            }
        }
        
        dataSource.apply(dataSourceSnapshot)
    }
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if indexPath.section == 2 {
            let edit = UIAction(title: "Edit",
                                image: UIImage(systemName: "pencil")) { _ in
                let deck = self.cdDecks[indexPath.row]
                let storyboard = UIStoryboard(name: "EditDeck", bundle: nil)
                guard let editDeckView = storyboard.instantiateInitialViewController() as? EditDeckTableViewController else {
                    fatalError("Project config error - storyboard doesnt provide a EditDeckCard")
                }
                editDeckView.deck = deck
                editDeckView.collectionsViewController = self
                self.present(editDeckView, animated: true, completion: nil)
                
            }
            
            
            let delete = UIAction(title: "Delete",
                                  image: UIImage(systemName: "trash.fill"),
                                  attributes: [.destructive]) { action in
                CoreDataStack.handler.privateContext.delete(self.cdDecks[indexPath.row] as NSManagedObject)
                do {
                    try CoreDataStack.handler.privateContext.save()
                } catch {
                    print(error)
                }
                self.reloadDecksFromCoreData()
                DispatchQueue.main.async {
                    
                    self.createDataSource()
                }
            }
            
            return UIContextMenuConfiguration(identifier: nil,
                                              previewProvider: nil) { _ in
                UIMenu(title: "", children: [edit, delete])
            }
        } else {
            return nil
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        if let indexPath = coordinator.destinationIndexPath {
            if indexPath.section == 2 {
                coordinator.session.loadObjects(ofClass: NSString.self) { items in
                    guard let strings = items as? [String] else { return }
                    for string in strings {
                        let deck = self.cdDecks[indexPath.row]
                        let card = DataManager.getCard(byUUID: string)
                        //let card = self.getCard(byUUID: string)
                        let results = deck.cards?.filter {
                            if let deckCard = $0 as? DeckCard {
                                return deckCard.card == card
                            }
                            return false
                        }
                        if results?.count ?? 0 > 0 {
                            if let found: DeckCard = results?[0] as? DeckCard {
                                found.quantity += 1
                                try? CoreDataStack.handler.managedObjectContext.save()
                            }
                        } else {
                            if let card = card {
                                guard  let entity = NSEntityDescription.entity(forEntityName: "DeckCard", in:  CoreDataStack.handler.privateContext) else {
                                    fatalError("Failed to decode Card")
                                }
                                let deckCard = DeckCard.init(entity: entity, insertInto: CoreDataStack.handler.privateContext)
                                deckCard.card = card
                                deckCard.quantity = 1
                                self.cdDecks[indexPath.row].addToCards(deckCard)
                                do {
                                    try CoreDataStack.handler.privateContext.save()
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }
                }
            } else if indexPath.section == 1 {
                coordinator.session.loadObjects(ofClass: NSString.self) { items in
                    guard let strings = items as? [String] else { return }
                    for string in strings {
                        print(string)
                        let card = DataManager.getCard(byUUID: string)
                        
                        if let card = card {
                            guard  let entity = NSEntityDescription.entity(forEntityName: "CollectionCard", in:  CoreDataStack.handler.privateContext) else {
                                fatalError("Failed to decode Card")
                            }
                            let collectionCard = CollectionCard.init(entity: entity, insertInto: CoreDataStack.handler.privateContext)
                            collectionCard.card = card
                            collectionCard.quantity = 1
                            self.cdCollections[indexPath.row].addToCards(collectionCard)
                            do {
                                try CoreDataStack.handler.privateContext.save()
                            } catch {
                                print(error)
                            }
                        }
                    }
                }
            }
        }
    }
}

