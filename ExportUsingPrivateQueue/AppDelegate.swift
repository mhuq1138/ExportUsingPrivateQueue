//
//  AppDelegate.swift
//  ExportUsingPrivateQueue
//
//  Created by Mazharul Huq on 3/4/18.
//  Copyright © 2018 Mazharul Huq. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    lazy var coreDataStack = CoreDataStack(modelName: "PersonList")


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        //deleteAll()
        seedStoreIfNeeded()
        return true
    }
    
    func seedStoreIfNeeded(){
        var count = 0
        let fetchRequest:NSFetchRequest<Person> = Person.fetchRequest()
        do{
            count = try coreDataStack.managedContext.count(for: fetchRequest)
        }
        catch let error as NSError {
            print("Error seeding store, error:\(error)")
        }
        guard count == 0 else{
            return
        }
        for i in (1...200000) {
            let person = Person(context: coreDataStack.managedContext)
            person.name = "John #\(i)"
            person.age = Int16(arc4random() % 100)
            if person.age < 10 {
                person.age = 10
            }
        }
        self.coreDataStack.saveContext()
    }
    
    func deleteAll(){
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Person")
        let objects: [AnyObject]?
        do {
            objects = try self.coreDataStack.managedContext
                .fetch(fetchRequest)
        } catch _ {
            objects = nil
        }
        for object in objects as! [NSManagedObject] {
            self.coreDataStack.managedContext.delete(object)
        }
        
        do {
            try self.coreDataStack.managedContext.save()
        } catch let error as NSError {
            print("Error deleting Person error:\(error)")
        }
    }
}

