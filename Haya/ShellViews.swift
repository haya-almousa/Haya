//
//  ShellViews.swift
//  Haya
//
//  Created by Haya almousa on 19/04/2026.
//

import SwiftUI

struct AppShellView: View {
    let profile: Profile
    let userIdentifier: String
    let onReset: (Profile) -> Void

    @State private var selectedTab: AppTab = .profile

    var body: some View {
        VStack(spacing: 0) {
            HayaTopBar(profile: profile)

            ScrollView(showsIndicators: false) {
                currentScreen
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 120)
            }

            HayaTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
                .background(
                    LinearGradient(
                        colors: [Color.tallaBackground.opacity(0.0), Color.tallaBackground],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch selectedTab {
        case .closet:
            ClosetTabView(profile: profile)
        case .scan:
            ScanTabView(profile: profile)
        case .vote:
            VoteTabView(profile: profile, userIdentifier: userIdentifier)
        case .profile:
            ProfileTabView(profile: profile, onReset: onReset)
        }
    }
}

private struct HayaTopBar: View {
    let profile: Profile

    var body: some View {
        HStack {
            Image(systemName: "line.3.horizontal")
                .font(.headline)

            Spacer()

            Text(AppConfiguration.appName)
                .font(.system(size: 30, weight: .semibold, design: .serif))
                .tracking(1)

            Spacer()

            ZStack {
                Circle()
                    .fill(Color.tallaInk)
                    .frame(width: 34, height: 34)
                Text(profileInitials)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .background(Color.tallaBackground)
    }

    private var profileInitials: String {
        let words = profile.name.split(separator: " ")
        let letters = words.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}

private struct HayaTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 18, weight: .semibold))
                        Text(tab.label)
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(selectedTab == tab ? Color.tallaInk : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
}
