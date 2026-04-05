// HistoryView.swift
// NutriLens
// Scan history — separate screen with back button

import SwiftUI

struct HistoryView: View {

    @StateObject private var store = ScanHistoryStore.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Nav bar ───────────────────────────────────
                HStack {
                    Button { dismiss() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(.green)
                    }

                    Spacer()

                    Text("Scan History")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    if !store.entries.isEmpty {
                        Button {
                            withAnimation { store.clear() }
                        } label: {
                            Text("Clear")
                                .font(.system(size: 15))
                                .foregroundColor(.red.opacity(0.8))
                        }
                    } else {
                        Text("Clear").foregroundColor(.clear)
                            .font(.system(size: 15))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 16)

                if store.entries.isEmpty {
                    Spacer()
                    VStack(spacing: 14) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.2))
                        Text("No scans yet")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                        Text("Point the camera at food\nto start tracking")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.3))
                            .multilineTextAlignment(.center)
                    }
                    Spacer()

                } else {
                    if !store.todayEntries.isEmpty {
                        TodaySummaryCard(
                            count   : store.todayEntries.count,
                            protein : store.todayTotalProtein,
                            calories: Double(store.todayTotalCalories)
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }

                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(store.entries) { entry in
                                ScanEntryRow(entry: entry)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// ── Today summary card ────────────────────────────────────────
struct TodaySummaryCard: View {
    let count   : Int
    let protein : Float
    let calories: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Text("\(count) scan\(count == 1 ? "" : "s")")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
            }
            HStack(spacing: 0) {
                SummaryPill(value: String(format: "%.1f", protein),
                            unit: "g", label: "Total Protein", color: .green)
                Spacer()
                SummaryPill(value: String(format: "%.0f", calories),
                            unit: "kcal", label: "Total Calories", color: .orange)
                Spacer()
                let pct = min(Int((protein / 150.0) * 100), 100)
                SummaryPill(value: "\(pct)%", unit: "",
                            label: "Daily Goal",
                            color: pct >= 100 ? .green : .blue)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(.white.opacity(0.1), lineWidth: 0.5))
    }
}

// ── Summary pill ──────────────────────────────────────────────
struct SummaryPill: View {
    let value : String
    let unit  : String
    let label : String
    let color : Color

    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(color)
                    .monospacedDigit()
                if !unit.isEmpty {
                    Text(unit).font(.system(size: 11))
                        .foregroundColor(color.opacity(0.7))
                }
            }
            Text(label).font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}

// ── Single scan row ───────────────────────────────────────────
struct ScanEntryRow: View {
    let entry: ScanEntry

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.green.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "fork.knife")
                    .font(.system(size: 18))
                    .foregroundColor(.green.opacity(0.8))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                HStack(spacing: 6) {
                    Text(entry.timeString)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                    Text("•").foregroundColor(.white.opacity(0.3))
                    Text("\(Int(entry.servingGrams))g")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                    Text("•").foregroundColor(.white.opacity(0.3))
                    Text("\(Int(entry.confidence * 100))% conf.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(String(format: "%.1fg", entry.scaledProtein))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.green)
                    .monospacedDigit()
                Text(String(format: "%.0f kcal", entry.scaledCalories))
                    .font(.system(size: 12))
                    .foregroundColor(.orange.opacity(0.8))
                    .monospacedDigit()
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(.white.opacity(0.08), lineWidth: 0.5))
    }
}
