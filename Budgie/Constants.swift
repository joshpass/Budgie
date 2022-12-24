//
//  Constants.swift
//  Budgie
//
//  Created by Josh Pasricha on 20/12/22.
//

import Foundation

enum Focusable: Hashable {
    case none
    case categoryRow(id: ObjectIdentifier)
}

enum LogType: String, CaseIterable {
    case expense, income
}

enum CategoryViewType {
    case addEdit, select
}

enum LogViewType {
    case add, edit
}

struct Constants {
    static var parentExpenseCategories: [DefaultExpenseCategory] = [.foodBev, .bills, .transportation]
    static var parentIncomeCategories: [DefaultIncomeCategory] = [.interest, .reimbursement]
}

enum DefaultExpenseCategory: String, CaseIterable {
    case foodBev = "Food and Beverage"
    case bills = "Bills and Utilities"
    case transportation = "Transportation"

    case shopping = "Shopping"
    case entertainment = "Entertainment"
//    case smoking = "Smoking and Drugs"
    case travel = "Travel"
    case health = "Health and Fitness"
    case loaned = "Loaned to Somebody"
//    case love = "Bubbie"
    case giftDonations = "Gifts and Donations"
    case investment = "Investment"
    case withdrawal = "Cash Withdrawal"
    case birthday = "Birthday Expenses"
}

enum DefaultFoodCategory: String, CaseIterable {
    case outsideFood = "Food at Restaurant"
    case snacks = "Snacks"
    case orderingIn = "Ordering In"
    case outsideBooze = "Alcohol at Bar/Pub/Club"
    case boozeForHome = "Alcohol at Home"
}

enum DefaultBillCategory: String, CaseIterable {
    case phone = "Phone Bill"
    case internet = "Internet and DTH Bill"
    case electricity = "Electricity Bill"
    case maintenance = "Society Maintenance"
    case maid = "Maid Salary"
    case cook = "Cook Salary"
    case laundry = "Laundry Bill"
    case boozeForHome = "Alcohol at Home"
    case ott = "OTT Subscriptions"
    case gamePass = "Xbox Game Pass Subscription"
    case appleMusic = "Apple Music Subscription"
}

enum DefaultTransportationCategory: String, CaseIterable {
    case taxi = "Taxi Fares"
    case parking = "Parking Fees"
    case fuel = "Fuel"
    case servicing = "Car Maintenance"
}

enum DefaultIncomeCategory: String, CaseIterable {
    case salary = "Salary"
    case gift = "Gifts"
    case interest = "Interest"
    case bonusAward = "Awards and Bonuses"
    case reimbursement = "Reimbursement"
}

enum DefaultInterestCategory: String, CaseIterable {
    case dividends = "Stock Dividends"
    case capitalGains = "Capital Gains"
    case savingsAccount = "Saving Account Interest"
}

enum DefaultReimbursementCategory: String, CaseIterable {
    case reimbursement = "Corporate Reimbursements"
    case owed = "Personal Reimbursements"
}
