import Foundation
import Observation

@Observable
final class PetShopListViewModel {
    private(set) var shops: [PetShop] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    var errorMessage: String?
    var searchText = ""
    private(set) var currentPage = 1
    private(set) var hasMore = true

    @ObservationIgnored private let repository: PetShopRepositoryProtocol
    @ObservationIgnored private let pageSize: Int
    @ObservationIgnored private var searchTask: Task<Void, Never>?

    init(repository: PetShopRepositoryProtocol = PetShopRepository(), pageSize: Int = 20) {
        self.repository = repository
        self.pageSize = pageSize
    }

    @MainActor
    func onAppear() async {
        guard shops.isEmpty else {
            return
        }
        await loadFirstPage()
    }

    @MainActor
    func loadFirstPage() async {
        isLoading = true
        errorMessage = nil
        currentPage = 1
        defer { isLoading = false }

        do {
            let result = try await repository.list(page: currentPage, query: normalizedSearch)
            shops = result
            hasMore = result.count >= pageSize
        } catch {
            shops = []
            hasMore = false
            errorMessage = message(for: error)
        }
    }

    @MainActor
    func loadMoreIfNeeded(currentShop: PetShop) async {
        guard currentShop.id == shops.last?.id, hasMore, !isLoadingMore, !isLoading else {
            return
        }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let nextPage = currentPage + 1
            let result = try await repository.list(page: nextPage, query: normalizedSearch)
            currentPage = nextPage
            shops.append(contentsOf: result)
            hasMore = result.count >= pageSize
        } catch {
            errorMessage = message(for: error)
        }
    }

    func search(text: String) {
        searchText = text
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else {
                return
            }
            await self?.loadFirstPage()
        }
    }

    private var normalizedSearch: String? {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func message(for error: Error) -> String {
        if let networkError = error as? NetworkError {
            return networkError.userMessage
        }
        return NetworkError.unknown(error.localizedDescription).userMessage
    }
}
