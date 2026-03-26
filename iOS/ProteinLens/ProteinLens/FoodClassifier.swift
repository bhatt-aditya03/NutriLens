// FoodClassifier.swift
// ProteinLens — Day 4 (Fixed)
// AVFoundation + Vision + CoreML
// Fix: hardcoded nutrition lookup + debug logging

import AVFoundation
import Vision
import CoreML
import SwiftUI
import Combine

// ── Nutrition model ───────────────────────────────────────────
struct NutritionInfo {
    let protein_g : Float
    let calories  : Int
    let fat_g     : Float
    let carbs_g   : Float
}

// ── Hardcoded nutrition lookup ────────────────────────────────
// Keyed by CoreML classLabel output strings
private let nutritionDB: [String: NutritionInfo] = [
    "Chicken Curry"  : NutritionInfo(protein_g: 25.0, calories: 150, fat_g: 7.0,  carbs_g: 5.0),
    "Samosa"         : NutritionInfo(protein_g: 6.0,  calories: 262, fat_g: 15.0, carbs_g: 27.0),
    "Omelette"       : NutritionInfo(protein_g: 10.9, calories: 154, fat_g: 12.0, carbs_g: 0.4),
    "Egg"            : NutritionInfo(protein_g: 12.6, calories: 155, fat_g: 10.6, carbs_g: 1.1),
    "French Toast"   : NutritionInfo(protein_g: 8.0,  calories: 229, fat_g: 11.0, carbs_g: 26.0),
    "Fried Rice"     : NutritionInfo(protein_g: 4.4,  calories: 163, fat_g: 4.0,  carbs_g: 28.0),
    "Momos"          : NutritionInfo(protein_g: 7.0,  calories: 190, fat_g: 7.0,  carbs_g: 25.0),
    "Spring Rolls"   : NutritionInfo(protein_g: 4.0,  calories: 153, fat_g: 7.0,  carbs_g: 18.0),
    "Hot & Sour Soup": NutritionInfo(protein_g: 3.0,  calories: 95,  fat_g: 3.0,  carbs_g: 12.0),
    "Noodles"        : NutritionInfo(protein_g: 5.0,  calories: 138, fat_g: 2.0,  carbs_g: 25.0),
    "Chicken"        : NutritionInfo(protein_g: 27.0, calories: 203, fat_g: 12.0, carbs_g: 0.0),
    "Sandwich"       : NutritionInfo(protein_g: 18.0, calories: 290, fat_g: 11.0, carbs_g: 28.0),
    "Burger"         : NutritionInfo(protein_g: 20.3, calories: 295, fat_g: 14.0, carbs_g: 24.0),
    "Pizza"          : NutritionInfo(protein_g: 11.0, calories: 266, fat_g: 10.0, carbs_g: 33.0),
    "Fish"           : NutritionInfo(protein_g: 25.4, calories: 208, fat_g: 13.0, carbs_g: 0.0),
    "Hummus"         : NutritionInfo(protein_g: 7.9,  calories: 177, fat_g: 9.6,  carbs_g: 14.0),
    "Falafel"        : NutritionInfo(protein_g: 13.3, calories: 333, fat_g: 17.0, carbs_g: 32.0),
    "Pancakes"       : NutritionInfo(protein_g: 7.9,  calories: 291, fat_g: 12.0, carbs_g: 38.0),
    "Rice Bowl"      : NutritionInfo(protein_g: 12.0, calories: 190, fat_g: 5.0,  carbs_g: 28.0),
    "Steak"          : NutritionInfo(protein_g: 26.1, calories: 271, fat_g: 17.5, carbs_g: 0.0),
]

// ── Main classifier ───────────────────────────────────────────
final class FoodClassifier: NSObject, ObservableObject {

    @Published var label      : String         = ""
    @Published var confidence : Float          = 0.0
    @Published var nutrition  : NutritionInfo? = nil

    let session      = AVCaptureSession()
    private let videoOutput  = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "cam.session", qos: .userInitiated)
    private let inferQueue   = DispatchQueue(label: "cam.infer",   qos: .userInitiated)

    private var visionRequest: VNCoreMLRequest?
    private var frameCounter  = 0
    private let skipFrames    = 10   // run inference every 10 frames

    // Minimum confidence to show result
    private let threshold: Float = 0.40

    override init() {
        super.init()
        setupModel()
    }

    // ── CoreML + Vision setup ─────────────────────────────────
    private func setupModel() {
        do {
            // Use auto-generated class — no bundle lookup needed
            let config          = MLModelConfiguration()
            config.computeUnits = .cpuAndNeuralEngine

            // Xcode auto-generates ProteinLens class from .mlpackage
            let mlModel = try ProteinLens(configuration: config).model
            let vnModel = try VNCoreMLModel(for: mlModel)

            visionRequest = VNCoreMLRequest(model: vnModel) { [weak self] req, err in
                self?.handleResults(req, err)
            }
            visionRequest?.imageCropAndScaleOption = .centerCrop
            print("✅ CoreML model loaded via generated class")

        } catch {
            print("❌ CoreML setup error: \(error)")
        }
    }

    // ── Session start/stop ────────────────────────────────────
    func startSession() {
        sessionQueue.async { [weak self] in
            self?.configureSession()
            self?.session.startRunning()
            print("✅ Camera session started")
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        // Back camera
        guard
            let device = AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: .back),
            let input  = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            print("❌ Camera input failed")
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        print("✅ Camera input added")

        // Frame output
        videoOutput.setSampleBufferDelegate(self, queue: inferQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        guard session.canAddOutput(videoOutput) else {
            print("❌ Video output failed")
            session.commitConfiguration()
            return
        }
        session.addOutput(videoOutput)
        print("✅ Video output added")

        // Portrait orientation
        if let conn = videoOutput.connection(with: .video) {
            if conn.isVideoRotationAngleSupported(90) {
                conn.videoRotationAngle = 90
            }
        }

        session.commitConfiguration()
    }

    // ── Handle Vision results ─────────────────────────────────
    private func handleResults(_ request: VNRequest, _ error: Error?) {
        if let error {
            print("❌ Vision error: \(error)")
            return
        }

        guard
            let results   = request.results as? [VNClassificationObservation],
            let top       = results.first
        else {
            print("⚠️ No classification results")
            return
        }

        // Always log top 3 so we can debug
        let top3 = results.prefix(3)
        print("🔍 Top results:")
        for r in top3 {
            print("   \(r.identifier) → \(Int(r.confidence * 100))%")
        }

        // Only show if above threshold
        guard top.confidence >= threshold else {
            DispatchQueue.main.async { [weak self] in
                self?.label      = ""
                self?.confidence = 0
                self?.nutrition  = nil
            }
            return
        }

        let detectedLabel = top.identifier
        let detectedConf  = top.confidence
        let detectedNutr  = nutritionDB[detectedLabel]

        if detectedNutr == nil {
            print("⚠️ No nutrition data for: '\(detectedLabel)'")
            print("   Available keys: \(Array(nutritionDB.keys))")
        }

        DispatchQueue.main.async { [weak self] in
            self?.label      = detectedLabel
            self?.confidence = detectedConf
            self?.nutrition  = detectedNutr
        }
    }
}

// ── Sample buffer delegate ────────────────────────────────────
extension FoodClassifier: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        frameCounter += 1
        guard frameCounter % skipFrames == 0 else { return }

        guard
            let request     = visionRequest,
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }

        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .right,
            options: [:]
        )
        do {
            try handler.perform([request])
        } catch {
            print("❌ Inference error: \(error)")
        }
    }
}
