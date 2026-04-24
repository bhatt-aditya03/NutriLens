# NutriLens 🔍🍽️

![ML Tests](https://github.com/bhatt-aditya03/NutriLens/actions/workflows/ml.yml/badge.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?logo=swift&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python&logoColor=white)
![TensorFlow](https://img.shields.io/badge/TensorFlow-2.19-FF6F00?logo=tensorflow&logoColor=white)
![CoreML](https://img.shields.io/badge/CoreML-on--device-black?logo=apple&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-17%2B-lightgrey?logo=apple&logoColor=white)
![Accuracy](https://img.shields.io/badge/Accuracy-86.4%25-brightgreen)
![Classes](https://img.shields.io/badge/Classes-30-blue)
![Model](https://img.shields.io/badge/Model-5.9MB-blue)
![License](https://img.shields.io/badge/License-MIT-green)

Real-time on-device Indian food classification iOS app. Point your camera at food — get instant nutrition estimates. No internet required.

**iOS App:** See `/iOS` — SwiftUI + CoreML, runs on iOS 17+

> **Disclaimer:** Nutrition values are approximate per-100g averages sourced from IFCT 2017 and USDA FoodData Central. Values vary by recipe and preparation. Not intended for medical or clinical dietary use.

---

## Demo

<p align="center">
  <img src="assets/NutriLens.gif" alt="NutriLens Demo" width="280"/>
</p>

---

## Architecture

```
iPhone Camera (AVFoundation)
        ↓
CameraPreview — AVCaptureVideoPreviewLayer
        ↓  CVPixelBuffer @ ~6 fps (1 in 10 frames)
Vision Framework — VNCoreMLRequest (centerCrop)
        ↓
CoreML — NutriLens_v2.mlpackage (Neural Engine)
        ↓
{ label: "Biryani", confidence: 0.94 }
        ↓
FoodClassifier (ObservableObject) → SwiftUI overlay
        ↓
DetectionCard — nutrition scaled by serving size slider
        ↓
ScanHistoryStore — daily protein + calorie totals
```

---

## Model

| Property | Value |
|---|---|
| Architecture | MobileNetV2 (ImageNet pretrained) |
| Training strategy | Two-phase: head only → top-layer fine-tuning |
| Dataset | IndianFoodDB-30 (5,191 images, 30 classes) |
| Training platform | Kaggle T4 x2 GPU |
| Phase 1 val accuracy | 84.0% |
| Phase 2 val accuracy | **86.4%** |
| Model size | 5.9 MB (.mlpackage) |
| Inference speed | < 50ms (Neural Engine, iPhone 17) |
| Confidence threshold | 40% |

**Nutrition scaling:** `displayed_value = base_per_100g × (serving_grams / 100)`. All values are linearly scaled from the per-100g baseline in `label_map_v2.json`. Actual nutrition varies non-linearly with preparation — this is an intentional approximation for demo clarity.

---

## Tech Stack

| Layer | Technology | Detail |
|---|---|---|
| Model training | Python, TensorFlow 2.19, Keras | MobileNetV2 fine-tuned on IndianFoodDB-30 |
| Dataset | IndianFoodDB-30 (custom) | 30 classes, 5,191 images, 2 sources merged |
| Model conversion | coremltools 7.2 | Keras → SavedModel → .mlpackage |
| iOS camera | AVFoundation | AVCaptureSession, live frames |
| iOS inference | Vision framework | VNCoreMLRequest, centerCrop |
| iOS UI | SwiftUI | Live overlay, serving size slider, history |
| CI | GitHub Actions | pytest, 7 tests on every push to ml/ |
| Deployment | CoreML, Neural Engine | Runs fully offline on iPhone |

---

## 30 Food Classes (IndianFoodDB-30)

| # | Food | Protein/100g | Calories/100g |
|---|---|---|---|
| 1 | Biryani | 14.0g | 198 kcal |
| 2 | Dal Tadka | 9.0g | 116 kcal |
| 3 | Dal Makhani | 8.0g | 130 kcal |
| 4 | Palak Paneer | 8.0g | 120 kcal |
| 5 | Paneer Butter Masala | 10.0g | 180 kcal |
| 6 | Butter Chicken | 16.0g | 150 kcal |
| 7 | Chana Masala | 9.0g | 140 kcal |
| 8 | Dum Aloo | 3.0g | 130 kcal |
| 9 | Aloo Tikki | 3.0g | 150 kcal |
| 10 | Poha | 3.0g | 130 kcal |
| 11 | Naan | 9.0g | 310 kcal |
| 12 | Chapati | 8.0g | 264 kcal |
| 13 | Dosa | 4.0g | 168 kcal |
| 14 | Idli | 3.0g | 58 kcal |
| 15 | Samosa | 6.0g | 262 kcal |
| 16 | Pani Puri | 3.0g | 180 kcal |
| 17 | Pav Bhaji | 4.0g | 150 kcal |
| 18 | Dhokla | 5.0g | 160 kcal |
| 19 | Jalebi | 2.0g | 380 kcal |
| 20 | Gulab Jamun | 4.0g | 340 kcal |
| 21 | Kheer | 5.0g | 180 kcal |
| 22 | Rasgulla | 5.0g | 186 kcal |
| 23 | Ras Malai | 6.0g | 195 kcal |
| 24 | Kachori | 5.0g | 280 kcal |
| 25 | Bhindi Masala | 3.0g | 90 kcal |
| 26 | Gajar Ka Halwa | 4.0g | 250 kcal |
| 27 | Modak | 3.0g | 170 kcal |
| 28 | Vada | 6.0g | 220 kcal |
| 29 | Kadai Paneer | 11.0g | 175 kcal |
| 30 | Rajma | 9.0g | 144 kcal |

Values from IFCT 2017 and USDA FoodData Central, averaged across common preparations.

---

## Dataset — IndianFoodDB-30

Built by merging two Kaggle datasets and deduplicating via MD5 hash:

| Source | Classes | Images |
|---|---|---|
| iamsouravbanerjee/indian-food-images-dataset | 80 | ~4,000 |
| ps2004/food-dataset | 30 | ~6,000 |
| **Merged + deduped** | **30** | **5,191** |

Corrupt images filtered using PIL validation. 9 classes have only 50 images (DS1-only) — their weaker accuracy is visible in the confusion matrix diagonal.

---

## ML Engineering Notes

- **Two-phase training** — base frozen in Phase 1 so the randomly-initialised head converges without corrupting ImageNet features. Phase 2 unfreezes top 54 layers at 20× lower LR (5e-5). This gave +2.4% over single-phase training.
- **PIL-based pipeline** — `tf.py_function` wrapping PIL instead of `tf.image.decode_jpeg` handles corrupt/misformatted images in the merged dataset without crashing the pipeline. A filter step drops zero-valued images that failed to load.
- **SavedModel intermediate** — coremltools 7.2 cannot introspect `.keras` format on TF 2.16+ due to a missing `_get_save_spec` method. Exporting to SavedModel first with a concrete `@tf.function` input signature works around this.
- **MD5 deduplication** — prevents the same image appearing in both train and val splits across the two merged source datasets.
- **IndianFoodDB-30 over Food-101** — Food-101 is a Western restaurant dataset. Samosas and biryani in it look like restaurant plating, not home cooking. A model trained on it would fail on real Indian household food.

---

## iOS Engineering Notes

- **Idempotent camera session** — `sessionConfigured` flag prevents `AVCaptureSession` from being reconfigured on repeated view appear/disappear cycles when the user backgrounds the app.
- **Frame throttling** — inference runs every 10th frame (~6/sec at 60fps). Balances responsiveness against battery drain.
- **40% confidence threshold** — below this the detection card is hidden. 40% is well above the 3.3% random baseline for 30 classes; lower values caused noisy detections in real use.
- **centerCrop** — `VNCoreMLRequest.imageCropAndScaleOption = .centerCrop` matches the preprocessing used during training.
- **`#if DEBUG` logging** — all inference `print()` calls are compile-time stripped in release builds to eliminate logging overhead.
- **Portrait lock** — `videoRotationAngle = 90` applied to the video connection so portrait camera output reaches the model in the correct orientation.

---

## Project Structure

```
NutriLens/
├── .github/
│   └── workflows/
│       └── ml.yml                   # GitHub Actions — pytest on every push to ml/
├── ml/
│   ├── tests/
│   │   └── test_conversion.py       # 7 smoke tests (label map + CoreML structure)
│   ├── train.ipynb                  # MobileNetV2 training — Kaggle T4 x2
│   ├── convert_to_coreml.py         # Keras → SavedModel → .mlpackage
│   ├── verify_mlpackage.py          # Post-conversion verification script
│   ├── label_map_v2.json            # Class labels, display names, model metadata
│   ├── requirements-train.txt       # Kaggle training environment (Linux, T4)
│   ├── requirements-convert.txt     # CoreML conversion environment (Mac M-series)
│   └── NutriLens_v2.mlpackage/      # CoreML model (5.9MB)
├── iOS/
│   └── NutriLens/
│       └── NutriLens/
│           ├── FoodClassifier.swift     # AVFoundation + Vision + CoreML
│           ├── CameraView.swift         # SwiftUI overlay + detection card
│           ├── CameraPreview.swift      # UIViewRepresentable — preview layer
│           ├── HistoryView.swift        # Scan history screen
│           ├── ScanHistory.swift        # ScanEntry + ScanHistoryStore
│           └── ContentView.swift        # Entry point
├── assets/
│   ├── NutriLens.gif                # Full feature demo (1 min)
│   ├── training_curves.png          # Phase 1 + Phase 2 accuracy/loss
│   └── confusion_matrix.png         # Per-class accuracy heatmap
├── CHANGELOG.md
├── LICENSE
└── README.md
```

---

## Limitations

- **30 classes only** — foods outside this set are misclassified silently
- **Visually similar dishes** — orange gravies (Paneer Butter Masala, Butter Chicken, Chana Masala) and white milk-based sweets (Ras Malai, Rasgulla, Kheer) are the weakest clusters in the confusion matrix
- **Nutrition values are approximate** — per-100g averages vary significantly by recipe, cook, and region
- **No persistence** — scan history resets when the app is closed (in-memory only)
- **Lighting dependent** — poor lighting or extreme angles reduce detection confidence
- **Training data skew** — 9 classes with only 50 training images have lower diagonal values in the confusion matrix vs data-rich classes

---

## Training Curves

<p align="center">
  <img src="assets/training_curves.png" alt="Training Curves" width="800"/>
</p>

---

## Confusion Matrix

<p align="center">
  <img src="assets/confusion_matrix.png" alt="Confusion Matrix" width="800"/>
</p>

---

## How to Run

### Training (Kaggle)
```bash
# Upload train.ipynb to Kaggle
# Add datasets: iamsouravbanerjee/indian-food-images-dataset, ps2004/food-dataset
# Runtime: GPU T4 x2 — ~45 mins
# Output: NutriLens_v2.keras, label_map_v2.json
```

### CoreML Conversion (Mac M-series)
```bash
cd ml/
conda create -n coreml_env python=3.10 -y
conda activate coreml_env
pip install -r requirements-convert.txt

python convert_to_coreml.py   # outputs NutriLens_v2.mlpackage
python verify_mlpackage.py    # smoke test
```

### iOS App
1. Open `iOS/NutriLens/NutriLens.xcodeproj` in Xcode 
2. Select your iPhone as target (iOS 17+ required)
3. `Cmd+R` — grant camera permission on first launch

### Tests
```bash
pip install pytest numpy Pillow
pytest ml/tests/ -v
```

---

## Author

**Aditya Bhatt** 