//
//  ClosetTabView.swift
//  Haya
//
//  Created by Haya almousa on 19/04/2026.
//

import SwiftUI
import SwiftData

struct ClosetTabView: View {
    @Environment(\.modelContext) private var modelContext

    let profile: Profile
    @StateObject private var stylingViewModel = ClosetStylingViewModel()

    private var profileRepository: ProfileRepository {
        ProfileRepository(modelContext: modelContext)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("دولابك الذكي")
                    .font(.system(size: 32, weight: .semibold, design: .serif))
                Text("جرّبي القطع مع بعض واحفظي الإطلالات اللي تنفعك للمناسبات والطلعات.")
                    .foregroundStyle(.secondary)
            }

            if profile.garments.isEmpty {
                TallaCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ابدئي بأول قطعة")
                            .font(.system(size: 24, weight: .semibold, design: .serif))
                        Text("صوري بلوزة، بنطلون، فستان أو عباية من تبويب الإضافة. بعدها تقدرين تخلطين القطع وتشوفين تنسيقات جاهزة.")
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                mixAndMatchCard

                TallaCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("دولابك الرقمي")
                                .font(.system(size: 24, weight: .semibold, design: .serif))
                            Spacer()
                            Text("\(profile.garments.count) قطعة")
                                .foregroundStyle(.secondary)
                        }

                        ForEach(profile.garments.sorted(by: { $0.createdAt > $1.createdAt })) { garment in
                            HStack(spacing: 12) {
                                GarmentImageView(garment: garment, height: 84)
                                    .frame(width: 72)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(garment.title)
                                        .font(.headline)
                                    Text("\(garment.category.rawValue) • \(garment.colorName)")
                                        .foregroundStyle(.secondary)
                                    Text("\(garment.season.rawValue) • \(garment.occasion.rawValue)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }

                savedOutfitsCard
            }
        }
        .onAppear {
            stylingViewModel.refresh(from: profile.garments)
        }
        .onChange(of: profile.garments.count) { _, _ in
            stylingViewModel.refresh(from: profile.garments)
        }
    }

    private var mixAndMatchCard: some View {
        TallaCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("جرّبي التنسيق")
                        .font(.system(size: 26, weight: .semibold, design: .serif))
                    Spacer()
                    if !stylingViewModel.onePieceGarments.isEmpty {
                        Picker("الوضع", selection: $stylingViewModel.selectedMode) {
                            ForEach(ClosetStylingViewModel.OutfitMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 220)
                    }
                }

                TextField("اسم الإطلالة، مثل: عشاء عائلي", text: $stylingViewModel.outfitName)
                    .textFieldStyle(.roundedBorder)

                if stylingViewModel.selectedMode == .separates {
                    if let top = stylingViewModel.selectedTopGarment {
                        garmentSelectorCard(
                            title: "القطعة العلوية",
                            garment: top,
                            accentColor: .tallaBlush,
                            previousAction: { stylingViewModel.moveTop(by: -1) },
                            nextAction: { stylingViewModel.moveTop(by: 1) }
                        )
                    }

                    if let bottom = stylingViewModel.selectedBottomGarment {
                        garmentSelectorCard(
                            title: "القطعة السفلية",
                            garment: bottom,
                            accentColor: .tallaSage,
                            previousAction: { stylingViewModel.moveBottom(by: -1) },
                            nextAction: { stylingViewModel.moveBottom(by: 1) }
                        )
                    }
                } else if let onePiece = stylingViewModel.selectedOnePieceGarment {
                    garmentSelectorCard(
                        title: "القطعة الكاملة",
                        garment: onePiece,
                        accentColor: .tallaTaupe,
                        previousAction: { stylingViewModel.moveOnePiece(by: -1) },
                        nextAction: { stylingViewModel.moveOnePiece(by: 1) }
                    )
                }

                if !stylingViewModel.validationMessage.isEmpty {
                    Text(stylingViewModel.validationMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button("احفظي الإطلالة") {
                    saveOutfit()
                }
                .buttonStyle(TallaPrimaryButtonStyle())
                .disabled(!stylingViewModel.canSave)
            }
        }
    }

    private var savedOutfitsCard: some View {
        TallaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("إطلالاتك الجاهزة")
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                    Spacer()
                    Text("\(profile.outfits.count) محفوظة")
                        .foregroundStyle(.secondary)
                }

                if profile.outfits.isEmpty {
                    Text("احفظي التنسيقات اللي تعجبك عشان ترجعين لها وقت المناسبة بدون حيرة.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(profile.outfits.sorted(by: { $0.createdAt > $1.createdAt })) { outfit in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(outfit.name)
                                .font(.headline)
                            Text(outfitSummary(outfit))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private func garmentSelectorCard(
        title: String,
        garment: Garment,
        accentColor: Color,
        previousAction: @escaping () -> Void,
        nextAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                arrowButton(systemImage: "chevron.right", action: previousAction)

                GarmentFeatureCard(title: title, garment: garment, accentColor: accentColor)

                arrowButton(systemImage: "chevron.left", action: nextAction)
            }
        }
    }

    private func arrowButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color.white))
        }
        .buttonStyle(.plain)
    }

    private func outfitSummary(_ outfit: Outfit) -> String {
        if let onePiece = outfit.onePieceGarment {
            return "\(onePiece.title) • \(onePiece.colorName)"
        }

        let top = outfit.topGarment?.title ?? "قطعة علوية"
        let bottom = outfit.bottomGarment?.title ?? "قطعة سفلية"
        return "\(top) + \(bottom)"
    }

    private func saveOutfit() {
        guard let outfit = stylingViewModel.buildOutfit(for: profile) else { return }
        profileRepository.insertOutfit(outfit, for: profile)
        stylingViewModel.resetComposer()
    }
}
