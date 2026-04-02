//
//  NotchMind - ViewModel Base
//  BaseViewModel.swift
//

import Foundation
import Combine

/// Base class for all ViewModels with Combine support
@MainActor
final class BaseViewModel: ObservableObject {

    // MARK: - Properties

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Protected Properties

    var cancellables = Set<AnyCancellable>()

    // MARK: - Methods

    func clearError() {
        errorMessage = nil
    }

    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        isLoading = false
    }
}