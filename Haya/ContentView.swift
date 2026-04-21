//
//  ContentView.swift
//  Haya
//
//  Created by Haya almousa on 19/04/2026.
//

import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Profile.updatedAt, order: .reverse) private var profiles: [Profile]

    @State private var name = ""
    @State private var shoulderWidth = ""
    @State private var bust = ""
    @State private var waist = ""
    @State private var hips = ""
    @State private var selectedUndertone: Undertone = .neutral
    @State private var validationMessage = ""

    private var activeProfile: Profile? {
        profiles.first
    }

    var body: some View {
        ZStack {
            Color.tallaBackground
                .ignoresSafeArea()

            if let profile = activeProfile {
                AppShellView(profile: profile, onReset: deleteProfile)
            } else {
                onboardingView
            }
        }
    }

    private var onboardingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Haya")
                    .font(.system(size: 34, weight: .semibold, design: .serif))
                    .tracking(1)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 18)

                VStack(alignment: .leading, spacing: 10) {
                    Text("قياساتك وأناقتك")
                        .font(.system(size: 32, weight: .semibold, design: .serif))
                    Text("أدخلي قياساتك للحصول على توصيات تناسب شكل جسمك وألوانك.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 18) {
                    TextField("اسم البروفايل", text: $name)
                        .textFieldStyle(.roundedBorder)

                    measurementField(title: "الأكتاف", value: $shoulderWidth)
                    measurementField(title: "الصدر", value: $bust)
                    measurementField(title: "الخصر", value: $waist)
                    measurementField(title: "الأرداف", value: $hips)

                    Picker("الأندرتون", selection: $selectedUndertone) {
                        ForEach(Undertone.allCases) { tone in
                            Text(tone.rawValue).tag(tone)
                        }
                    }
                    .pickerStyle(.segmented)

                    if !validationMessage.isEmpty {
                        Text(validationMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button("احسبي نوع جسمي") {
                        saveProfile()
                    }
                    .buttonStyle(TallaPrimaryButtonStyle())
                }
                .padding(22)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.white.opacity(0.94))
                )
            }
            .padding(20)
        }
    }

    private func measurementField(title: String, value: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField("سم", text: value)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func saveProfile() {
        guard
            let shoulderValue = Double(shoulderWidth),
            let bustValue = Double(bust),
            let waistValue = Double(waist),
            let hipsValue = Double(hips),
            shoulderValue > 0,
            bustValue > 0,
            waistValue > 0,
            hipsValue > 0
        else {
            validationMessage = "أدخلي قياسات صحيحة أولًا."
            return
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.isEmpty ? "بروفايلي" : trimmedName
        let detectedShape = ProfileAnalyzer.detectBodyShape(
            shoulders: shoulderValue,
            bust: bustValue,
            waist: waistValue,
            hips: hipsValue
        )

        let profile = Profile(
            name: finalName,
            shoulderWidth: shoulderValue,
            bust: bustValue,
            waist: waistValue,
            hips: hipsValue,
            bodyShape: detectedShape,
            undertone: selectedUndertone,
            recommendedColors: selectedUndertone.recommendedColors
        )

        modelContext.insert(profile)
        validationMessage = ""
    }

    private func deleteProfile(_ profile: Profile) {
        modelContext.delete(profile)
        name = ""
        shoulderWidth = ""
        bust = ""
        waist = ""
        hips = ""
        selectedUndertone = .neutral
    }
}

private struct AppShellView: View {
    let profile: Profile
    let onReset: (Profile) -> Void

    @State private var selectedTab: AppTab = .profile

    var body: some View {
        VStack(spacing: 0) {
            TallaTopBar(profile: profile)

            ScrollView(showsIndicators: false) {
                currentScreen
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 120)
            }

            TallaTabBar(selectedTab: $selectedTab)
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
            ClosetHomeView(profile: profile)
        case .scan:
            ScanStudioView(profile: profile)
        case .vote:
            VoteChallengeView(profile: profile)
        case .profile:
            ProfileStudioView(profile: profile, onReset: onReset)
        }
    }
}

private struct TallaTopBar: View {
    let profile: Profile

    var body: some View {
        HStack {
            Image(systemName: "line.3.horizontal")
                .font(.headline)

            Spacer()

            Text("Haya")
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

private struct TallaTabBar: View {
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

private struct ProfileStudioView: View {
    let profile: Profile
    let onReset: (Profile) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("حمضك الأنيق")
                    .font(.system(size: 32, weight: .semibold, design: .serif))
                Text("تحليل منسق لشكل جسمك والأندرتون لديك ليساعدك في بناء دولاب يناسبك.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            styleCard
            undertoneCard
            paletteCard
            measurementsCard
            consciousStylingCard

            Button("إعادة ضبط البروفايل") {
                onReset(profile)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
        }
    }

    private var styleCard: some View {
        TallaCard {
            VStack(alignment: .leading, spacing: 18) {
                Circle()
                    .fill(Color.tallaSoft.opacity(0.5))
                    .frame(width: 88, height: 88)
                    .overlay {
                        Text(profile.bodyShape.symbol)
                            .font(.system(size: 34, weight: .light, design: .serif))
                            .foregroundStyle(Color.tallaTaupe)
                    }
                    .frame(maxWidth: .infinity)

                Text(profile.bodyShape.rawValue)
                    .font(.system(size: 30, weight: .semibold, design: .serif))
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("شكل الجسم")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                Divider()

                Text(profile.bodyShape.styleNote)
                    .font(.body)
                    .foregroundStyle(.secondary)

                FlowTagGroup(tags: profile.bodyShape.recommendedFocus)
            }
        }
    }

    private var undertoneCard: some View {
        TallaCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    ForEach(profile.undertoneSwatches, id: \.self) { swatch in
                        Circle()
                            .fill(swatch)
                            .frame(width: 44, height: 44)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                Text(profile.seasonTitle)
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("الأندرتون: \(profile.undertone.rawValue)")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                Divider()

                Text(profile.undertoneDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)

                HStack(spacing: 14) {
                    ForEach(profile.recommendedColors.prefix(3), id: \.self) { color in
                        VStack(spacing: 6) {
                            Circle()
                                .fill(TallaPalette.color(for: color))
                                .frame(width: 34, height: 34)
                            Text(color.uppercased())
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var paletteCard: some View {
        TallaCard {
            VStack(alignment: .leading, spacing: 18) {
                Text("ألوانك المميزة")
                    .font(.system(size: 26, weight: .semibold, design: .serif))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(profile.recommendedColors, id: \.self) { colorName in
                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(TallaPalette.color(for: colorName))
                                .frame(height: 132)
                            Text(colorName.uppercased())
                                .font(.footnote.weight(.bold))
                            Text(TallaPalette.hex(for: colorName))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var measurementsCard: some View {
        TallaCard {
            VStack(alignment: .leading, spacing: 18) {
                Text("قياسات جسمك")
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                Text("هذه القياسات المحفوظة التي بُنيت عليها توصيات الشكل والألوان.")
                    .foregroundStyle(.secondary)

                measurementRow(title: "الصدر", value: profile.bust)
                measurementRow(title: "الخصر", value: profile.waist)
                measurementRow(title: "الأرداف", value: profile.hips)
            }
        }
    }

    private var consciousStylingCard: some View {
        TallaCard {
            VStack(alignment: .leading, spacing: 16) {
                Label("تنسيق بوعي", systemImage: "nosign")
                    .font(.system(size: 26, weight: .semibold, design: .serif))

                Text("للحفاظ على توازن \(profile.bodyShape.rawValue) ودرجات \(profile.undertone.rawValue)، انتبهي لهذه العناصر:")
                    .foregroundStyle(.secondary)

                consciousColumn(title: "البناء", items: profile.bodyShape.avoidConstruction)
                consciousColumn(title: "الألوان", items: profile.undertoneColorsToAvoid)
                consciousColumn(title: "التفاصيل", items: profile.bodyShape.avoidDetails)
            }
        }
    }

    private func measurementRow(title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(value)) سم")
                    .font(.headline)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.tallaSoft)
                        .frame(height: 4)
                    Circle()
                        .fill(Color.tallaInk)
                        .frame(width: 12, height: 12)
                        .offset(x: markerOffset(width: geometry.size.width, value: value))
                }
            }
            .frame(height: 12)
        }
    }

    private func consciousColumn(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            ForEach(items, id: \.self) { item in
                Text("• \(item)")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func markerOffset(width: CGFloat, value: Double) -> CGFloat {
        let normalized = min(max(value / 120.0, 0), 1)
        return max(width * normalized - 6, 0)
    }
}

private struct ClosetHomeView: View {
    let profile: Profile

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("نسّقي إطلالتك")
                    .font(.system(size: 32, weight: .semibold, design: .serif))
                Text("اختاري من قطعك المحفوظة وجرّبي أكثر من تنسيق داخل دولابك الرقمي.")
                    .foregroundStyle(.secondary)
            }

            if profile.garments.isEmpty {
                TallaCard {
                    Text("دولابك فارغ الآن. أضيفي أول قطعة من تبويب التصوير.")
                        .foregroundStyle(.secondary)
                }
            } else {
                if let topPiece = profile.garments.first(where: { $0.category.isTop }) {
                    GarmentFeatureCard(title: "القطعة العلوية", garment: topPiece, accentColor: .tallaBlush)
                }

                if let bottomPiece = profile.garments.first(where: { $0.category.isBottom || $0.category.isOnePiece }) {
                    GarmentFeatureCard(title: "القطعة السفلية", garment: bottomPiece, accentColor: .tallaSage)
                }

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
            }
        }
    }
}

private struct ScanStudioView: View {
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

private struct VoteChallengeView: View {
    let profile: Profile

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text("تحدي الويكند")
                    .font(.system(size: 30, weight: .semibold, design: .serif))
                Text("موضوع الأسبوع: افتتاح معرض بسيط وأنيق")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 14) {
                VoteOptionCard(
                    title: "الخيار A",
                    garment: profile.garments.first,
                    accentColor: .tallaInk
                )
                VoteOptionCard(
                    title: "الخيار B",
                    garment: profile.garments.dropFirst().first ?? profile.garments.first,
                    accentColor: .tallaTaupe
                )
            }

            TallaCard {
                HStack {
                    statBlock(title: "الوقت المتبقي", value: "14:22:05")
                    Divider()
                    statBlock(title: "إجمالي الأصوات", value: "8.4k")
                }
            }

            TallaCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("لوحة الشرف")
                            .font(.system(size: 28, weight: .semibold, design: .serif))
                        Spacer()
                        Text("عرض الكل")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }

                    leaderboardRow(name: "Elena Rossi", role: "أيقونة الذوق", score: "2,450 نقطة")
                    leaderboardRow(name: "Julian Vance", role: "منسقة الإطلالات", score: "1,920 نقطة")
                    leaderboardRow(name: profile.name, role: "حسابك", score: "1,180 نقطة")
                }
            }
        }
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 30, weight: .medium, design: .serif))
        }
        .frame(maxWidth: .infinity)
    }

    private func leaderboardRow(name: String, role: String, score: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.tallaSoft)
                .frame(width: 42, height: 42)
                .overlay {
                    Text(String(name.prefix(1)))
                        .font(.headline)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.headline)
                Text(role)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(score)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct GarmentComposerView: View {
    @Environment(\.modelContext) private var modelContext

    let profile: Profile
    let style: ComposerStyle

    @State private var garmentTitle = ""
    @State private var garmentColor = ""
    @State private var garmentNotes = ""
    @State private var garmentImageData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedCategory: ClothingCategory = .top
    @State private var selectedSeason: Season = .allYear
    @State private var selectedOccasion: Occasion = .daily
    @State private var validationMessage = ""

    var body: some View {
        TallaCard {
            VStack(alignment: .leading, spacing: 18) {
                Text(style.title)
                    .font(.system(size: 28, weight: .semibold, design: .serif))

                GarmentImageUploadView(imageData: garmentImageData)

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Text(garmentImageData == nil ? "اختاري صورة القطعة" : "تغيير الصورة")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TallaPrimaryButtonStyle())

                if style == .scan {
                    categoryChips
                }

                TextField("اسم القطعة", text: $garmentTitle)
                    .textFieldStyle(.roundedBorder)
                TextField("اللون", text: $garmentColor)
                    .textFieldStyle(.roundedBorder)
                TextField("ملاحظات", text: $garmentNotes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Picker("الموسم", selection: $selectedSeason) {
                        ForEach(Season.allCases) { season in
                            Text(season.rawValue).tag(season)
                        }
                    }

                    Picker("المناسبة", selection: $selectedOccasion) {
                        ForEach(Occasion.allCases) { occasion in
                            Text(occasion.rawValue).tag(occasion)
                        }
                    }
                }
                .pickerStyle(.menu)

                if !validationMessage.isEmpty {
                    Text(validationMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button("حفظ في الدولاب") {
                    saveGarment()
                }
                .buttonStyle(TallaPrimaryButtonStyle())
            }
        }
        .task(id: selectedPhotoItem) {
            await loadSelectedPhoto()
        }
    }

    private var categoryChips: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(ClothingCategory.allCases) { category in
                Button {
                    selectedCategory = category
                } label: {
                    Text(category.chipLabel)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(selectedCategory == category ? Color.tallaSoft : Color(.systemGray6))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func loadSelectedPhoto() async {
        guard let selectedPhotoItem else { return }

        do {
            if let data = try await selectedPhotoItem.loadTransferable(type: Data.self) {
                garmentImageData = data
                if style == .scan {
                    validationMessage = ""
                }
            }
        } catch {
            validationMessage = "تعذر تحميل الصورة المختارة."
        }
    }

    private func saveGarment() {
        let trimmedTitle = garmentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedColor = garmentColor.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty, !trimmedColor.isEmpty else {
            validationMessage = "أدخلي اسم القطعة واللون."
            return
        }

        let garment = Garment(
            title: trimmedTitle,
            category: selectedCategory,
            colorName: trimmedColor,
            season: selectedSeason,
            occasion: selectedOccasion,
            notes: garmentNotes.trimmingCharacters(in: .whitespacesAndNewlines),
            imageData: garmentImageData,
            profile: profile
        )

        profile.updatedAt = .now
        modelContext.insert(garment)

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
                        Text("أضيفي صورتك التالية للدولاب")
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

private struct GarmentFeatureCard: View {
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

private struct VoteOptionCard: View {
    let title: String
    let garment: Garment?
    let accentColor: Color

    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.92))

                if let garment {
                    GarmentImageView(garment: garment, height: 220)
                        .padding(10)
                } else {
                    VStack {
                        Spacer()
                        Image(systemName: "hanger")
                            .font(.system(size: 38))
                            .foregroundStyle(.white.opacity(0.8))
                        Spacer()
                    }
                }

                Text(title)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.95))
                    .clipShape(Capsule(style: .continuous))
                    .padding(10)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Text("صوّتي")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(accentColor)
                )
                .foregroundStyle(.white)
                .font(.headline)
        }
    }
}

private struct GarmentImageView: View {
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

private struct TallaCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white.opacity(0.95))
        )
    }
}

private struct FlowTagGroup: View {
    let tags: [String]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule(style: .continuous).fill(Color(.systemGray6)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private enum AppTab: CaseIterable, Identifiable {
    case closet
    case scan
    case vote
    case profile

    var id: Self { self }

    var label: String {
        switch self {
        case .closet:
            return "الدولاب"
        case .scan:
            return "التصوير"
        case .vote:
            return "التصويت"
        case .profile:
            return "البروفايل"
        }
    }

    var systemImage: String {
        switch self {
        case .closet:
            return "square.grid.2x2"
        case .scan:
            return "camera"
        case .vote:
            return "trophy"
        case .profile:
            return "face.smiling"
        }
    }
}

private enum ComposerStyle {
    case scan

    var title: String {
        switch self {
        case .scan:
            return "صوّري قطعتك"
        }
    }
}

private enum TallaPalette {
    static func color(for name: String) -> Color {
        switch name {
        case "عاجي":
            return Color(red: 0.96, green: 0.93, blue: 0.87)
        case "بيج دافئ":
            return Color(red: 0.87, green: 0.80, blue: 0.69)
        case "زيتوني":
            return Color(red: 0.62, green: 0.66, blue: 0.49)
        case "ذهبي":
            return Color(red: 0.83, green: 0.70, blue: 0.40)
        case "خوخي":
            return Color(red: 0.88, green: 0.65, blue: 0.58)
        case "بني كراميل":
            return Color(red: 0.55, green: 0.38, blue: 0.26)
        case "أبيض ناصع":
            return Color(red: 0.98, green: 0.98, blue: 0.98)
        case "أزرق ملكي":
            return Color(red: 0.29, green: 0.38, blue: 0.68)
        case "وردي بارد":
            return Color(red: 0.89, green: 0.72, blue: 0.78)
        case "بنفسجي مزرق":
            return Color(red: 0.77, green: 0.70, blue: 0.88)
        case "فضي":
            return Color(red: 0.82, green: 0.82, blue: 0.82)
        case "عنابي":
            return Color(red: 0.47, green: 0.18, blue: 0.23)
        case "أوف وايت":
            return Color(red: 0.95, green: 0.93, blue: 0.90)
        case "رمادي ناعم":
            return Color(red: 0.82, green: 0.82, blue: 0.84)
        case "كحلي":
            return Color(red: 0.29, green: 0.36, blue: 0.48)
        case "وردي غباري":
            return Color(red: 0.85, green: 0.68, blue: 0.68)
        case "أخضر ساج":
            return Color(red: 0.67, green: 0.76, blue: 0.72)
        case "توبي":
            return Color(red: 0.52, green: 0.47, blue: 0.43)
        default:
            return .gray.opacity(0.4)
        }
    }

    static func hex(for name: String) -> String {
        switch name {
        case "عاجي":
            return "#F5EEDC"
        case "بيج دافئ":
            return "#DDCCB0"
        case "زيتوني":
            return "#9DA87C"
        case "ذهبي":
            return "#D4B266"
        case "خوخي":
            return "#E1A392"
        case "بني كراميل":
            return "#8C6142"
        case "أبيض ناصع":
            return "#FAFAFA"
        case "أزرق ملكي":
            return "#4A61AD"
        case "وردي بارد":
            return "#E2B8C8"
        case "بنفسجي مزرق":
            return "#C4B3E0"
        case "فضي":
            return "#D1D1D1"
        case "عنابي":
            return "#782D39"
        case "أوف وايت":
            return "#F2EDE6"
        case "رمادي ناعم":
            return "#D1D1D6"
        case "كحلي":
            return "#4A5D7A"
        case "وردي غباري":
            return "#D9AEAE"
        case "أخضر ساج":
            return "#ABC2B7"
        case "توبي":
            return "#85786E"
        default:
            return "#CCCCCC"
        }
    }
}

private struct TallaPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.tallaInk.opacity(configuration.isPressed ? 0.84 : 1))
            )
    }
}

private extension Color {
    static let tallaBackground = Color(red: 0.97, green: 0.96, blue: 0.94)
    static let tallaInk = Color(red: 0.16, green: 0.16, blue: 0.15)
    static let tallaSoft = Color(red: 0.93, green: 0.89, blue: 0.84)
    static let tallaTaupe = Color(red: 0.58, green: 0.52, blue: 0.46)
    static let tallaBlush = Color(red: 0.79, green: 0.63, blue: 0.62)
    static let tallaSage = Color(red: 0.65, green: 0.72, blue: 0.66)
}

private extension BodyShape {
    var symbol: String {
        switch self {
        case .hourglass:
            return "⌛"
        case .pear:
            return "◔"
        case .apple:
            return "◕"
        case .rectangle:
            return "▯"
        case .invertedTriangle:
            return "▽"
        case .balanced:
            return "◌"
        }
    }

    var recommendedFocus: [String] {
        switch self {
        case .hourglass:
            return ["لفات خصر", "خصر عالٍ", "أحزمة"]
        case .pear:
            return ["أكتاف محددة", "تنانير ناعمة", "ياقات لافتة"]
        case .apple:
            return ["فتحات رقبة مفتوحة", "طبقات انسيابية", "خطوط طويلة"]
        case .rectangle:
            return ["خصر محدد", "طبقات", "أقمشة غنية"]
        case .invertedTriangle:
            return ["حجم بالأسفل", "توبات هادئة", "قصات A"]
        case .balanced:
            return ["قصات مرنة", "تفصيل خفيف", "تحديد ناعم"]
        }
    }

    var avoidConstruction: [String] {
        switch self {
        case .hourglass:
            return ["قصات مربعة واسعة", "خصر منخفض", "أقمشة ثقيلة وصلبة"]
        case .pear:
            return ["جيوب كبيرة عند الأرداف", "طبقات سفلية ثقيلة", "تنانير تلتصق بالجسم"]
        case .apple:
            return ["قصات ضيقة عند البطن", "أطوال قصيرة جدًا", "خياطات قاسية عند الخصر"]
        case .rectangle:
            return ["قصات مستقيمة بلا شكل", "فساتين بلا خصر", "طبقات مستقيمة بالكامل"]
        case .invertedTriangle:
            return ["أكتاف مبالغ فيها", "أكمام ضخمة", "قصات تضيق الأرداف"]
        case .balanced:
            return ["تفصيل مبالغ", "حجم زائد", "خطوط تباين مشتتة"]
        }
    }

    var avoidDetails: [String] {
        switch self {
        case .hourglass:
            return ["ياقات عالية جدًا", "كشاكش كثيفة عند الصدر", "طبعات صغيرة مزدحمة"]
        case .pear:
            return ["زخرفة كثيفة عند الأرداف", "خصر منخفض", "تفاصيل كثيرة عند الحافة"]
        case .apple:
            return ["أحزمة ضيقة", "ثنيات ثقيلة بالمنتصف", "أطوال حادة وقصيرة"]
        case .rectangle:
            return ["جيوب مستقيمة جدًا", "تنسيق بلا تباين", "سقطة قماش جامدة"]
        case .invertedTriangle:
            return ["تفاصيل أكتاف قوية", "ياقات قارب كثيرة", "لمعة زائدة بالأعلى"]
        case .balanced:
            return ["ياقات مزدحمة بالإكسسوارات", "نسب حادة", "تقسيمات بصرية قاسية"]
        }
    }
}

private extension ClothingCategory {
    var chipLabel: String {
        switch self {
        case .top:
            return "علوي"
        case .pants:
            return "سفلي"
        case .skirt:
            return "تنورة"
        case .dress:
            return "فستان"
        case .abaya:
            return "عباية"
        case .outerwear:
            return "خارجي"
        }
    }
}

private extension Profile {
    var seasonTitle: String {
        switch undertone {
        case .warm:
            return "خريف دافئ"
        case .cool:
            return "صيف بارد"
        case .neutral:
            return "حيادي ناعم"
        }
    }

    var undertoneDescription: String {
        switch undertone {
        case .warm:
            return "الدرجات الذهبية والخوخية تعطيك انسجامًا واضحًا وإشراقة طبيعية أنيقة."
        case .cool:
            return "الدرجات الوردية الباردة والناعمة تناسبك أكثر، خاصة الألوان ذات القاعدة الزرقاء أو الفضية."
        case .neutral:
            return "أندرتونك المتوازن يعطيك حرية أكبر بين الدرجات الدافئة والباردة الهادئة."
        }
    }

    var undertoneSwatches: [Color] {
        switch undertone {
        case .warm:
            return [Color(red: 0.92, green: 0.84, blue: 0.70), Color(red: 0.88, green: 0.77, blue: 0.60), Color(red: 0.79, green: 0.64, blue: 0.43)]
        case .cool:
            return [Color(red: 0.91, green: 0.86, blue: 0.80), Color(red: 0.95, green: 0.91, blue: 0.88), Color(red: 0.84, green: 0.75, blue: 0.64)]
        case .neutral:
            return [Color(red: 0.89, green: 0.85, blue: 0.80), Color(red: 0.85, green: 0.84, blue: 0.80), Color(red: 0.78, green: 0.76, blue: 0.72)]
        }
    }

    var undertoneColorsToAvoid: [String] {
        switch undertone {
        case .warm:
            return ["بنفسجي أزرق بارد", "رمادي طبشوري بارد", "فوشيا بقاعدة زرقاء"]
        case .cool:
            return ["برتقالي وأصفر نيون", "درجات ترابية موحلة", "أسود حاد جدًا"]
        case .neutral:
            return ["نيون دافئ قوي", "ألوان فلورية باردة جدًا", "ألوان أساسية مشبعة جدًا"]
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Profile.self, Garment.self, Outfit.self], inMemory: true)
}
