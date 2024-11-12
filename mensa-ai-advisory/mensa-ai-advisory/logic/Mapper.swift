//
//  Mapper.swift
//  MensaAdvisory
//
//  Created by Arne Stoll on 11/2/24.
//

import Foundation
import SwiftUI

func mapMensaDaysToMealResponses(mensaDays: [MensaDay]) -> [MealResponse] {
    return mensaDays.map {
        let meals: [MealResponse.MealData] = $0.meals?.allObjects as? [MealResponse.MealData] ?? []
        let mealResponse = MealResponse(
            meals: meals.map {
                return MealResponse.MealData(title: $0.title, explanation: $0.explanation, price: $0.price)
            },
            comment: $0.comment ?? "-",
            funny_title: $0.funny_title ?? "-"
        )
        return mealResponse
    }
}

func mapMensaDayToContentTemplateView(mensaDay: MensaDay, with mealTemplate: String) -> ContentTemplateView {
    let (date, timestamp) = getCurrentDateAndTime(currentDate: mensaDay.date ?? Date())
    let meals: [Meal] = mensaDay.meals?.allObjects as? [Meal] ?? []
    var content = ""
    for meal: Meal in meals {
        content.append(mealTemplate
            .replacingOccurrences(of: "{title}", with: meal.title ?? "")
            .replacingOccurrences(of: "{explanation}", with: meal.explanation ?? "")
            .replacingOccurrences(of: "{price}", with: meal.price ?? "")
        )
    }
    content.append(mensaDay.comment ?? "")
    
    let newContent = ContentTemplateView(
        title: mensaDay.funny_title ?? "",
        date: date,
        timestamp: timestamp,
        content: LocalizedStringKey.init(content)
    )
    return newContent
}
