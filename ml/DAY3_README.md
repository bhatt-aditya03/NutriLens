# Day 3 — CoreML Conversion

Convert `ProteinLens_model.keras` → `ProteinLens.mlpackage`

---

## Prerequisites

Make sure these are in your `ml/` folder:
- `ProteinLens_model.keras` (downloaded from Kaggle)
- `label_map.json` (downloaded from Kaggle)
- `convert_to_coreml.py` (this folder)

---

## Step 1 — Set up Python environment on your Mac

```bash
# Create a fresh conda env
conda create -n coreml_env python=3.10 -y
conda activate coreml_env

# Install dependencies
# tensorflow-macos for M4, coremltools for conversion
pip install tensorflow-macos coremltools Pillow numpy
```

> **Why Python 3.10?** coremltools 7.x works best with Python 3.10.
> Python 3.11+ can cause compatibility issues.

---

## Step 2 — Run the conversion

```bash
cd ~/ProteinLens/ml
conda activate coreml_env

python convert_to_coreml.py
```

Expected output:
```
Loading label map...
Classes      : 20
Loading ProteinLens_model.keras...
Testing Keras model with random input...
Output shape : (1, 20)  ✓
Converting to CoreML...
Adding metadata...
Saving to ProteinLens.mlpackage...
Verifying CoreML model...
Model size: ~14.2 MB
Day 3 DONE
```

---

## Step 3 — Verify the model

```bash
python verify_mlpackage.py
```

Should print 5 test predictions without errors.

---

## Step 4 — Git push

```bash
cd ~/ProteinLens

# .mlpackage is a folder — git tracks it fine
git add ml/ProteinLens.mlpackage
git add ml/convert_to_coreml.py
git add ml/verify_mlpackage.py

git commit -m "Day 3: Keras model converted to CoreML (.mlpackage)"
git push origin main
```

> Note: If the .mlpackage is over 100MB, add it to .gitignore
> and store it in Google Drive instead.

---

## What the conversion does

```
ProteinLens_model.keras
        │
        │  coremltools.convert()
        │  - Sets input: image [224x224 RGB]
        │  - Sets preprocessing: scale 1/127.5, bias -1.0
        │    (matches MobileNetV2 preprocess_input)
        │  - Sets output: classLabel + classLabelProbs
        │  - Targets iOS 16+, uses Neural Engine
        ▼
ProteinLens.mlpackage/
├── Data/
│   └── com.apple.CoreML/
│       └── model.mlmodel
└── Manifest.json
```

---

## Day 4 preview

Tomorrow you'll:
1. Open Xcode → New Project → iOS App
2. Drag `ProteinLens.mlpackage` into the project
3. Set up `AVFoundation` camera with `AVCaptureSession`
4. Use `Vision` framework to run `VNCoreMLRequest` on live frames
5. Display results on screen

The model input is already set to accept `CVPixelBuffer` from
the camera — no manual preprocessing needed in Swift.
