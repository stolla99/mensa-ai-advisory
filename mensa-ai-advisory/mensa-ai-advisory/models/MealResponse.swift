//
//  MealResponse.swift
//  MensaAdvisory
//
//  Created by Arne Stoll on 11/2/24.
//

struct MealResponse: Decodable {
    struct MealData: Decodable {
        let title: String
        let explanation: String
        let price: String
    }

    let meals: [MealData]
    let comment: String
    let funny_title: String
}
