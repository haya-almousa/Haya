//
//  DesignSystem.swift
//  Haya
//
//  Created by Haya almousa on 19/04/2026.
//

import SwiftUI

struct TallaCard<Content: View>: View {
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

struct FlowTagGroup: View {
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

struct TallaPrimaryButtonStyle: ButtonStyle {
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

enum TallaPalette {
    static func color(for name: String) -> Color {
        switch name {
        case "عاجي": return Color(red: 0.96, green: 0.93, blue: 0.87)
        case "بيج دافئ": return Color(red: 0.87, green: 0.80, blue: 0.69)
        case "زيتوني": return Color(red: 0.62, green: 0.66, blue: 0.49)
        case "ذهبي": return Color(red: 0.83, green: 0.70, blue: 0.40)
        case "خوخي": return Color(red: 0.88, green: 0.65, blue: 0.58)
        case "بني كراميل": return Color(red: 0.55, green: 0.38, blue: 0.26)
        case "أبيض ناصع": return Color(red: 0.98, green: 0.98, blue: 0.98)
        case "أزرق ملكي": return Color(red: 0.29, green: 0.38, blue: 0.68)
        case "وردي بارد": return Color(red: 0.89, green: 0.72, blue: 0.78)
        case "بنفسجي مزرق": return Color(red: 0.77, green: 0.70, blue: 0.88)
        case "فضي": return Color(red: 0.82, green: 0.82, blue: 0.82)
        case "عنابي": return Color(red: 0.47, green: 0.18, blue: 0.23)
        case "أوف وايت": return Color(red: 0.95, green: 0.93, blue: 0.90)
        case "رمادي ناعم": return Color(red: 0.82, green: 0.82, blue: 0.84)
        case "كحلي": return Color(red: 0.29, green: 0.36, blue: 0.48)
        case "وردي غباري": return Color(red: 0.85, green: 0.68, blue: 0.68)
        case "أخضر ساج": return Color(red: 0.67, green: 0.76, blue: 0.72)
        case "توبي": return Color(red: 0.52, green: 0.47, blue: 0.43)
        default: return .gray.opacity(0.4)
        }
    }

    static func hex(for name: String) -> String {
        switch name {
        case "عاجي": return "#F5EEDC"
        case "بيج دافئ": return "#DDCCB0"
        case "زيتوني": return "#9DA87C"
        case "ذهبي": return "#D4B266"
        case "خوخي": return "#E1A392"
        case "بني كراميل": return "#8C6142"
        case "أبيض ناصع": return "#FAFAFA"
        case "أزرق ملكي": return "#4A61AD"
        case "وردي بارد": return "#E2B8C8"
        case "بنفسجي مزرق": return "#C4B3E0"
        case "فضي": return "#D1D1D1"
        case "عنابي": return "#782D39"
        case "أوف وايت": return "#F2EDE6"
        case "رمادي ناعم": return "#D1D1D6"
        case "كحلي": return "#4A5D7A"
        case "وردي غباري": return "#D9AEAE"
        case "أخضر ساج": return "#ABC2B7"
        case "توبي": return "#85786E"
        default: return "#CCCCCC"
        }
    }
}

extension Color {
    static let tallaBackground = Color(red: 0.97, green: 0.96, blue: 0.94)
    static let tallaInk = Color(red: 0.16, green: 0.16, blue: 0.15)
    static let tallaSoft = Color(red: 0.93, green: 0.89, blue: 0.84)
    static let tallaTaupe = Color(red: 0.58, green: 0.52, blue: 0.46)
    static let tallaBlush = Color(red: 0.79, green: 0.63, blue: 0.62)
    static let tallaSage = Color(red: 0.65, green: 0.72, blue: 0.66)
}

extension BodyShape {
    var symbol: String {
        switch self {
        case .hourglass: return "⌛"
        case .pear: return "◔"
        case .apple: return "◕"
        case .rectangle: return "▯"
        case .invertedTriangle: return "▽"
        case .balanced: return "◌"
        }
    }

    var recommendedFocus: [String] {
        switch self {
        case .hourglass: return ["لفات خصر", "خصر عالٍ", "أحزمة"]
        case .pear: return ["أكتاف محددة", "تنانير ناعمة", "ياقات لافتة"]
        case .apple: return ["فتحات رقبة مفتوحة", "طبقات انسيابية", "خطوط طويلة"]
        case .rectangle: return ["خصر محدد", "طبقات", "أقمشة غنية"]
        case .invertedTriangle: return ["حجم بالأسفل", "توبات هادئة", "قصات A"]
        case .balanced: return ["قصات مرنة", "تفصيل خفيف", "تحديد ناعم"]
        }
    }

    var avoidConstruction: [String] {
        switch self {
        case .hourglass: return ["قصات مربعة واسعة", "خصر منخفض", "أقمشة ثقيلة وصلبة"]
        case .pear: return ["جيوب كبيرة عند الأرداف", "طبقات سفلية ثقيلة", "تنانير تلتصق بالجسم"]
        case .apple: return ["قصات ضيقة عند البطن", "أطوال قصيرة جدًا", "خياطات قاسية عند الخصر"]
        case .rectangle: return ["قصات مستقيمة بلا شكل", "فساتين بلا خصر", "طبقات مستقيمة بالكامل"]
        case .invertedTriangle: return ["أكتاف مبالغ فيها", "أكمام ضخمة", "قصات تضيق الأرداف"]
        case .balanced: return ["تفصيل مبالغ", "حجم زائد", "خطوط تباين مشتتة"]
        }
    }

    var avoidDetails: [String] {
        switch self {
        case .hourglass: return ["ياقات عالية جدًا", "كشاكش كثيفة عند الصدر", "طبعات صغيرة مزدحمة"]
        case .pear: return ["زخرفة كثيفة عند الأرداف", "خصر منخفض", "تفاصيل كثيرة عند الحافة"]
        case .apple: return ["أحزمة ضيقة", "ثنيات ثقيلة بالمنتصف", "أطوال حادة وقصيرة"]
        case .rectangle: return ["جيوب مستقيمة جدًا", "تنسيق بلا تباين", "سقطة قماش جامدة"]
        case .invertedTriangle: return ["تفاصيل أكتاف قوية", "ياقات قارب كثيرة", "لمعة زائدة بالأعلى"]
        case .balanced: return ["ياقات مزدحمة بالإكسسوارات", "نسب حادة", "تقسيمات بصرية قاسية"]
        }
    }
}

extension ClothingCategory {
    var chipLabel: String {
        switch self {
        case .top: return "علوي"
        case .pants: return "سفلي"
        case .skirt: return "تنورة"
        case .dress: return "فستان"
        case .abaya: return "عباية"
        case .outerwear: return "خارجي"
        }
    }
}

extension Profile {
    var seasonTitle: String {
        switch undertone {
        case .warm: return "خريف دافئ"
        case .cool: return "صيف بارد"
        case .neutral: return "حيادي ناعم"
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
