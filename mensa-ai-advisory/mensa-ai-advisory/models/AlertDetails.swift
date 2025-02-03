//
//  AlertDetails.swift
//  MensaAdvisory
//
//  Created by Arne Stoll on 11/2/24.
//

import Foundation

struct AlertDetails: Identifiable, Equatable {
    let title: String
    let errorDescription: String
    let intentAlert: Bool
    let id = UUID()
}
