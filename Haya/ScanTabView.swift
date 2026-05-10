//
//  ScanTabView.swift
//  Haya
//
//  Created by Haya almousa on 19/04/2026.
//

import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct ScanTabView: View {
    let profile: Profile

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            GarmentComposerView(profile: profile, style: .scan)

            if let latestGarment = profile.garments.sorted(by: { $0.createdAt > $1.createdAt }).first {
                TallaCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("آخر قطعة مضافة")
                            .font(.system(size: 24, weight: .semibold, design: .serif))
                        GarmentImageView(garment: latestGarment, height: 240)
                        Text(latestGarment.title)
                            .font(.headline)
                        Text("\(latestGarment.category.rawValue) • \(latestGarment.colorName)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private struct GarmentComposerView: View {
    @Environment(\.modelContext) private var modelContext

    let profile: Profile
    @StateObject private var viewModel: ScanComposerViewModel

    private var profileRepository: ProfileRepository {
        ProfileRepository(modelContext: modelContext)
    }

    init(profile: Profile, style: ComposerStyle) {
        self.profile = profile
        _viewModel = StateObject(wrappedValue: ScanComposerViewModel(style: style))
    }

    var body: some View {
        let hasSelectedImage = viewModel.garmentImageData != nil

        TallaCard {
            VStack(alignment: .leading, spacing: 18) {
                Text(viewModel.style.title)
                    .font(.system(size: 28, weight: .semibold, design: .serif))

                Text("أضيفي القطع اللي عندك فعلًا. كل قطعة تحفظينها هنا بتظهر في الدولاب والتنسيق والتصويت.")
                    .foregroundStyle(.secondary)

                GarmentImageUploadView(imageData: viewModel.garmentImageData)

                PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                    Text(hasSelectedImage ? "تغيير صورة القطعة" : "ارفعي صورة القطعة")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TallaPrimaryButtonStyle())

                if viewModel.style == .scan {
                    categoryChips
                }

                TextField("اسم القطعة، مثل: بلوزة بيضاء", text: $viewModel.garmentTitle)
                    .textFieldStyle(.roundedBorder)
                TextField("لون القطعة", text: $viewModel.garmentColor)
                    .textFieldStyle(.roundedBorder)
                TextField("ملاحظات اختيارية، مثل: تناسب الدوام", text: $viewModel.garmentNotes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Picker("الموسم", selection: $viewModel.selectedSeason) {
                        ForEach(Season.allCases) { season in
                            Text(season.rawValue).tag(season)
                        }
                    }

                    Picker("المناسبة", selection: $viewModel.selectedOccasion) {
                        ForEach(Occasion.allCases) { occasion in
                            Text(occasion.rawValue).tag(occasion)
                        }
                    }
                }
                .pickerStyle(.menu)

                if !viewModel.validationMessage.isEmpty {
                    Text(viewModel.validationMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button("احفظيها في دولابي") {
                    saveGarment()
                }
                .buttonStyle(TallaPrimaryButtonStyle())
            }
        }
        .task(id: viewModel.selectedPhotoItem) {
            await viewModel.handleSelectedPhotoChange()
        }
    }

    private var categoryChips: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(ClothingCategory.allCases) { category in
                Button {
                    viewModel.selectedCategory = category
                } label: {
                    Text(category.chipLabel)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(viewModel.selectedCategory == category ? Color.tallaSoft : Color(.systemGray6))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func saveGarment() {
        guard let garment = viewModel.buildGarment(for: profile) else { return }
        profileRepository.insertGarment(garment, for: profile)
        viewModel.reset()
    }
}

private struct GarmentImageUploadView: View {
    let imageData: Data?

    var body: some View {
        Group {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color.black.opacity(0.82), Color.gray.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    VStack(spacing: 10) {
                        Image(systemName: "camera")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                        Text("ارفعي صورة واضحة للقطعة")
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct GarmentFeatureCard: View {
    let title: String
    let garment: Garment
    let accentColor: Color

    var body: some View {
        TallaCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                GarmentImageView(garment: garment, height: 240)
                Text(garment.title)
                    .font(.headline)
                Text(garment.colorName)
                    .foregroundStyle(.secondary)
            }
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(.white)
                    .frame(width: 34, height: 34)
                    .overlay {
                        Image(systemName: "heart")
                            .foregroundStyle(accentColor)
                    }
                    .padding(10)
            }
        }
    }
}

struct GarmentImageView: View {
    let garment: Garment
    let height: CGFloat

    var body: some View {
        Group {
            if let imageData = garment.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color(.systemGray6)
                    VStack(spacing: 10) {
                        Image(systemName: garment.category.systemImage)
                            .font(.system(size: 28))
                        Text(garment.category.rawValue)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
