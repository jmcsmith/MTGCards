//
//  DataManager.swift
//  MTGCards
//
//  Created by Joseph Smith on 1/17/19.
//  Copyright © 2019 Robotic Snail Software. All rights reserved.
//

import Foundation
import CoreData
import UIKit

public class DataManager {
    static func getLocalVersion() -> String {
        return "1.0"
    }
    static func getSet(setCode: String, completion: @escaping (_ success: Bool) -> Void) {
        
        let setURL = URL(string: "https://mtgjson.com/json/\(setCode).json")
        do {
            let data = try Data(contentsOf: setURL!)
            let d = data
            
            guard let codingUserInfoKeyManagedObjectContext = CodingUserInfoKey.managedObjectContext else {
                fatalError("Failed to retrieve context")
            }
            let decoder = newJSONDecoder()
            let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            managedObjectContext.persistentStoreCoordinator = CoreDataStack.handler.storeContainer.persistentStoreCoordinator
            
            decoder.userInfo[codingUserInfoKeyManagedObjectContext] = managedObjectContext
            managedObjectContext.perform {
                do {
                    try autoreleasepool {
                        let set = try decoder.decode(MTGSet.self, from: d)
                        print("\(setCode): \(set.cards.count)")
                    }
                    do {
                        try managedObjectContext.save()
                        
                    } catch {
                        print(error)
                    }
                    managedObjectContext.parent?.reset()
                    
                    
                    completion(true)
                } catch let error {
                    print(error)
                    completion(false)
                }
            }
        } catch let error {
            print("Download error: \(error)")
            completion(false)
        }
    }
    static func getSetList() -> SetList? {
        let setListURL = URL(string: "https://mtgjson.com/json/SetList.json")
        let setList = try? SetList.init(fromURL: setListURL!)
        return setList
    }
    
}
public extension CodingUserInfoKey {
    // Helper property to retrieve the context
    static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")
}
