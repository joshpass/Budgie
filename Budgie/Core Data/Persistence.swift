//
//  Persistence.swift
//  Budgie
//
//  Created by Josh Pasricha on 14/12/22.
//

import CoreData
import SwiftUI

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Add Account
        let userAccount = Account(context: viewContext)
        userAccount.name = "Josh Pasricha"
        userAccount.balance = 0.00

        // Add Default Expense Categories
        for (index, category) in DefaultExpenseCategory.allCases.enumerated() {
            let dbCategory = Category(context: viewContext)
            dbCategory.title = category.rawValue
            dbCategory.iconName = "testCategoryIcon"
            dbCategory.lastLogDate = Calendar.current.date(byAdding: .hour, value: -index, to: Date())
            dbCategory.isCustom = false
            dbCategory.type = LogType.expense.rawValue
        }
        // Add Default Income Categories
        for (index, category) in DefaultIncomeCategory.allCases.enumerated() {
            let dbCategory = Category(context: viewContext)
            dbCategory.title = category.rawValue
            dbCategory.iconName = "testCategoryIcon"
            dbCategory.lastLogDate = Calendar.current.date(byAdding: .hour, value: -index, to: Date())
            dbCategory.isCustom = false
            dbCategory.type = LogType.income.rawValue
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }

        // Add Test Data for Log List View
        for index in 0 ..< 10 {
            let categories = try? viewContext.fetch(Category.fetchRequest())
            let newItem = Log(context: viewContext)
            newItem.timestamp = Calendar.current.date(byAdding: .day, value: -index, to: Date())
            newItem.amount = NSDecimalNumber(value: 100 * index)
            newItem.category = categories?.randomElement()
            let newItem2 = Log(context: viewContext)
            var timestamp2 = Calendar.current.date(byAdding: .day, value: -index, to: Date())
            timestamp2 = Calendar.current.date(byAdding: .hour, value: -index, to: timestamp2!)
            newItem2.timestamp = timestamp2
            newItem2.amount = NSDecimalNumber(value: 100 * index)
            newItem2.category = categories?.randomElement()
            userAccount.balance = userAccount.balance?.subtracting(newItem.amount!).subtracting(newItem2.amount!)
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Budgie")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func addTestAccount() {
        // Add Account
        let userAccount = Account(context: container.viewContext)
        userAccount.name = "Josh Pasricha"
        userAccount.balance = 0.00
        save()
    }

    func addTestCategories() {
        func createCategory(title: String) -> Category {
            let dbCategory = Category(context: container.viewContext)
            dbCategory.title = title
            dbCategory.iconName = "testCategoryIcon"
            dbCategory.isCustom = false
            dbCategory.type = LogType.expense.rawValue
            return dbCategory
        }
        // Add Default Expense Categories
        for category in DefaultExpenseCategory.allCases {
            let dbCategory = Category(context: container.viewContext)
            dbCategory.title = category.rawValue
            dbCategory.iconName = "testCategoryIcon"
            dbCategory.isCustom = false
            dbCategory.type = LogType.expense.rawValue
            dbCategory.isParent = Constants.parentExpenseCategories.contains(category)
            if dbCategory.isParent {
                switch category {
                    case .foodBev:
                        dbCategory.subCategories =
                        NSMutableSet(
                            array: DefaultFoodCategory.allCases.map { createCategory(title: $0.rawValue) }
                        )
                    case .transportation: dbCategory.subCategories =
                        NSMutableSet(
                            array: DefaultTransportationCategory.allCases.map { createCategory(title: $0.rawValue) }
                        )
                    case .bills: dbCategory.subCategories =
                        NSMutableSet(
                            array: DefaultBillCategory.allCases.map { createCategory(title: $0.rawValue) }
                        )
                    default: break
                }
            }
        }
        // Add Default Income Categories
        for category in DefaultIncomeCategory.allCases {
            let dbCategory = Category(context: container.viewContext)
            dbCategory.title = category.rawValue
            dbCategory.iconName = "testCategoryIcon"
            dbCategory.isCustom = false
            dbCategory.type = LogType.income.rawValue
            dbCategory.isParent = Constants.parentIncomeCategories.contains(category)
            if dbCategory.isParent {
                switch category {
                    case .interest:
                        dbCategory.subCategories =
                        NSMutableSet(
                            array: DefaultInterestCategory.allCases.map { createCategory(title: $0.rawValue) }
                        )
                    case .reimbursement: dbCategory.subCategories =
                        NSMutableSet(
                            array: DefaultReimbursementCategory.allCases.map { createCategory(title: $0.rawValue) }
                        )
                    default: break
                }
            }
        }
        save()
    }

    func addTestCalendarItems() {
        // Add Test Data for Log List View
        let viewContext = container.viewContext
        let userAccount = try? viewContext.fetch(Account.fetchRequest()).first
        for index in 0 ..< 10 {
            let categories = try? viewContext.fetch(Category.fetchRequest())
            let newItem = Log(context: viewContext)
            newItem.timestamp = Calendar.current.date(byAdding: .day, value: -index, to: Date())
            newItem.amount = NSDecimalNumber(value: 100 * index)
            newItem.category = categories?.randomElement()
            let newItem2 = Log(context: viewContext)
            var timestamp2 = Calendar.current.date(byAdding: .day, value: -index, to: Date())
            timestamp2 = Calendar.current.date(byAdding: .hour, value: -index, to: timestamp2!)
            newItem2.timestamp = timestamp2
            newItem2.amount = NSDecimalNumber(value: 100 * index)
            newItem2.category = categories?.randomElement()
            userAccount?.balance = userAccount?.balance?.subtracting(newItem.amount!).subtracting(newItem2.amount!)
        }
        save()
    }

    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
