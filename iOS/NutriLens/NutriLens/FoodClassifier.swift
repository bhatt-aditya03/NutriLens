// FoodClassifier.swift
// NutriLens v2 — 30 Indian Food Classes
// Model: NutriLens_v2.mlpackage (86.4% accuracy, IndianFoodDB-30)

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

// ── Nutrition DB — 30 Indian food classes (per 100g, USDA/NIN) ──
private let nutritionDB: [String: NutritionInfo] = [
    "Biryani"             : NutritionInfo(protein_g: 14.0, calories: 198, fat_g: 7.0,  carbs_g: 28.0),
    "Dal Tadka"           : NutritionInfo(protein_g: 9.0,  calories: 116, fat_g: 4.0,  carbs_g: 15.0),
    "Dal Makhani"         : NutritionInfo(protein_g: 8.0,  calories: 130, fat_g: 6.0,  carbs_g: 14.0),
    "Palak Paneer"        : NutritionInfo(protein_g: 8.0,  calories: 120, fat_g: 8.0,  carbs_g: 6.0),
    "Paneer Butter Masala": NutritionInfo(protein_g: 10.0, calories: 180, fat_g: 12.0, carbs_g: 10.0),
    "Butter Chicken"      : NutritionInfo(protein_g: 16.0, calories: 150, fat_g: 8.0,  carbs_g: 7.0),
    "Chana Masala"        : NutritionInfo(protein_g: 9.0,  calories: 140, fat_g: 4.0,  carbs_g: 20.0),
    "Dum Aloo"            : NutritionInfo(protein_g: 3.0,  calories: 130, fat_g: 6.0,  carbs_g: 18.0),
    "Aloo Tikki"          : NutritionInfo(protein_g: 3.0,  calories: 150, fat_g: 7.0,  carbs_g: 20.0),
    "Poha"                : NutritionInfo(protein_g: 3.0,  calories: 130, fat_g: 3.0,  carbs_g: 24.0),
    "Naan"                : NutritionInfo(protein_g: 9.0,  calories: 310, fat_g: 8.0,  carbs_g: 50.0),
    "Chapati"             : NutritionInfo(protein_g: 8.0,  calories: 264, fat_g: 4.0,  carbs_g: 52.0),
    "Dosa"                : NutritionInfo(protein_g: 4.0,  calories: 168, fat_g: 5.0,  carbs_g: 27.0),
    "Idli"                : NutritionInfo(protein_g: 3.0,  calories: 58,  fat_g: 0.5,  carbs_g: 12.0),
    "Samosa"              : NutritionInfo(protein_g: 6.0,  calories: 262, fat_g: 15.0, carbs_g: 27.0),
    "Pani Puri"           : NutritionInfo(protein_g: 3.0,  calories: 180, fat_g: 5.0,  carbs_g: 30.0),
    "Pav Bhaji"           : NutritionInfo(protein_g: 4.0,  calories: 150, fat_g: 6.0,  carbs_g: 22.0),
    "Dhokla"              : NutritionInfo(protein_g: 5.0,  calories: 160, fat_g: 5.0,  carbs_g: 24.0),
    "Jalebi"              : NutritionInfo(protein_g: 2.0,  calories: 380, fat_g: 14.0, carbs_g: 60.0),
    "Gulab Jamun"         : NutritionInfo(protein_g: 4.0,  calories: 340, fat_g: 14.0, carbs_g: 48.0),
    "Kheer"               : NutritionInfo(protein_g: 5.0,  calories: 180, fat_g: 6.0,  carbs_g: 28.0),
    "Rasgulla"            : NutritionInfo(protein_g: 5.0,  calories: 186, fat_g: 4.0,  carbs_g: 34.0),
    "Ras Malai"           : NutritionInfo(protein_g: 6.0,  calories: 195, fat_g: 8.0,  carbs_g: 26.0),
    "Kachori"             : NutritionInfo(protein_g: 5.0,  calories: 280, fat_g: 14.0, carbs_g: 34.0),
    "Bhindi Masala"       : NutritionInfo(protein_g: 3.0,  calories: 90,  fat_g: 5.0,  carbs_g: 9.0),
    "Gajar Ka Halwa"      : NutritionInfo(protein_g: 4.0,  calories: 250, fat_g: 10.0, carbs_g: 36.0),
    "Modak"               : NutritionInfo(protein_g: 3.0,  calories: 170, fat_g: 5.0,  carbs_g: 30.0),
    "Vada"                : NutritionInfo(protein_g: 6.0,  calories: 220, fat_g: 11.0, carbs_g: 25.0),
    "Kadai Paneer"        : NutritionInfo(protein_g: 11.0, calories: 175, fat_g: 12.0, carbs_g: 8.0),
    "Rajma"               : NutritionInfo(protein_g: 9.0,  calories: 144, fat_g: 3.0,  carbs_g: 22.0),
]

// ── Main classifier ───────────────────────────────────────────
final class FoodClassifier: NSObject, ObservableObject {

    @Published var label      : String         = ""
    @Published var confidence : Float          = 0.0
    @Published var nutrition  : NutritionInfo? = nil

    let session      = AVCaptureSession()
    private let videoOutput   = AVCaptureVideoDataOutput()
    private let sessionQueue  = DispatchQueue(label: "cam.session", qos: .userInitiated)
    private let inferQueue    = DispatchQueue(label: "cam.infer",   qos: .userInitiated)

    private var visionRequest    : VNCoreMLRequest?
    private var frameCounter     = 0
    private let skipFrames       = 10
    private let threshold        : Float = 0.40

    private var sessionConfigured = false
    private var configSucceeded   = false
    private var inferenceActive   = true

    override init() {
        super.init()
        setupModel()
    }

    // ── Freeze / resume ───────────────────────────────────────
    func pauseInference() {
        inferenceActive = false
    }

    func resumeInference() {
        inferenceActive = true
        DispatchQueue.main.async { [weak self] in
            self?.label      = ""
            self?.confidence = 0
            self?.nutrition  = nil
        }
    }

    // ── CoreML + Vision setup ─────────────────────────────────
    private func setupModel() {
        do {
            let config          = MLModelConfiguration()
            config.computeUnits = .cpuAndNeuralEngine

            // v2 model — 30 Indian food classes
            let mlModel         = try NutriLens_v2(configuration: config).model
            let vnModel         = try VNCoreMLModel(for: mlModel)

            visionRequest = VNCoreMLRequest(model: vnModel) { [weak self] req, err in
                self?.handleResults(req, err)
            }
            visionRequest?.imageCropAndScaleOption = .centerCrop

            #if DEBUG
            print("✅ NutriLens v2 loaded — 30 Indian food classes")
            #endif

        } catch {
            #if DEBUG
            print("❌ CoreML setup error: \(error)")
            #endif
        }
    }

    // ── Session lifecycle ─────────────────────────────────────
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.sessionConfigured {
                self.configSucceeded   = self.configureSession()
                self.sessionConfigured = true
            }
            guard self.configSucceeded, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    @discardableResult
    private func configureSession() -> Bool {
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        guard
            let device = AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: .back),
            let input  = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            return false
        }
        session.addInput(input)

        videoOutput.setSampleBufferDelegate(self, queue: inferQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        guard session.canAddOutput(videoOutput) else {
            session.commitConfiguration()
            return false
        }
        session.addOutput(videoOutput)

        if let conn = videoOutput.connection(with: .video),
           conn.isVideoRotationAngleSupported(90) {
            conn.videoRotationAngle = 90
        }

        session.commitConfiguration()
        return true
    }

    // ── Inference results ─────────────────────────────────────
    private func handleResults(_ request: VNRequest, _ error: Error?) {
        if let error {
            #if DEBUG
            print("❌ Vision error: \(error)")
            #endif
            return
        }

        guard
            let results = request.results as? [VNClassificationObservation],
            let top     = results.first
        else { return }

        #if DEBUG
        results.prefix(3).forEach {
            print("🔍 \($0.identifier): \(Int($0.confidence * 100))%")
        }
        #endif

        guard top.confidence >= threshold else {
            DispatchQueue.main.async { [weak self] in
                self?.label      = ""
                self?.confidence = 0
                self?.nutrition  = nil
            }
            return
        }

        let detectedNutrition = nutritionDB[top.identifier]

        DispatchQueue.main.async { [weak self] in
            self?.label      = top.identifier
            self?.confidence = top.confidence
            self?.nutrition  = detectedNutrition
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
        guard inferenceActive else { return }
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
            #if DEBUG
            print("❌ Inference error: \(error)")
            #endif
        }
    }
}
