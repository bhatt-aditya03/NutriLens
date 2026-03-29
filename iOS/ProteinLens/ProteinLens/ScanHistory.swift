// ScanHistory.swift
// ProteinLens — Day 6
// In-memory scan history store shared across the app

import SwiftUI
import Combine

// ── Single scan entry ─────────────────────────────────────────
struct ScanEntry: Identifiable {
    let id          : UUID    = UUID()
    let label       : String
    let confidence  : Float
    let nutrition   : NutritionInfo
    let servingGrams: Double
    let timestamp   : Date    = Date()

    // Scaled nutrition values for the actual serving size scanned
    var scaledProtein  : Float { nutrition.protein_g * Float(servingGrams / 100) }
    var scaledCalories : Float { Float(nutrition.calories) * Float(servingGrams / 100) }
    var scaledFat      : Float { nutrition.fat_g * Float(servingGrams / 100) }
    var scaledCarbs    : Float { nutrition.carbs_g * Float(servingGrams / 100) }

    var timeString: String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: timestamp)
    }

    var dateString: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: timestamp)
    }
}

// ── Shared history store ──────────────────────────────────────
final class ScanHistoryStore: ObservableObject {
    static let shared = ScanHistoryStore()

    @Published private(set) var entries: [ScanEntry] = []

    private init() {}

    func add(
        label: String,
        confidence: Float,
        nutrition: NutritionInfo,
        servingGrams: Double
    ) {
        let entry = ScanEntry(
            label       : label,
            confidence  : confidence,
            nutrition   : nutrition,
            servingGrams: servingGrams
        )
        entries.insert(entry, at: 0) // newest first
    }

    func clear() {
        entries.removeAll()
    }

    func remove(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
    }

    // Daily totals
    var todayEntries: [ScanEntry] {
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())
        return entries.filter { cal.startOfDay(for: $0.timestamp) == today }
    }

    var todayTotalProtein  : Float { todayEntries.reduce(0) { $0 + $1.scaledProtein   } }
    var todayTotalCalories : Float { todayEntries.reduce(0) { $0 + $1.scaledCalories  } }
}
