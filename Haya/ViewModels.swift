//
//  ViewModels.swift
//  Haya
//
//  Created by Haya almousa on 19/04/2026.
//

import Combine
import Foundation
import PhotosUI
import SwiftData
import SwiftUI

enum MeasurementUnit: String, CaseIterable, Identifiable {
    case inches = "إنش"
    case centimeters = "سم"

    var id: String { rawValue }

    var displayName: String { rawValue }

    func toCentimeters(_ value: Double) -> Double {
        switch self {
        case .inches:
            return value * 2.54
        case .centimeters:
            return value
        }
    }

    func fromCentimeters(_ value: Double) -> Double {
        switch self {
        case .inches:
            return value / 2.54
        case .centimeters:
            return value
        }
    }

    var sliderRange: ClosedRange<Double> {
        switch self {
        case .inches:
            return 20...70
        case .centimeters:
            return 50...180
        }
    }

    var shortLabel: String {
        switch self {
        case .inches:
            return "إنش"
        case .centimeters:
            return "سم"
        }
    }
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var draft = ProfileDraft()
    @Published var validationMessage = ""
    @Published var showPaywall = false
    @Published var selectedUnit: MeasurementUnit = .inches

    private var pendingProfileCreation = false

    func handleCalculateTapped(isUnlocked: Bool) -> Profile? {
        if isUnlocked {
            return buildProfile()
        }

        pendingProfileCreation = true
        showPaywall = true
        return nil
    }

    func handlePurchaseUnlocked() -> Profile? {
        guard pendingProfileCreation else { return nil }
        pendingProfileCreation = false
        showPaywall = false
        return buildProfile()
    }

    func dismissPaywall() {
        showPaywall = false
        pendingProfileCreation = false
    }

    func reset() {
        draft.reset()
        validationMessage = ""
        pendingProfileCreation = false
        showPaywall = false
    }

    func measurementBinding(for keyPath: WritableKeyPath<ProfileDraft, Double>) -> Binding<Double> {
        Binding(
            get: {
                self.selectedUnit.fromCentimeters(self.draft[keyPath: keyPath])
            },
            set: { newValue in
                self.draft[keyPath: keyPath] = self.selectedUnit.toCentimeters(newValue)
            }
        )
    }

    private func buildProfile() -> Profile? {
        guard
            draft.shoulderWidth > 0,
            draft.bust > 0,
            draft.waist > 0,
            draft.hips > 0
        else {
            validationMessage = "راجعي القياسات، لازم تكون الأرقام صحيحة قبل التحليل."
            return nil
        }

        let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.isEmpty ? "حسابي" : trimmedName
        let detectedShape = ProfileAnalyzer.detectBodyShape(
            shoulders: draft.shoulderWidth,
            bust: draft.bust,
            waist: draft.waist,
            hips: draft.hips
        )

        validationMessage = ""

        return Profile(
            name: finalName,
            shoulderWidth: draft.shoulderWidth,
            bust: draft.bust,
            waist: draft.waist,
            hips: draft.hips,
            bodyShape: detectedShape,
            undertone: draft.selectedUndertone,
            recommendedColors: draft.selectedUndertone.recommendedColors
        )
    }
}

@MainActor
final class ScanComposerViewModel: ObservableObject {
    @Published var garmentTitle = ""
    @Published var garmentColor = ""
    @Published var garmentNotes = ""
    @Published var garmentImageData: Data?
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var selectedCategory: ClothingCategory = .top
    @Published var selectedSeason: Season = .allYear
    @Published var selectedOccasion: Occasion = .daily
    @Published var validationMessage = ""

    let style: ComposerStyle

    init(style: ComposerStyle) {
        self.style = style
    }

    func handleSelectedPhotoChange() async {
        guard let selectedPhotoItem else { return }

        do {
            if let data = try await selectedPhotoItem.loadTransferable(type: Data.self) {
                garmentImageData = data
                validationMessage = ""
            }
        } catch {
            validationMessage = "ما قدرنا نحمّل الصورة. جرّبي صورة ثانية."
        }
    }

    func buildGarment(for profile: Profile) -> Garment? {
        let trimmedTitle = garmentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedColor = garmentColor.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty, !trimmedColor.isEmpty else {
            validationMessage = "اكتبي اسم القطعة ولونها عشان نحفظها في دولابك."
            return nil
        }

        validationMessage = ""

        return Garment(
            title: trimmedTitle,
            category: selectedCategory,
            colorName: trimmedColor,
            season: selectedSeason,
            occasion: selectedOccasion,
            notes: garmentNotes.trimmingCharacters(in: .whitespacesAndNewlines),
            imageData: garmentImageData,
            profile: profile
        )
    }

    func reset() {
        garmentTitle = ""
        garmentColor = ""
        garmentNotes = ""
        garmentImageData = nil
        selectedPhotoItem = nil
        selectedCategory = .top
        selectedSeason = .allYear
        selectedOccasion = .daily
        validationMessage = ""
    }
}

@MainActor
final class ClosetStylingViewModel: ObservableObject {
    @Published var outfitName = ""
    @Published var selectedMode: OutfitMode = .separates
    @Published private var topIndex = 0
    @Published private var bottomIndex = 0
    @Published private var onePieceIndex = 0
    @Published var validationMessage = ""

    enum OutfitMode: String, CaseIterable, Identifiable {
        case separates
        case onePiece

        var id: String { rawValue }

        var title: String {
            switch self {
            case .separates:
                return "قطعتين"
            case .onePiece:
                return "فستان/عباية"
            }
        }
    }

    var topGarments: [Garment] = []
    var bottomGarments: [Garment] = []
    var onePieceGarments: [Garment] = []

    func refresh(from garments: [Garment]) {
        topGarments = garments
            .filter { $0.category.isTop }
            .sorted { $0.createdAt > $1.createdAt }
        bottomGarments = garments
            .filter { $0.category.isBottom }
            .sorted { $0.createdAt > $1.createdAt }
        onePieceGarments = garments
            .filter { $0.category.isOnePiece }
            .sorted { $0.createdAt > $1.createdAt }

        if onePieceGarments.isEmpty {
            selectedMode = .separates
        }

        topIndex = normalizedIndex(topIndex, count: topGarments.count)
        bottomIndex = normalizedIndex(bottomIndex, count: bottomGarments.count)
        onePieceIndex = normalizedIndex(onePieceIndex, count: onePieceGarments.count)
    }

    var selectedTopGarment: Garment? {
        guard topGarments.indices.contains(topIndex) else { return nil }
        return topGarments[topIndex]
    }

    var selectedBottomGarment: Garment? {
        guard bottomGarments.indices.contains(bottomIndex) else { return nil }
        return bottomGarments[bottomIndex]
    }

    var selectedOnePieceGarment: Garment? {
        guard onePieceGarments.indices.contains(onePieceIndex) else { return nil }
        return onePieceGarments[onePieceIndex]
    }

    var canSave: Bool {
        switch selectedMode {
        case .separates:
            return selectedTopGarment != nil && selectedBottomGarment != nil
        case .onePiece:
            return selectedOnePieceGarment != nil
        }
    }

    func moveTop(by offset: Int) {
        topIndex = wrappedIndex(topIndex, offset: offset, count: topGarments.count)
    }

    func moveBottom(by offset: Int) {
        bottomIndex = wrappedIndex(bottomIndex, offset: offset, count: bottomGarments.count)
    }

    func moveOnePiece(by offset: Int) {
        onePieceIndex = wrappedIndex(onePieceIndex, offset: offset, count: onePieceGarments.count)
    }

    func buildOutfit(for profile: Profile) -> Outfit? {
        let trimmedName = outfitName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.isEmpty ? "إطلالة محفوظة" : trimmedName

        switch selectedMode {
        case .separates:
            guard let top = selectedTopGarment, let bottom = selectedBottomGarment else {
                validationMessage = "اختاري قطعة علوية وقطعة سفلية قبل الحفظ."
                return nil
            }

            validationMessage = ""
            return Outfit(
                name: finalName,
                profile: profile,
                topGarment: top,
                bottomGarment: bottom
            )
        case .onePiece:
            guard let onePiece = selectedOnePieceGarment else {
                validationMessage = "اختاري فستان أو عباية قبل الحفظ."
                return nil
            }

            validationMessage = ""
            return Outfit(
                name: finalName,
                profile: profile,
                onePieceGarment: onePiece
            )
        }
    }

    func resetComposer() {
        outfitName = ""
        validationMessage = ""
    }

    private func normalizedIndex(_ index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return min(index, count - 1)
    }

    private func wrappedIndex(_ current: Int, offset: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return (current + offset + count) % count
    }
}
