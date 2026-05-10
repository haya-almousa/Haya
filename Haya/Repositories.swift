//
//  Repositories.swift
//  Haya
//
//  Created by Haya almousa on 19/04/2026.
//

import SwiftData
import Foundation

struct SessionStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func savedAppleUserIdentifier() -> String? {
        defaults.string(forKey: AppConfiguration.appleUserIdentifierKey)
    }

    func saveAppleUserIdentifier(_ identifier: String) {
        defaults.set(identifier, forKey: AppConfiguration.appleUserIdentifierKey)
    }
}

struct ProfileRepository {
    let modelContext: ModelContext

    func insert(_ profile: Profile) {
        modelContext.insert(profile)
    }

    func delete(_ profile: Profile) {
        modelContext.delete(profile)
    }

    func insertGarment(_ garment: Garment, for profile: Profile) {
        profile.updatedAt = .now
        modelContext.insert(garment)
    }

    func insertOutfit(_ outfit: Outfit, for profile: Profile) {
        profile.updatedAt = .now
        modelContext.insert(outfit)
    }
}
