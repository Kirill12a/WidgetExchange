//
//  PurchaseManager.swift
//  Widget
//
//  Created by Kirill Drozdov on 09.11.2025.
//

import Foundation
import Combine
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    enum PurchaseState: Equatable {
        case idle
        case purchasing(String)
        case success
        case failed(String)
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published var purchaseState: PurchaseState = .idle
    @Published var infoMessage: String?

    private var updatesTask: Task<Void, Never>?

    var isSubscribed: Bool {
        !purchasedProductIDs.isEmpty
    }

    init(previewMode: Bool = false) {
        guard !previewMode else { return }

        updatesTask = Task {
            await listenForTransactions()
        }

        Task {
            await refreshProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func refreshProducts() async {
        do {
            products = try await Product.products(for: [
                SharedConstants.converterProMonthlyID,
                SharedConstants.converterProAnnualID
            ])
            infoMessage = nil
        } catch {
            infoMessage = "Не удалось загрузить подписки: \(error.localizedDescription)"
        }
    }

    func purchase(_ product: Product) async {
        purchaseState = .purchasing(product.id)
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
                purchaseState = .success
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .idle
            @unknown default:
                purchaseState = .failed("Неизвестный статус покупки")
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    func restore() async {
        await updatePurchasedProducts()
    }

    private func updatePurchasedProducts() async {
        var ids: Set<String> = []
        for await verification in Transaction.currentEntitlements {
            guard case .verified(let transaction) = verification else { continue }
            ids.insert(transaction.productID)
        }

        purchasedProductIDs = ids
        if ids.isEmpty {
            purchaseState = .idle
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            do {
                let transaction = try checkVerified(result)
                purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
                purchaseState = .success
            } catch {
                purchaseState = .failed(error.localizedDescription)
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.unverified
        case .verified(let safe):
            return safe
        }
    }

    enum PurchaseError: LocalizedError {
        case unverified

        var errorDescription: String? {
            switch self {
            case .unverified:
                return "Покупка не верифицирована."
            }
        }
    }
}

extension PurchaseManager.PurchaseState {
    func isPurchasing(productID: String) -> Bool {
        if case .purchasing(let id) = self, id == productID {
            return true
        }
        return false
    }
}
