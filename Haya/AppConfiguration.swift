//
//  AppConfiguration.swift
//  Haya
//
//  Created by Haya almousa on 19/04/2026.
//

import Foundation
import SwiftUI

enum AppConfiguration {
    static let appName = "Haya"
    static let appleUserIdentifierKey = "haya.apple_user_identifier"
    static let bodyAnalysisProductID = "haya.body_analysis_unlock"
    static let cloudKitContainerIdentifier = "iCloud.HayaAlmousa.Haya"
    static let currentChallengeID = "weekly-family-occasion"
}

enum AppTab: CaseIterable, Identifiable {
    case closet
    case scan
    case vote
    case profile

    var id: Self { self }

    var label: String {
        switch self {
        case .closet: return "الدولاب"
        case .scan: return "إضافة"
        case .vote: return "التصويت"
        case .profile: return "البروفايل"
        }
    }

    var systemImage: String {
        switch self {
        case .closet: return "square.grid.2x2"
        case .scan: return "camera"
        case .vote: return "trophy"
        case .profile: return "face.smiling"
        }
    }
}

enum ComposerStyle {
    case scan

    var title: String {
        switch self {
        case .scan:
            return "أضيفي قطعة لدولابك"
        }
    }
}
