//
//  Person+CoreDataClass.swift
//  ExportUsingPrivateQueue
//
//  Created by Mazharul Huq on 3/4/18.
//  Copyright © 2018 Mazharul Huq. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Person)
public class Person: NSManagedObject {
    func csv()-> String{
        let coalescedName = name ?? ""
        let coalescedAge = age
        return "\(coalescedName)," +
        "\(coalescedAge)\n"
    }
}
