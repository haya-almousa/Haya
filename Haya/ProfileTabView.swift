//
//  ProfileTabView.swift
//  Haya
//
//  Created by Haya almousa on 19/04/2026.
//

import SwiftUI

struct ProfileTabView: View {
    let profile: Profile
    let onReset: (Profile) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("ستايلك الشخصي")
                    .font(.system(size: 32, weight: .semibold, design: .serif))
                Text("هنا تحفظين شكل جسمك، ألوانك المناسبة، والنصائح اللي تساعدك تختارين القطع بثقة.")
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

                Text("نوع الجسم")
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
                Text("ألوان تناسبك")
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
                Text("هذه القياسات اللي استخدمناها في تحليل شكل جسمك. تقدرين تعيدين التحليل إذا تغيرت قياساتك.")
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
                Label("انتبهي لهذه التفاصيل", systemImage: "exclamationmark.circle")
                    .font(.system(size: 26, weight: .semibold, design: .serif))

                Text("مو قواعد صارمة، لكنها ملاحظات تساعدك تختارين قطع أسهل في التنسيق مع جسمك وألوانك.")
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
