//
//  Item.swift
//  Haya
//
//  Created by Haya almousa on 19/04/2026.
//

import Foundation
import SwiftData

@Model
final class Profile {
    var name: String
    var shoulderWidth: Double
    var bust: Double
    var waist: Double
    var hips: Double
    var bodyShapeRaw: String
    var undertoneRaw: String
    var recommendedColors: [String]
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Garment.profile) var garments: [Garment] = []
    @Relationship(deleteRule: .cascade, inverse: \Outfit.profile) var outfits: [Outfit] = []

    init(
        name: String,
        shoulderWidth: Double,
        bust: Double,
        waist: Double,
        hips: Double,
        bodyShape: BodyShape,
        undertone: Undertone,
        recommendedColors: [String],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.name = name
        self.shoulderWidth = shoulderWidth
        self.bust = bust
        self.waist = waist
        self.hips = hips
        self.bodyShapeRaw = bodyShape.rawValue
        self.undertoneRaw = undertone.rawValue
        self.recommendedColors = recommendedColors
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var bodyShape: BodyShape {
        BodyShape(rawValue: bodyShapeRaw) ?? .balanced
    }

    var undertone: Undertone {
        Undertone(rawValue: undertoneRaw) ?? .neutral
    }
}

@Model
final class Garment {
    var title: String
    var categoryRaw: String
    var colorName: String
    var seasonRaw: String
    var occasionRaw: String
    var notes: String
    var imageData: Data?
    var createdAt: Date
    var profile: Profile?
    @Relationship(inverse: \Outfit.topGarment) var usedAsTopInOutfits: [Outfit] = []
    @Relationship(inverse: \Outfit.bottomGarment) var usedAsBottomInOutfits: [Outfit] = []
    @Relationship(inverse: \Outfit.onePieceGarment) var usedAsOnePieceInOutfits: [Outfit] = []

    init(
        title: String,
        category: ClothingCategory,
        colorName: String,
        season: Season,
        occasion: Occasion,
        notes: String = "",
        imageData: Data? = nil,
        createdAt: Date = .now,
        profile: Profile? = nil
    ) {
        self.title = title
        self.categoryRaw = category.rawValue
        self.colorName = colorName
        self.seasonRaw = season.rawValue
        self.occasionRaw = occasion.rawValue
        self.notes = notes
        self.imageData = imageData
        self.createdAt = createdAt
        self.profile = profile
    }

    var category: ClothingCategory {
        ClothingCategory(rawValue: categoryRaw) ?? .top
    }

    var season: Season {
        Season(rawValue: seasonRaw) ?? .allYear
    }

    var occasion: Occasion {
        Occasion(rawValue: occasionRaw) ?? .daily
    }
}

@Model
final class Outfit {
    var name: String
    var notes: String
    var createdAt: Date
    var profile: Profile?
    var topGarment: Garment?
    var bottomGarment: Garment?
    var onePieceGarment: Garment?

    init(
        name: String,
        notes: String = "",
        createdAt: Date = .now,
        profile: Profile? = nil,
        topGarment: Garment? = nil,
        bottomGarment: Garment? = nil,
        onePieceGarment: Garment? = nil
    ) {
        self.name = name
        self.notes = notes
        self.createdAt = createdAt
        self.profile = profile
        self.topGarment = topGarment
        self.bottomGarment = bottomGarment
        self.onePieceGarment = onePieceGarment
    }
}

enum BodyShape: String, CaseIterable, Identifiable {
    case hourglass = "ساعة رملية"
    case pear = "كمثرى"
    case apple = "تفاحة"
    case rectangle = "مستطيل"
    case invertedTriangle = "مثلث مقلوب"
    case balanced = "متوازن"

    var id: String { rawValue }

    var styleNote: String {
        switch self {
        case .hourglass:
            return "القصات المحددة للخصر غالبًا تطلع عليك متوازنة."
        case .pear:
            return "التفاصيل بالأعلى والألوان الهادئة بالأسفل تعطي توازن جميل."
        case .apple:
            return "القصات الانسيابية والتركيز على خط الرقبة يبرز الإطلالة."
        case .rectangle:
            return "الطبقات والأحزمة تساعد في إبراز الخصر."
        case .invertedTriangle:
            return "التفاصيل بالأسفل والقصات الناعمة بالأعلى تعطي توازن."
        case .balanced:
            return "جسمك متوازن، فاختاري القصات حسب الستايل والمناسبة."
        }
    }
}

enum Undertone: String, CaseIterable, Identifiable {
    case warm = "دافئ"
    case cool = "بارد"
    case neutral = "محايد"

    var id: String { rawValue }

    var recommendedColors: [String] {
        switch self {
        case .warm:
            return ["عاجي", "بيج دافئ", "زيتوني", "ذهبي", "خوخي", "بني كراميل"]
        case .cool:
            return ["أبيض ناصع", "أزرق ملكي", "وردي بارد", "بنفسجي مزرق", "فضي", "عنابي"]
        case .neutral:
            return ["أوف وايت", "رمادي ناعم", "كحلي", "وردي غباري", "أخضر ساج", "توبي"]
        }
    }
}

enum ClothingCategory: String, CaseIterable, Identifiable {
    case top = "بلوزة"
    case pants = "بنطلون"
    case skirt = "تنورة"
    case dress = "فستان"
    case abaya = "عباية"
    case outerwear = "جاكيت"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .top:
            return "tshirt"
        case .pants:
            return "figure.walk"
        case .skirt:
            return "sparkles"
        case .dress:
            return "hanger"
        case .abaya:
            return "moon.stars"
        case .outerwear:
            return "jacket"
        }
    }

    var isTop: Bool {
        self == .top || self == .outerwear
    }

    var isBottom: Bool {
        self == .pants || self == .skirt
    }

    var isOnePiece: Bool {
        self == .dress || self == .abaya
    }
}

enum Season: String, CaseIterable, Identifiable {
    case summer = "صيف"
    case winter = "شتاء"
    case spring = "ربيع"
    case autumn = "خريف"
    case allYear = "كل السنة"

    var id: String { rawValue }
}

enum Occasion: String, CaseIterable, Identifiable {
    case daily = "يومي"
    case work = "دوام"
    case outing = "طلعات"
    case travel = "سفر"
    case evening = "مساء"

    var id: String { rawValue }
}

enum ProfileAnalyzer {
    static func detectBodyShape(shoulders: Double, bust: Double, waist: Double, hips: Double) -> BodyShape {
        let upperLine = max(shoulders, bust)
        let waistDefinition = waist / max(hips, upperLine)
        let upperLowerDifference = abs(bust - hips)
        let shoulderHipDifference = shoulders - hips

        if waistDefinition <= 0.75, upperLowerDifference <= 5 {
            return .hourglass
        }

        if hips - bust >= 5 {
            return .pear
        }

        if bust - hips >= 5, waistDefinition > 0.8 {
            return .apple
        }

        if shoulderHipDifference >= 5 {
            return .invertedTriangle
        }

        if upperLowerDifference <= 4, waistDefinition > 0.75 {
            return .rectangle
        }

        return .balanced
    }
}
