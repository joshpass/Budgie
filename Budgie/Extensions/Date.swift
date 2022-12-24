//
//  Date.swift
//  Budgie
//
//  Created by Josh Pasricha on 15/12/22.
//

import Foundation

extension Date {
    func monthDisplayString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .autoupdatingCurrent
        dateFormatter.dateFormat = self.dateComponents().year == Date().dateComponents().year ? "MMMM" : "MMMM, YYYY"
        return dateFormatter.string(from: self)
    }
    
    func dateDisplayString(shouldDisplayMonthAndYear: Bool = false) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .ordinal
        numberFormatter.locale = .autoupdatingCurrent
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .autoupdatingCurrent
        dateFormatter.dateFormat = "EEEE"
        var displayString = dateFormatter.string(from: self)
        if Calendar.current.isDateInToday(self) {
            displayString.insert(contentsOf: "Today, ", at: displayString.startIndex)
        } else if Calendar.current.isDateInYesterday(self) {
            displayString.insert(contentsOf: "Yesterday, ", at: displayString.startIndex)
        }
        displayString.insert(contentsOf: ", the ", at: displayString.endIndex)
        dateFormatter.dateFormat = "dd"
        let dayNumber = NSNumber(value: Int(dateFormatter.string(from: self)) ?? .zero)
        displayString.insert(contentsOf: numberFormatter.string(from: dayNumber) ?? "", at: displayString.endIndex)
        if shouldDisplayMonthAndYear {
            displayString.insert(contentsOf: " of \(monthDisplayString())", at: displayString.endIndex)
        }
        return displayString
    }
    
    func time() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .autoupdatingCurrent
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: self)
    }

    func dateComponents() -> DateComponents {
        Calendar.autoupdatingCurrent.dateComponents([.year], from: self)
    }

    func monthPredicate() -> NSPredicate {
        let currentMonth = Calendar.autoupdatingCurrent.dateComponents(
            [.year, .month],
            from: self
        )
        var startOfMonth = DateComponents()
        startOfMonth.year = currentMonth.year
        startOfMonth.month = currentMonth.month
        startOfMonth.day = 1

        let firstDayOfTheMonth = Calendar.autoupdatingCurrent.date(from: startOfMonth)
        let startOfNextMonth = Calendar.autoupdatingCurrent.date(
            byAdding: DateComponents(month: 1),
            to: firstDayOfTheMonth ?? Date()
        )

        return NSPredicate(
            format: "%K >= %@ && %K < %@",
            "timestamp", firstDayOfTheMonth! as NSDate,
            "timestamp", startOfNextMonth! as NSDate
        )
    }
}
