//
//  Processing.swift
//  MensaAdvisory
//
//  Created by Arne Stoll on 11/2/24.
//

import Foundation
import CoreData

func getCurrentDateAndTime(currentDate: Date) -> (date: String, timestamp: String) {
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "h:mm a"
    timeFormatter.locale = Locale(identifier: "en_US_POSIX")
    timeFormatter.timeZone = TimeZone.current

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMMM dd, yyyy"
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone.current
    
    return (date: dateFormatter.string(from: currentDate), timestamp: timeFormatter.string(from: currentDate))
}

func isPastTwoPM(on date: Date) -> Bool {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month, .day], from: date)
    var twoPMComponents = components
    twoPMComponents.hour = 14
    twoPMComponents.minute = 0
    twoPMComponents.second = 0
    guard let twoPMDate = calendar.date(from: twoPMComponents) else {
        return false
    }
    return date > twoPMDate
}

func isDateInSharedData(on queryDate: Date, on sharedData: CoreDataStack) -> Bool {
    let alreadyCheckedToday: Bool = sharedData.mensaDays.map {
        return Calendar.current.isDate(queryDate, inSameDayAs: $0.date ?? Date.distantPast)
    }.reduce(false, { $0 || $1 })
    return alreadyCheckedToday
}

func decidingNextStep(on queryDate: Date, on sharedData: CoreDataStack) async -> (isAlert: Bool, title: String, message: String, date: Date, type: ModalType) {
    let queryDateSucc: Date = Calendar.current.date(byAdding: .day, value: 1, to: queryDate) ?? Date.distantPast
    if isDateInSharedData(on: queryDate, on: sharedData) {
        if isPastTwoPM(on: queryDate) && !isDateInSharedData(on: queryDateSucc, on: sharedData) {
            return (
                false,
                "CHECK 00",
                "Today already checked checking tomorrow. Today -> Tomorrow -> Checking",
                queryDateSucc,
                .yesNo
            )
        } else {
            return (
                true,
                "OVERRIDE",
                "You already checked the menu today and tomorrow. Today -> Tomorrow -> Nothing",
                queryDate,
                .yesNo
            )
        }
    } else {
        return (
            false,
            "CHECK 24",
            "Checking menu for today. Today -> Checking",
            queryDate,
            .okOnly
        )
    }
}
