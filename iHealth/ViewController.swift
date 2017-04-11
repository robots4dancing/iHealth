//
//  ViewController.swift
//  iHealth
//
//  Created by ANI on 4/11/17.
//  Copyright © 2017 Shane Empie. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    
    let healthStore = HKHealthStore()
    
    //MARK: - HealthKit Methods
    
    func getUserData() {
        getUserAge()
        getUserHeight()
        getUserSteps()
    }
    
    func getUserAge() {
        do {
            let dateOfBirth = try healthStore.dateOfBirthComponents()
            let userAge = dateOfBirth.year
            print("Age: (\(userAge))")
        } catch {
            print("Got DoB Error")
        }
    }
    
    func getUserHeight() {
        mostRecentQuantitySampleOfType(heightType!, predicate: nil) { (quantity, error) in
            let heightUnit = HKUnit.foot()
            let userHeight = quantity.doubleValue(for: heightUnit)
            print("Height: \(userHeight)")
        }
    }
    
    func mostRecentQuantitySampleOfType(_ quantityType: HKQuantityType, predicate: NSPredicate?, completion: @escaping (_ quantity: HKQuantity, _ error: NSError?) ->()) {
        
        let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: 1, sortDescriptors: [timeSortDescriptor]) { (query, results, error) in
            if results!.count > 0 {
                let quantitySample = results!.first as! HKQuantitySample
                let quantity = quantitySample.quantity
                completion(quantity, nil)
            } else {
                print("No Height")
            }
        }
        
        healthStore.execute(query)
    }
    
    func getUserSteps() {
        let endDate = Date()
        let dayCount = -7
        let startDate = Calendar.current.date(byAdding: .day, value: dayCount, to: endDate)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: HKQueryOptions())
        let sampleLimit = abs(dayCount) * 100
        let query = HKSampleQuery(sampleType: stepsType!, predicate: predicate, limit: sampleLimit, sortDescriptors: nil) { (query, results, error) in
            var totalSteps = 0.0
            for steps in results as! [HKQuantitySample] {
                totalSteps += steps.quantity.doubleValue(for: HKUnit.count())
            }
            let avgSteps = totalSteps / Double(abs(dayCount))
            print("Total: \(totalSteps) AVG: \(avgSteps)")
        }
        healthStore.execute(query)
    }
    
    //MARK: - Authorization Methods
    
    let heightType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)
    let heartRate = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)
    let weightType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)
    let stepsType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
    
    func dataTypesToWrite() -> Set<HKSampleType> {
        return [heightType!, heartRate!, weightType!]
    }
    
    func dataTypesToRead() -> Set<HKObjectType> {
        let birthdayType = HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth)
        return [heightType!, heartRate!, weightType!, birthdayType!, stepsType!]
    }
    
    func requestAuthorizatin() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore.requestAuthorization(toShare: dataTypesToWrite(), read: dataTypesToRead(), completion: { (success, error) in
                if success {
                    DispatchQueue.main.async {
                        self.getUserData()
                    }
                } else {
                    print("Error: \(error)")
                }
            })
        } else {
            print("HK Not Available.")
        }
    }
    
    //MARK: - Life Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        requestAuthorizatin()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

