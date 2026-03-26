// CameraView.swift
// ProteinLens — Day 4
// SwiftUI wrapper around AVFoundation camera + live detection overlay

import SwiftUI
import AVFoundation

struct CameraView: View {

    @StateObject private var classifier = FoodClassifier()

    var body: some View {
        ZStack {

            // ── Live camera feed ──────────────────────────────
            CameraPreview(session: classifier.session)
                .ignoresSafeArea()

            // ── Overlay ───────────────────────────────────────
            VStack {
                // Top bar
                HStack {
                    Text("ProteinLens")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    // Confidence badge
                    if classifier.confidence > 0 {
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

                Spacer()

                // ── Detection card ────────────────────────────
                if !classifier.label.isEmpty && classifier.confidence >= 0.5 {
                    DetectionCard(
                        label: classifier.label,
                        confidence: classifier.confidence,
                        nutrition: classifier.nutrition
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 50)
                } else {
                    // Scanning indicator
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
                    .padding(.bottom, 60)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: classifier.label)
        .onAppear  { classifier.startSession() }
        .onDisappear { classifier.stopSession() }
    }

    private func confidenceColor(_ confidence: Float) -> Color {
        switch confidence {
        case 0.85...: return .green.opacity(0.85)
        case 0.65...: return .orange.opacity(0.85)
        default:      return .red.opacity(0.85)
        }
    }
}

// ── Detection result card ─────────────────────────────────────
struct DetectionCard: View {
    let label      : String
    let confidence : Float
    let nutrition  : NutritionInfo?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Food name
            HStack {
                Text(label)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "fork.knife")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.7))
            }

            Divider().background(.white.opacity(0.3))

            // Nutrition row
            if let n = nutrition {
                HStack(spacing: 0) {
                    NutritionPill(value: n.protein_g,  unit: "g", label: "Protein",  color: .green)
                    Spacer()
                    NutritionPill(value: Float(n.calories), unit: "kcal", label: "Calories", color: .orange)
                    Spacer()
                    NutritionPill(value: n.fat_g ?? 0, unit: "g", label: "Fat",      color: .yellow)
                    Spacer()
                    NutritionPill(value: n.carbs_g ?? 0, unit: "g", label: "Carbs",  color: .blue)
                }
            }

            Text("per 100g  •  tap to freeze frame")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.15), lineWidth: 0.5)
        )
    }
}

struct NutritionPill: View {
    let value : Float
    let unit  : String
    let label : String
    let color : Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value == 0 ? "—" : String(format: "%.1f", value))
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(color)
            Text(unit)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}
