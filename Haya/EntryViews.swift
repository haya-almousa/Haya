//
//  EntryViews.swift
//  Haya
//
//  Created by Haya almousa on 19/04/2026.
//

import AuthenticationServices
import StoreKit
import SwiftUI

struct ProfileDraft {
    var name = ""
    var shoulderWidth = 86.0
    var bust = 86.0
    var waist = 66.0
    var hips = 96.0
    var selectedUndertone: Undertone = .neutral

    mutating func reset() {
        self = ProfileDraft()
    }
}

struct SignInGateView: View {
    @ObservedObject var sessionManager: SessionManager

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Text(AppConfiguration.appName)
                .font(.system(size: 42, weight: .semibold, design: .serif))
                .tracking(1)

            VStack(spacing: 10) {
                Text("ادخلي بحساب Apple")
                    .font(.system(size: 30, weight: .semibold, design: .serif))
                Text("نستخدم تسجيل Apple عشان نحفظ بروفايلك ودولابك ومشترياتك بطريقة آمنة.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 28)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                sessionManager.handle(result: result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 54)
            .padding(.horizontal, 24)

            if let errorMessage = sessionManager.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 24)
            }

            Spacer()
        }
    }
}

struct ProfileOnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onCalculateTapped: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(AppConfiguration.appName)
                    .font(.system(size: 34, weight: .semibold, design: .serif))
                    .tracking(1)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 18)

                VStack(alignment: .leading, spacing: 10) {
                    Text("قياساتك أولًا")
                        .font(.system(size: 32, weight: .semibold, design: .serif))
                    Text("أدخلي قياساتك عشان نعرف شكل جسمك ونقترح لك قصات وألوان تناسبك.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                VStack(alignment: .leading, spacing: 18) {
                    silhouetteCard

                    measurementSlider(
                        title: "الأكتاف",
                        value: viewModel.measurementBinding(for: \.shoulderWidth),
                        range: viewModel.selectedUnit.sliderRange,
                        unit: viewModel.selectedUnit.shortLabel
                    )
                    measurementSlider(
                        title: "الصدر",
                        value: viewModel.measurementBinding(for: \.bust),
                        range: viewModel.selectedUnit.sliderRange,
                        unit: viewModel.selectedUnit.shortLabel
                    )
                    measurementSlider(
                        title: "الخصر",
                        value: viewModel.measurementBinding(for: \.waist),
                        range: viewModel.selectedUnit.sliderRange,
                        unit: viewModel.selectedUnit.shortLabel
                    )
                    measurementSlider(
                        title: "الأرداف",
                        value: viewModel.measurementBinding(for: \.hips),
                        range: viewModel.selectedUnit.sliderRange,
                        unit: viewModel.selectedUnit.shortLabel
                    )

                    Picker("الوحدة", selection: $viewModel.selectedUnit) {
                        ForEach(MeasurementUnit.allCases) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField("اسمك أو لقبك", text: $viewModel.draft.name)
                        .textFieldStyle(.roundedBorder)

                    Picker("الأندرتون", selection: $viewModel.draft.selectedUndertone) {
                        ForEach(Undertone.allCases) { tone in
                            Text(tone.rawValue).tag(tone)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("كل ما فهمتي جسمك وألوانك، صار التنسيق أسهل.")
                        .font(.footnote.italic())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    if !viewModel.validationMessage.isEmpty {
                        Text(viewModel.validationMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button("احسبي نوع جسمي وألواني", action: onCalculateTapped)
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

    private var silhouetteCard: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white.opacity(0.55))
            .frame(height: 260)
            .overlay {
                ZStack {
                    SilhouetteFigureView()
                    VStack(spacing: 34) {
                        silhouetteLabel("الأكتاف")
                        silhouetteLabel("الصدر")
                        silhouetteLabel("الخصر")
                        silhouetteLabel("الأرداف")
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 14)
                }
                .padding(.horizontal, 22)
            }
    }

    private func silhouetteLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.tallaSoft.opacity(0.85))
            )
    }

    private func measurementSlider(title: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(value.wrappedValue.rounded())) \(unit)")
                    .font(.headline)
            }

            Slider(value: value, in: range)
                .tint(.black)

            HStack {
                Text("\(Int(range.lowerBound))")
                Spacer()
                Text("\(Int(range.upperBound))")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }
}

private struct SilhouetteFigureView: View {
    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width * 0.38
            let topY = geometry.size.height * 0.10

            Path { path in
                path.addEllipse(in: CGRect(x: centerX - 14, y: topY, width: 28, height: 34))
                path.move(to: CGPoint(x: centerX, y: topY + 34))
                path.addLine(to: CGPoint(x: centerX, y: topY + 162))

                path.move(to: CGPoint(x: centerX - 28, y: topY + 56))
                path.addQuadCurve(to: CGPoint(x: centerX + 28, y: topY + 56), control: CGPoint(x: centerX, y: topY + 44))

                path.move(to: CGPoint(x: centerX - 20, y: topY + 98))
                path.addQuadCurve(to: CGPoint(x: centerX + 20, y: topY + 98), control: CGPoint(x: centerX, y: topY + 108))

                path.move(to: CGPoint(x: centerX - 30, y: topY + 138))
                path.addQuadCurve(to: CGPoint(x: centerX + 30, y: topY + 138), control: CGPoint(x: centerX, y: topY + 132))

                path.move(to: CGPoint(x: centerX - 18, y: topY + 162))
                path.addLine(to: CGPoint(x: centerX - 14, y: topY + 236))
                path.move(to: CGPoint(x: centerX + 18, y: topY + 162))
                path.addLine(to: CGPoint(x: centerX + 14, y: topY + 236))
            }
            .stroke(Color.black.opacity(0.20), lineWidth: 2)

            measurementLine(y: topY + 58, width: 66, centerX: centerX)
            measurementLine(y: topY + 100, width: 44, centerX: centerX)
            measurementLine(y: topY + 140, width: 76, centerX: centerX)
        }
        .frame(height: 240)
    }

    private func measurementLine(y: CGFloat, width: CGFloat, centerX: CGFloat) -> some View {
        Rectangle()
            .fill(Color.black.opacity(0.65))
            .frame(width: width, height: 3)
            .overlay {
                HStack {
                    Circle().fill(Color.black.opacity(0.65)).frame(width: 6, height: 6)
                    Spacer()
                    Circle().fill(Color.black.opacity(0.65)).frame(width: 6, height: 6)
                }
            }
            .position(x: centerX, y: y)
    }
}

struct PaywallView: View {
    @ObservedObject var purchaseManager: PurchaseManager
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("افتحي التحليل الشخصي")
                            .font(.system(size: 30, weight: .semibold, design: .serif))
                        Text("دفعة واحدة تفتح لك تحليل شكل الجسم، الأندرتون، والألوان المناسبة وتحفظ النتيجة في بروفايلك.")
                            .foregroundStyle(.secondary)
                    }

                    TallaCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("يشمل")
                                .font(.headline)
                            paywallFeature("تحليل نوع الجسم")
                            paywallFeature("الأندرتون والألوان المناسبة")
                            paywallFeature("حفظ النتيجة داخل البروفايل")
                        }
                    }

                    if let product = purchaseManager.bodyAnalysisProduct {
                        TallaCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text(product.displayName)
                                    .font(.title3.bold())
                                Text(product.description)
                                    .foregroundStyle(.secondary)
                                Text(product.displayPrice)
                                    .font(.title.bold())

                                if let purchaseError = purchaseManager.purchaseError {
                                    Text(purchaseError)
                                        .font(.footnote)
                                        .foregroundStyle(.red)
                                }

                                Button("افتحي التحليل الآن") {
                                    Task {
                                        await purchaseManager.purchaseBodyAnalysis()
                                    }
                                }
                                .buttonStyle(TallaPrimaryButtonStyle())
                                .disabled(purchaseManager.isPurchasing)

                                Button("استعادة المشتريات") {
                                    Task {
                                        await purchaseManager.restorePurchases()
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    } else {
                        TallaCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("الدفع غير جاهز على هذا الجهاز")
                                    .font(.headline)
                                Text("للإطلاق على App Store لازم يكون منتج الشراء مضافًا ومفعّلًا في App Store Connect بهذا المعرّف:")
                                    .foregroundStyle(.secondary)
                                Text(AppConfiguration.bodyAnalysisProductID)
                                    .font(.footnote.monospaced())
                                    .foregroundStyle(Color.tallaTaupe)
                                if let purchaseError = purchaseManager.purchaseError {
                                    Text(purchaseError)
                                        .font(.footnote)
                                        .foregroundStyle(.red)
                                }

                                #if DEBUG
                                Button("فتح مؤقت للتجربة") {
                                    purchaseManager.unlockForDevelopment()
                                    onClose()
                                }
                                .buttonStyle(TallaPrimaryButtonStyle())
                                #endif
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.tallaBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("إغلاق", action: onClose)
                }
            }
        }
        .task {
            await purchaseManager.loadProducts()
        }
    }

    private func paywallFeature(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.tallaSage)
            Text(text)
        }
    }
}
