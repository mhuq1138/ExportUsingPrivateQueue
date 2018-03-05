//
//  ListViewController.swift
//  ExportUsingPrivateQueue
//
//  Created by Mazharul Huq on 3/4/18.
//  Copyright © 2018 Mazharul Huq. All rights reserved.
//

import UIKit
import CoreData

class ListViewController: UITableViewController {
    @IBOutlet var headerView: UIView!
    
    lazy var coreDataStack = CoreDataStack(modelName: "PersonList")
    
    lazy var fetchedResultsController:NSFetchedResultsController<Person> = {
        let frc = NSFetchedResultsController(fetchRequest: personFetchRequest(),
                                             managedObjectContext: self.coreDataStack.managedContext,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        return frc
        
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.headerView.backgroundColor = UIColor.red
        self.navigationItem.leftBarButtonItem = self.exportBarButtonItem()

        do {
            try fetchedResultsController.performFetch()
        }
        catch let error as NSError {
            print("Unable fetch records, \(error)")
        }
    }

    func personFetchRequest()-> NSFetchRequest<Person>{
        let fetchRequest:NSFetchRequest<Person> = Person.fetchRequest()
        fetchRequest.fetchBatchSize = 20
        let sortDescriptor =
            NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        return fetchRequest
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let sections = self.fetchedResultsController.sections else{
             return 0
        }
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = self.fetchedResultsController.sections else{
            return 0
        }
        return sections[section].numberOfObjects
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        configureCell(cell, indexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        let person = fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = person.name
        cell.detailTextLabel?.text = "\(person.age)"
    }

    @IBAction func changeColorTapped(_ sender: Any) {
        if self.headerView.backgroundColor == UIColor.red{
            self.headerView.backgroundColor = UIColor.blue
        }
        else{
            self.headerView.backgroundColor = UIColor.red
        }
    }
}
//Extension for export code
extension ListViewController{
    
    func exportBarButtonItem() -> UIBarButtonItem {
        return UIBarButtonItem(title: "Export", style: .plain, target: self, action: #selector(exportTapped))
    }
    
    @objc func exportTapped() {
        self.navigationItem.leftBarButtonItem = self.activityIndicatorBarButtonItem()
        /*
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coreDataStack.managedContext.persistentStoreCoordinator
        
        
        context.perform { () -> Void in
            var results: [Person]
            let fetchRequest = self.personFetchRequest()
            do {
                results = try context.fetch(fetchRequest)
            } catch {
                let nserror = error as NSError
                print("Error: \(nserror)")
                results = []
            }
            self.exportToFile(results)
        }
         */
        
        self.coreDataStack.storeContainer.performBackgroundTask { context
            in
            var results:[Person] = []
            let fetchRequest = self.personFetchRequest()
            do{
                results =
                    try self.coreDataStack.managedContext.fetch(fetchRequest)
            }
            catch{
                let nserror = error as NSError
                print("Error: \(nserror)")
                results = []
            }
            self.exportToFile(results)
        }
        
    }
    
    func activityIndicatorBarButtonItem() -> UIBarButtonItem {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        let barButtonItem = UIBarButtonItem(customView: activityIndicator)
        activityIndicator.startAnimating()
        
        return barButtonItem
    }
    
    func exportToFile(_ results: [Person]){
        //1
        let exportFilePath = NSTemporaryDirectory() + "export.csv"
        let exportFileURL = URL(fileURLWithPath: exportFilePath)
        FileManager.default.createFile(
            atPath: exportFilePath, contents: Data(), attributes: nil)
        //2
        let fileHandle: FileHandle?
        do {
            fileHandle = try FileHandle(forWritingTo: exportFileURL)
        } catch let error as NSError {
            print("Unable create file handle, \(error)")
            fileHandle = nil
        }
        
        if let fileHandle = fileHandle {
            //4
            for person in results {
                fileHandle.seekToEndOfFile()
                guard let csvData = person.csv()
                    .data(using: .utf8, allowLossyConversion: false) else {
                        continue
                }
                fileHandle.write(csvData)
            }
            //5
            print("Export Path: \(exportFilePath)")
            fileHandle.closeFile()
            DispatchQueue.main.async {
                self.navigationItem.leftBarButtonItem =
                    self.exportBarButtonItem()
                print("Export succeeded")
            }
        } else {
            DispatchQueue.main.async {
                self.navigationItem.leftBarButtonItem =
                    self.exportBarButtonItem()
                print("Export failed")
            }
        }
        
    }
   
}
