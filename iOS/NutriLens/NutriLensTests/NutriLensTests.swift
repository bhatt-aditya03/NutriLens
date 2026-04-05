// NutriLensTests.swift
// NutriLens — Unit Tests
// Tests for ScanHistoryStore and nutrition scaling logic

import XCTest
@testable import NutriLens

final class ScanHistoryStoreTests: XCTestCase {

    var store: ScanHistoryStore!

    let sampleNutrition = NutritionInfo(
        protein_g: 25.0,
        calories: 150,
        fat_g: 7.0,
        carbs_g: 5.0
    )

    override func setUp() {
        super.setUp()
        store = ScanHistoryStore.shared
    }

    override func tearDown() {
        store.clear()
        // don't nil out — it's a singleton
        super.tearDown()
    }

    // ── Add / Clear ───────────────────────────────────────────

    func testAddEntry() {
        store.add(
            label: "Biryani",
            confidence: 0.95,
            nutrition: sampleNutrition,
            servingGrams: 100
        )
        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries.first?.label, "Biryani")
    }

    func testAddMultipleEntries() {
        store.add(label: "Samosa",   confidence: 0.8, nutrition: sampleNutrition, servingGrams: 100)
        store.add(label: "Biryani",  confidence: 0.9, nutrition: sampleNutrition, servingGrams: 200)
        store.add(label: "Dal Tadka",confidence: 0.7, nutrition: sampleNutrition, servingGrams: 150)
        XCTAssertEqual(store.entries.count, 3)
    }

    func testNewestEntryFirst() {
        store.add(label: "Samosa",  confidence: 0.8, nutrition: sampleNutrition, servingGrams: 100)
        store.add(label: "Biryani", confidence: 0.9, nutrition: sampleNutrition, servingGrams: 100)
        XCTAssertEqual(store.entries.first?.label, "Biryani")
    }

    func testClearRemovesAll() {
        store.add(label: "Samosa",  confidence: 0.8, nutrition: sampleNutrition, servingGrams: 100)
        store.add(label: "Biryani", confidence: 0.9, nutrition: sampleNutrition, servingGrams: 100)
        store.clear()
        XCTAssertTrue(store.entries.isEmpty)
    }

    func testRemoveAtOffsets() {
        store.add(label: "Samosa",  confidence: 0.8, nutrition: sampleNutrition, servingGrams: 100)
        store.add(label: "Biryani", confidence: 0.9, nutrition: sampleNutrition, servingGrams: 100)
        store.remove(at: IndexSet(integer: 0))
        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries.first?.label, "Samosa")
    }

    // ── Daily totals ──────────────────────────────────────────

    func testTodayTotalProtein() {
        store.add(label: "Biryani", confidence: 0.9, nutrition: sampleNutrition, servingGrams: 100)
        store.add(label: "Biryani", confidence: 0.9, nutrition: sampleNutrition, servingGrams: 100)
        XCTAssertEqual(store.todayTotalProtein, 50.0, accuracy: 0.01)
    }

    func testTodayTotalCalories() {
        store.add(label: "Biryani", confidence: 0.9, nutrition: sampleNutrition, servingGrams: 100)
        XCTAssertEqual(store.todayTotalCalories, 150.0, accuracy: 0.01)
    }

    func testEmptyStoreTotalsAreZero() {
        XCTAssertEqual(store.todayTotalProtein,  0.0)
        XCTAssertEqual(store.todayTotalCalories, 0.0)
    }
}

// ── Nutrition scaling tests ───────────────────────────────────
final class NutritionScalingTests: XCTestCase {

    let baseNutrition = NutritionInfo(
        protein_g: 25.0,
        calories: 200,
        fat_g: 10.0,
        carbs_g: 30.0
    )

    func testScalingAt100g() {
        let entry = ScanEntry(
            label: "Test",
            confidence: 0.9,
            nutrition: baseNutrition,
            servingGrams: 100
        )
        XCTAssertEqual(entry.scaledProtein,  25.0,  accuracy: 0.01)
        XCTAssertEqual(entry.scaledCalories, 200.0, accuracy: 0.01)
        XCTAssertEqual(entry.scaledFat,      10.0,  accuracy: 0.01)
        XCTAssertEqual(entry.scaledCarbs,    30.0,  accuracy: 0.01)
    }

    func testScalingAt200g() {
        let entry = ScanEntry(
            label: "Test",
            confidence: 0.9,
            nutrition: baseNutrition,
            servingGrams: 200
        )
        XCTAssertEqual(entry.scaledProtein,  50.0,  accuracy: 0.01)
        XCTAssertEqual(entry.scaledCalories, 400.0, accuracy: 0.01)
        XCTAssertEqual(entry.scaledFat,      20.0,  accuracy: 0.01)
        XCTAssertEqual(entry.scaledCarbs,    60.0,  accuracy: 0.01)
    }

    func testScalingAt50g() {
        let entry = ScanEntry(
            label: "Test",
            confidence: 0.9,
            nutrition: baseNutrition,
            servingGrams: 50
        )
        XCTAssertEqual(entry.scaledProtein,  12.5,  accuracy: 0.01)
        XCTAssertEqual(entry.scaledCalories, 100.0, accuracy: 0.01)
        XCTAssertEqual(entry.scaledFat,       5.0,  accuracy: 0.01)
        XCTAssertEqual(entry.scaledCarbs,    15.0,  accuracy: 0.01)
    }

    func testScalingAt300g() {
        let entry = ScanEntry(
            label: "Test",
            confidence: 0.9,
            nutrition: baseNutrition,
            servingGrams: 300
        )
        XCTAssertEqual(entry.scaledProtein,  75.0,  accuracy: 0.01)
        XCTAssertEqual(entry.scaledCalories, 600.0, accuracy: 0.01)
    }
}
