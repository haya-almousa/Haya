//
//  AppServices.swift
//  Haya
//
//  Created by Haya almousa on 19/04/2026.
//

import AuthenticationServices
import Combine
import StoreKit

@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var isSignedIn = false
    @Published var errorMessage: String?
    private let sessionStore: SessionStore

    init() {
        self.sessionStore = SessionStore()
        let storedIdentifier = sessionStore.savedAppleUserIdentifier()
        isSignedIn = storedIdentifier?.isEmpty == false
    }

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
        let storedIdentifier = sessionStore.savedAppleUserIdentifier()
        isSignedIn = storedIdentifier?.isEmpty == false
    }

    var userIdentifier: String {
        sessionStore.savedAppleUserIdentifier() ?? "anonymous-user"
    }

    func handle(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "تعذر قراءة بيانات Apple ID."
                return
            }

            sessionStore.saveAppleUserIdentifier(credential.user)
            isSignedIn = true
            errorMessage = nil
        case .failure(let error):
            errorMessage = Self.signInErrorMessage(from: error)
        }
    }

    private static func signInErrorMessage(from error: Error) -> String {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                return "تم إلغاء تسجيل الدخول."
            case .failed:
                return "فشل تسجيل الدخول. تأكدي من تفعيل Sign in with Apple في المشروع."
            case .invalidResponse:
                return "استجابة Apple غير صالحة."
            case .notHandled:
                return "لم يتمكن النظام من معالجة طلب تسجيل الدخول."
            case .unknown:
                return "حدث خطأ غير معروف أثناء تسجيل الدخول."
            case .notInteractive:
                return "لا يمكن عرض واجهة تسجيل الدخول الآن."
            default:
                return error.localizedDescription
            }
        }

        return error.localizedDescription
    }
}

@MainActor
final class PurchaseManager: ObservableObject {
    @Published private(set) var hasUnlockedBodyAnalysis = false
    @Published private(set) var bodyAnalysisProduct: Product?
    @Published private(set) var isPurchasing = false
    @Published var purchaseError: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = observeTransactionUpdates()

        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [AppConfiguration.bodyAnalysisProductID])
            bodyAnalysisProduct = products.first
            purchaseError = bodyAnalysisProduct == nil
                ? "ما زال منتج الدفع غير مضاف في App Store Connect أو ملف StoreKit المحلي."
                : nil
        } catch {
            purchaseError = "تعذر تحميل منتجات الدفع."
        }
    }

    func purchaseBodyAnalysis() async {
        guard let product = bodyAnalysisProduct else {
            purchaseError = "المنتج غير متاح حاليًا."
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await unlock(using: transaction)
                await transaction.finish()
                purchaseError = nil
            case .pending:
                purchaseError = "العملية ما زالت معلقة من Apple."
            case .userCancelled:
                purchaseError = nil
            @unknown default:
                purchaseError = "نتيجة شراء غير معروفة."
            }
        } catch {
            purchaseError = "فشل إتمام الدفع."
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            purchaseError = "تعذر استعادة المشتريات."
        }
    }

    #if DEBUG
    func unlockForDevelopment() {
        hasUnlockedBodyAnalysis = true
        purchaseError = nil
    }
    #endif

    private func refreshEntitlements() async {
        var unlocked = false

        for await result in StoreKit.Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.productID == AppConfiguration.bodyAnalysisProductID,
               transaction.revocationDate == nil {
                unlocked = true
            }
        }

        hasUnlockedBodyAnalysis = unlocked
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            guard let self else { return }

            for await result in StoreKit.Transaction.updates {
                guard let transaction = try? self.checkVerified(result) else { continue }
                await self.unlock(using: transaction)
                await transaction.finish()
            }
        }
    }

    private func unlock(using transaction: StoreKit.Transaction) async {
        if transaction.productID == AppConfiguration.bodyAnalysisProductID,
           transaction.revocationDate == nil {
            hasUnlockedBodyAnalysis = true
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw PurchaseVerificationError.failed
        }
    }
}

private enum PurchaseVerificationError: Error {
    case failed
}
