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

func decidingNextStep(on queryDate: Date, on sharedData: CoreDataStack) async -> (isAlert: Bool, title: String, message: String, date: Date, type: ModalType) {
    let alreadyCheckedToday: Bool = sharedData.mensaDays.map {
        return Calendar.current.isDate(queryDate, inSameDayAs: $0.date ?? Date.distantPast)
    }.reduce(false, { $0 || $1 })
    
    if alreadyCheckedToday {
        if isPastTwoPM(on: queryDate) {
            return (
                true,
                "Information",
                "Want to check for tomorrow? If yes next refresh will trigger the fetch data for tomorrow",
                Calendar.current.date(byAdding: .day, value: 1, to: queryDate) ?? Date.distantPast,
                .yesNo
            )
        } else {
            return (
                true,
                "Proceed?",
                "You already checked the menu today. If proceeding next refresh will trigger the update regardless",
                queryDate,
                .yesNo
            )
        }
    } else {
        return (
            false,
            "",
            "",
            queryDate,
            .okOnly
        )
    }
}
