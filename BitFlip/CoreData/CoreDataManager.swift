//
//  CoreDataManager.swift
//  BitFlip
//
//  Created by Sean Ng Pack on 8/24/19.
//  Copyright © 2019 Lengjai. All rights reserved.
//

import Foundation
import CoreData

class CoreDataManager {
    
    var container: NSPersistentContainer?
    var context: NSManagedObjectContext
    
    init(container: NSPersistentContainer) {
        self.container = container
        self.context = container.viewContext
    }

    // fetches all the Flip objects
    func fetchAllFlips() -> [Flip]? {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Flip")
        
        do {
            let flip = try context.fetch(fetchRequest)
            return flip as? [Flip]
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return nil
        }
    }
    
    // fetches all the outcomes for the inputted duration
    func fetchOutcomes(range: Int) -> [String: Int] {
        let end = Date()
        let start = Calendar.current.date(byAdding: DateComponents(day: -range), to: end)!
        
        let headsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Flip")
        headsRequest.predicate = NSPredicate(format: "date > %@ AND date <= %@ AND outcome == %@",
                                        argumentArray: [start, end, 0])
        headsRequest.resultType = .countResultType
        
        let tailsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Flip")
        tailsRequest.predicate = NSPredicate(format: "date > %@ AND date <= %@ AND outcome == %@",
                                             argumentArray: [start, end, 1])
        tailsRequest.resultType = .countResultType
        
        let heads = try! context.fetch(headsRequest)[0] as! Int
        let tails = try! context.fetch(tailsRequest)[0] as! Int
        
        return ["heads": heads, "tails": tails]
    }
    
    // finds the probabilities for the given duration and returns an array of dictionaries
    // containing the dates and probabilities
    func fetchProbs(range: Int) -> [NSDictionary] {
        
        let fr = NSFetchRequest<NSDictionary>(entityName: "Flip")
     
        let end = Date()
        let start = Calendar.current.date(byAdding: DateComponents(day: -range), to: end)!
        fr.predicate = NSPredicate(format: "date > %@ AND date <= %@",
                                                    argumentArray: [start, end])
        
        fr.propertiesToGroupBy = ["date"]
        fr.resultType = .dictionaryResultType
        let hed = NSExpressionDescription()
        hed.expression = NSExpression(forFunction: "abs:",
                                      arguments: [NSExpression(forKeyPath: "headsProb")])
        hed.name = "headsProb"
        hed.expressionResultType = .doubleAttributeType
        
        let ted = NSExpressionDescription()
        ted.expression = NSExpression(forFunction: "abs:",
                                      arguments: [NSExpression(forKeyPath: "tailsProb")])
        ted.name = "tailsProb"
        ted.expressionResultType = .doubleAttributeType
        
        // generate the dictionary
        fr.propertiesToFetch = ["date", hed, ted]
        
        // fetch it!
        let probs = try! context.fetch(fr)
        print(probs.count)
        
        // do a for loop now with fetch offset!!!
        return filterPoints(set: probs, range: range)
    }
    
    // applies normalization function to reduce the number of points in a set
    func filterPoints(set: [NSDictionary], range: Int) -> [NSDictionary] {
        var newDict:[NSDictionary] = []
        let points:Float = Float(set.count)
        let const:Float = 5.0
        let offset:Int = Int(ceil(points/(Float(range) * const)))
//        print("offset is \(offset)")
        
        newDict.append(set[set.count]) //handpicked last element(most recent flip)
        for (index, item) in set.reversed().enumerated() {
            if index % offset == 0 {
                newDict.append(item)
            }
        }
        newDict.append(set[0]) //handpicked first element
        return newDict
    }
    
    // adds a flip to the context manager and saves it
    func insertFlip(outcome: Int16, date : Date, coins : Int32) -> Flip? {
        let allOutcomes = fetchOutcomes(range: 10000)
        var heads:Double = Double(allOutcomes["heads"]!)
        var tails:Double = Double(allOutcomes["tails"]!)
        
        if outcome == 0 {
            heads += 1
        }
        else {
            tails += 1
        }
        
        let total:Double = heads + tails
        
        let headsProb:Double = Double(heads/total)
        let tailsProb:Double = Double(tails/total)
        
        let entity = NSEntityDescription.entity(forEntityName: "Flip",
                                                in: context)!
        let flip = NSManagedObject(entity: entity,
                                   insertInto: context)
        flip.setValue(outcome, forKeyPath: "outcome")
        flip.setValue(date, forKeyPath: "date")
        flip.setValue(coins, forKey: "coins")
        flip.setValue(tailsProb, forKeyPath: "tailsProb")
        flip.setValue(headsProb, forKeyPath: "headsProb")
        
        save()
        return flip as? Flip
    }
    
//    // returns the number of entries in the given entity
//    func getCount(_ entity: String) -> Int {
//        switch entity {
//        case "Flip":
//            do {
//                let count = try context.count(for: NSFetchRequest(entityName: "Flip"))
//                return count
//            } catch let error as NSError {
//                print("Error: \(error.localizedDescription)")
//                return 0
//            }
//        case "headsCount":
//            do {
//                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Flip")
//                fetchRequest.predicate = NSPredicate(format: "outcome == %@", 0)
//                let count = try context.count(for: fetchRequest)
//                return count
//            } catch let error as NSError {
//                print("Error: \(error.localizedDescription)")
//                return 0
//            }
//
//        default:
//            print("Enter Flip to fetch the count")
//            return 0
//        }
//    }
    
    // MARK: - Core Data Saving support
    func save() {
        if context.hasChanges {
            do {
                try context.save()
                print("SAVED")
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
