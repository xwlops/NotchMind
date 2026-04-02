//
//  NotchMind - Date Extension
//  Date+Extensions.swift
//

import Foundation

extension Date {

    /// Returns a human-readable relative time string
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Check if date is within the given time interval
    func isWithin(seconds: TimeInterval) -> Bool {
        return Date().timeIntervalSince(self) < seconds
    }

    /// Format date as short time string
    var shortTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: self)
    }
}