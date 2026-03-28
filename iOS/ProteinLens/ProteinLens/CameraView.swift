// CameraView.swift
// ProteinLens — Day 5
// Added: serving size slider (50g-500g) + tap to freeze/unfreeze

import SwiftUI
import AVFoundation

struct CameraView: View {

    @StateObject private var classifier = FoodClassifier()
    @State private var servingGrams: Double = 100
    @State private var isFrozen: Bool = false

    var body: some View {
        ZStack {

            // ── Live camera feed ──────────────────────────────
            CameraPreview(session: classifier.session)
                .ignoresSafeArea()

            // ── Tap anywhere to freeze/unfreeze ───────────────
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isFrozen.toggle()
                        if isFrozen {
                            classifier.pauseInference()
                        } else {
                            classifier.resumeInference()
                            // Reset serving size on unfreeze
                            servingGrams = 100
                        }
                    }
                }

            // ── Overlay ───────────────────────────────────────
            VStack(spacing: 0) {

                // Top bar
                topBar

                Spacer()

                // Detection card + slider
                if !classifier.label.isEmpty && classifier.confidence >= 0.40 {
                    VStack(spacing: 10) {
                        DetectionCard(
                            label      : classifier.label,
                            confidence : classifier.confidence,
                            nutrition  : classifier.nutrition,
                            servingGrams: servingGrams,
                            isFrozen   : isFrozen
                        )

                        // Serving size slider — only show when detected
                        ServingSizeSlider(grams: $servingGrams)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)

                } else if !isFrozen {
                    scanningIndicator
                        .padding(.bottom, 60)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: classifier.label)
        .animation(.easeInOut(duration: 0.2), value: isFrozen)
        .onAppear  { classifier.startSession() }
        .onDisappear { classifier.stopSession() }
    }

    // ── Top bar ───────────────────────────────────────────────
    private var topBar: some View {
        HStack {
            Text("ProteinLens")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            // Frozen indicator
            if isFrozen {
                HStack(spacing: 5) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 11))
                    Text("Frozen")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.85))
                .clipShape(Capsule())
            } else if classifier.confidence > 0 {
                // Confidence badge
                Text("\(Int(classifier.confidence * 100))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(confidenceColor(classifier.confidence))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [.black.opacity(0.6), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // ── Scanning indicator ────────────────────────────────────
    private var scanningIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(.white)
                .scaleEffect(0.8)
            Text("Point camera at food...")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.black.opacity(0.45))
        .clipShape(Capsule())
    }

    private func confidenceColor(_ c: Float) -> Color {
        switch c {
        case 0.85...: return .green.opacity(0.85)
        case 0.65...: return .orange.opacity(0.85)
        default:      return .red.opacity(0.85)
        }
    }
}

// ── Serving size slider ───────────────────────────────────────
struct ServingSizeSlider: View {

    @Binding var grams: Double

    // Quick preset buttons
    private let presets: [(String, Double)] = [
        ("50g", 50), ("100g", 100), ("200g", 200), ("300g", 300)
    ]

    var body: some View {
        VStack(spacing: 10) {
            // Label row
            HStack {
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                Text("Serving size")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text("\(Int(grams))g")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .monospacedDigit()
                    .frame(minWidth: 55, alignment: .trailing)
            }

            // Slider
            Slider(value: $grams, in: 50...500, step: 5)
                .tint(.green)

            // Preset buttons
            HStack(spacing: 8) {
                ForEach(presets, id: \.0) { label, value in
                    Button {
                        withAnimation(.spring(duration: 0.2)) {
                            grams = value
                        }
                    } label: {
                        Text(label)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(grams == value ? .black : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                grams == value
                                ? Color.green
                                : Color.white.opacity(0.15)
                            )
                            .clipShape(Capsule())
                    }
                }
                Spacer()
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.15), lineWidth: 0.5)
        )
    }
}

// ── Detection card ────────────────────────────────────────────
struct DetectionCard: View {

    let label        : String
    let confidence   : Float
    let nutrition    : NutritionInfo?
    let servingGrams : Double
    let isFrozen     : Bool

    // Scale factor vs 100g baseline
    private var scale: Double { servingGrams / 100.0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Food name + icon
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text(isFrozen ? "Tap screen to resume" : "per \(Int(servingGrams))g")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                Image(systemName: isFrozen ? "pause.circle.fill" : "fork.knife")
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.6))
            }

            Divider().background(.white.opacity(0.3))

            // Nutrition grid — scaled by serving size
            if let n = nutrition {
                HStack(spacing: 0) {
                    NutritionPill(
                        value: n.protein_g * Float(scale),
                        unit: "g",
                        label: "Protein",
                        color: .green
                    )
                    Spacer()
                    NutritionPill(
                        value: Float(Double(n.calories) * scale),
                        unit: "kcal",
                        label: "Calories",
                        color: .orange
                    )
                    Spacer()
                    NutritionPill(
                        value: n.fat_g * Float(scale),
                        unit: "g",
                        label: "Fat",
                        color: .yellow
                    )
                    Spacer()
                    NutritionPill(
                        value: n.carbs_g * Float(scale),
                        unit: "g",
                        label: "Carbs",
                        color: .blue
                    )
                }
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isFrozen
                    ? Color.blue.opacity(0.5)
                    : Color.white.opacity(0.15),
                    lineWidth: isFrozen ? 1.5 : 0.5
                )
        )
    }
}

// ── Nutrition pill ────────────────────────────────────────────
struct NutritionPill: View {
    let value : Float
    let unit  : String
    let label : String
    let color : Color

    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%.1f", value))
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(color)
                .monospacedDigit()
            Text(unit)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}
