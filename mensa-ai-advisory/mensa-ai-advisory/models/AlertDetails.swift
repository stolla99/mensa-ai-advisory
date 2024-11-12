//
//  AlertDetails.swift
//  MensaAdvisory
//
//  Created by Arne Stoll on 11/2/24.
//

import Foundation

struct AlertDetails: Identifiable {
    let modalType: ModalType
    let errorDescription: String
    let queryDate: Date
    let id = UUID()
}
