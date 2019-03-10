//
//  CoreDataManager.swift
//  MTGCards
//
//  Created by Joseph Smith on 3/15/18.
//  Copyright © 2018 Robotic Snail Software. All rights reserved.
//

import CoreData
import Foundation
import UIKit

final class CoreDataManager {

    // MARK: - Properties
    private let modelName: String

    // MARK: - Initialization
    init(modelName: String) {
        self.modelName = modelName

        // Setup Notification Handling
        setupNotificationHandling()
    }

    // MARK: - Core Data Stack
     lazy var managedObjectContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)

        managedObjectContext.parent = self.privateManagedObjectContext

        return managedObjectContext
    }()

    private lazy var privateManagedObjectContext: NSManagedObjectContext = {
        // Initialize Managed Object Context
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)

        // Configure Managed Object Context
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator

        return managedObjectContext
    }()

    private lazy var managedObjectModel: NSManagedObjectModel = {
        guard let modelURL = Bundle.main.url(forResource: self.modelName, withExtension: "momd") else {
            fatalError("Unable to Find Data Model")
        }

        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Unable to Load Data Model")
        }

        return managedObjectModel
    }()

    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)

        let fileManager = FileManager.default
        let storeName = "\(self.modelName).sqlite"

        let documentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        let persistentStoreURL = documentsDirectoryURL.appendingPathComponent(storeName)

        do {
            let options = [ NSInferMappingModelAutomaticallyOption: true,
                            NSMigratePersistentStoresAutomaticallyOption: true]

            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                              configurationName: nil,
                                                              at: persistentStoreURL,
                                                              options: options)
        } catch {
            fatalError("Unable to Load Persistent Store")
        }

        return persistentStoreCoordinator
    }()

    // MARK: - Notification Handling
    @objc func saveChanges(_ notification: NSNotification) {
        managedObjectContext.perform {
            do {
                if self.managedObjectContext.hasChanges {
                    try self.managedObjectContext.save()
                }
            } catch {
                let saveError = error as NSError
                print("Unable to Save Changes of Managed Object Context")
                print("\(saveError), \(saveError.localizedDescription)")
            }

            self.privateManagedObjectContext.perform {
                do {
                    if self.privateManagedObjectContext.hasChanges {
                        try self.privateManagedObjectContext.save()
                    }
                } catch {
                    let saveError = error as NSError
                    print("Unable to Save Changes of Private Managed Object Context")
                    print("\(saveError), \(saveError.localizedDescription)")
                }
            }

        }
    }

    // MARK: - Helper Methods
    private func setupNotificationHandling() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(CoreDataManager.saveChanges(_:)), name: UIApplication.willTerminateNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(CoreDataManager.saveChanges(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

}
