# NutriLens 🔍🍽️

> **Real-time on-device Indian food classification iOS app**  
> Point your camera at food — get instant nutrition estimates. No internet required.

![Swift](https://img.shields.io/badge/Swift-5.9-orange?logo=swift&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python&logoColor=white)
![TensorFlow](https://img.shields.io/badge/TensorFlow-2.19-FF6F00?logo=tensorflow&logoColor=white)
![CoreML](https://img.shields.io/badge/CoreML-on--device-black?logo=apple&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-17%2B-lightgrey?logo=apple&logoColor=white)
![Accuracy](https://img.shields.io/badge/Accuracy-86.4%25-brightgreen)
![Classes](https://img.shields.io/badge/Classes-30-blue)
![Model Size](https://img.shields.io/badge/Model-5.9MB-blue)
![Dataset](https://img.shields.io/badge/Dataset-IndianFoodDB--30-orange)
![License](https://img.shields.io/badge/License-MIT-green)

---

## Demo

![NutriLens Demo](assets/NutriLens.gif)

---

## What it does

NutriLens uses a custom-trained **MobileNetV2 CNN** trained on **IndianFoodDB-30** — a curated dataset of 30 Indian food classes — to classify food in real time via the iPhone camera. Built specifically for Indian home cooking, street food, and everyday meals.

**Live detection shows:**
- 🍽️ Food name with confidence score
- 💪 Protein / Calories / Fat / Carbs per serving
- ⚖️ Serving size slider — scale from 50g to 500g live
- 🕐 Scan history with daily protein and calorie totals
- ❄️ Tap anywhere to freeze frame and adjust serving size

**Everything runs on-device** — no API calls, no latency, no data leaving your phone.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     NutriLens App                        │
├──────────────────┬──────────────────────────────────────┤
│   Training (ML)  │           iOS App (Swift)             │
│                  │                                       │
│  IndianFoodDB-30 │  AVFoundation → live camera frames    │
│  (5,191 images)  │         ↓                             │
│     ↓            │  Vision Framework → VNCoreMLRequest   │
│  MobileNetV2     │         ↓                             │
│  fine-tuned      │  CoreML → NutriLens_v2.mlpackage      │
│  (TensorFlow)    │         ↓                             │
│     ↓            │  SwiftUI → nutrition card overlay     │
│  coremltools     │         ↓                             │
│  conversion      │  ScanHistory → daily totals           │
│     ↓            │                                       │
│  .mlpackage      │                                       │
│  (5.9 MB)        │                                       │
└──────────────────┴──────────────────────────────────────┘
```

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
| On-device storage | In-memory | Scan history, daily totals |
| Deployment | CoreML, Neural Engine | Runs fully offline on iPhone |

---

## Model Performance

| Metric | Value |
|---|---|
| Architecture | MobileNetV2 (ImageNet pretrained, fine-tuned) |
| Training strategy | Two-phase: head only → top-layer fine-tuning |
| Dataset | IndianFoodDB-30 (5,191 images, 30 classes) |
| Training platform | Kaggle T4 x2 GPU |
| Phase 1 best accuracy | 84.0% |
| Phase 2 best accuracy | **86.4%** |
| Model size | 5.9 MB (.mlpackage) |
| Inference speed | < 50ms on iPhone (Neural Engine) |
| Confidence threshold | 40% |

---

## 30 Food Classes (IndianFoodDB-30)

| # | Food | Protein/100g | Calories/100g |
|---|---|---|---|
| 1 | Biryani 🍛 | 14.0g | 198 kcal |
| 2 | Dal Tadka 🫘 | 9.0g | 116 kcal |
| 3 | Dal Makhani 🫘 | 8.0g | 130 kcal |
| 4 | Palak Paneer 🥬 | 8.0g | 120 kcal |
| 5 | Paneer Butter Masala 🧀 | 10.0g | 180 kcal |
| 6 | Butter Chicken 🍗 | 16.0g | 150 kcal |
| 7 | Chana Masala 🫘 | 9.0g | 140 kcal |
| 8 | Dum Aloo 🥔 | 3.0g | 130 kcal |
| 9 | Aloo Tikki 🥔 | 3.0g | 150 kcal |
| 10 | Poha 🍚 | 3.0g | 130 kcal |
| 11 | Naan 🫓 | 9.0g | 310 kcal |
| 12 | Chapati 🫓 | 8.0g | 264 kcal |
| 13 | Dosa 🫓 | 4.0g | 168 kcal |
| 14 | Idli 🍚 | 3.0g | 58 kcal |
| 15 | Samosa 🥟 | 6.0g | 262 kcal |
| 16 | Pani Puri 🫧 | 3.0g | 180 kcal |
| 17 | Pav Bhaji 🍞 | 4.0g | 150 kcal |
| 18 | Dhokla 🟡 | 5.0g | 160 kcal |
| 19 | Jalebi 🍬 | 2.0g | 380 kcal |
| 20 | Gulab Jamun 🍮 | 4.0g | 340 kcal |
| 21 | Kheer 🍮 | 5.0g | 180 kcal |
| 22 | Rasgulla 🍮 | 5.0g | 186 kcal |
| 23 | Ras Malai 🍮 | 6.0g | 195 kcal |
| 24 | Kachori 🥟 | 5.0g | 280 kcal |
| 25 | Bhindi Masala 🫑 | 3.0g | 90 kcal |
| 26 | Gajar Ka Halwa 🥕 | 4.0g | 250 kcal |
| 27 | Modak 🍮 | 3.0g | 170 kcal |
| 28 | Vada 🍩 | 6.0g | 220 kcal |
| 29 | Kadai Paneer 🧀 | 11.0g | 175 kcal |
| 30 | Rajma 🫘 | 9.0g | 144 kcal |

---

## Dataset — IndianFoodDB-30

Built by merging two Kaggle datasets:

| Source | Classes | Images |
|---|---|---|
| iamsouravbanerjee/indian-food-images-dataset | 80 | ~4,000 |
| ps2004/food-dataset | 30 | ~6,000 |
| **Merged + deduped** | **30** | **5,191** |

Deduplication via MD5 hash. Corrupt images filtered using PIL validation.

---

## Project Structure

```
NutriLens/
├── ml/
│   ├── train.ipynb                  # MobileNetV2 training (Kaggle)
│   ├── convert_to_coreml.py         # Keras → CoreML v2 conversion
│   ├── convert_to_coreml_v1.py      # v1 conversion (reference)
│   ├── verify_mlpackage.py          # Model verification script
│   ├── label_map.json               # v1 class labels
│   ├── label_map_v2.json            # v2 class labels + model info
│   ├── NutriLens.mlpackage/         # v1 CoreML model (5.9MB)
│   └── NutriLens_v2.mlpackage/      # v2 CoreML model (5.9MB)
├── iOS/
│   └── NutriLens/
│       └── NutriLens/
│           ├── FoodClassifier.swift     # AVFoundation + Vision + CoreML
│           ├── CameraView.swift         # SwiftUI camera overlay
│           ├── CameraPreview.swift      # AVCaptureVideoPreviewLayer
│           ├── HistoryView.swift        # Scan history screen
│           ├── ScanHistory.swift        # History data model
│           └── ContentView.swift        # Entry point
├── assets/
│   ├── NutriLens.gif            # Demo recording
│   ├── training_curves.png      # Loss + accuracy curves
│   └── confusion_matrix.png     # Per-class accuracy heatmap
└── README.md
```

---

## Training Curves

![Training Curves](assets/training_curves.png)

---

## Confusion Matrix

![Confusion Matrix](assets/confusion_matrix.png)

---

## Resume Headline

> **NutriLens** — Built a real-time on-device food classification iOS app using a custom-trained MobileNetV2 CNN (86.4% accuracy) on IndianFoodDB-30, a self-curated dataset of 5,191 images across 30 Indian food classes. Deployed as a 5.9MB CoreML model running fully offline on iPhone using AVFoundation + Vision framework + SwiftUI.

---

## How to run

### ML (training + conversion)
```bash
cd ml/
conda create -n coreml_env python=3.10 -y
conda activate coreml_env
pip install tensorflow-macos coremltools Pillow numpy

python convert_to_coreml.py
python verify_mlpackage.py
```

### iOS app
1. Open `iOS/NutriLens/NutriLens.xcodeproj` in Xcode 16
2. Select your iPhone as target
3. `Cmd+R` to build and run
4. Grant camera permission on first launch

---

## Author

**Aditya Bhatt** — B.Tech CSE (Data Science), PSIT Kanpur  
[github.com/bhatt-aditya03](https://github.com/bhatt-aditya03) · [linkedin.com/in/bhatt-aditya03](https://linkedin.com/in/bhatt-aditya03)
