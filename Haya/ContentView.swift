//
//  ContentView.swift
//  Haya
//
//  Created by Haya almousa on 19/04/2026.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Profile.updatedAt, order: .reverse) private var profiles: [Profile]

    @StateObject private var sessionManager = SessionManager()
    @StateObject private var purchaseManager = PurchaseManager()
    @StateObject private var onboardingViewModel = OnboardingViewModel()

    private var activeProfile: Profile? {
        profiles.first
    }

    private var profileRepository: ProfileRepository {
        ProfileRepository(modelContext: modelContext)
    }

    var body: some View {
        ZStack {
            Color.tallaBackground
                .ignoresSafeArea()

            if !sessionManager.isSignedIn {
                SignInGateView(sessionManager: sessionManager)
            } else if let profile = activeProfile {
                AppShellView(
                    profile: profile,
                    userIdentifier: sessionManager.userIdentifier,
                    onReset: deleteProfile
                )
            } else {
                ProfileOnboardingView(
                    viewModel: onboardingViewModel,
                    onCalculateTapped: handleCalculateTapped
                )
            }
        }
        .sheet(isPresented: $onboardingViewModel.showPaywall) {
            PaywallView(
                purchaseManager: purchaseManager,
                onClose: onboardingViewModel.dismissPaywall
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: purchaseManager.hasUnlockedBodyAnalysis) { _, unlocked in
            guard unlocked, let profile = onboardingViewModel.handlePurchaseUnlocked() else { return }
            profileRepository.insert(profile)
            onboardingViewModel.reset()
        }
    }

    private func handleCalculateTapped() {
        if let profile = onboardingViewModel.handleCalculateTapped(isUnlocked: purchaseManager.hasUnlockedBodyAnalysis) {
            profileRepository.insert(profile)
            onboardingViewModel.reset()
        }
    }

    private func deleteProfile(_ profile: Profile) {
        profileRepository.delete(profile)
        onboardingViewModel.reset()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Profile.self, Garment.self, Outfit.self], inMemory: true)
}
