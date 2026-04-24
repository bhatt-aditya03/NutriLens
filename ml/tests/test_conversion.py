# ml/tests/test_conversion.py
# Smoke tests for NutriLens CoreML model and label map
# Run: pytest ml/tests/ -v

import json
import pytest
import numpy as np
from pathlib import Path

ML_DIR      = Path(__file__).parent.parent
MLPACKAGE   = ML_DIR / 'NutriLens_v2.mlpackage'
LABEL_MAP   = ML_DIR / 'label_map_v2.json'
NUM_CLASSES = 30

# ── Label map tests ───────────────────────────────────────────
def test_label_map_exists():
    assert LABEL_MAP.exists(), f"label_map_v2.json not found at {LABEL_MAP}"

def test_label_map_has_30_classes():
    with open(LABEL_MAP) as f:
        lm = json.load(f)
    assert len(lm['target_classes']) == NUM_CLASSES

def test_label_map_idx_to_display_complete():
    with open(LABEL_MAP) as f:
        lm = json.load(f)
    for i in range(NUM_CLASSES):
        assert str(i) in lm['idx_to_display'], f"Missing idx {i} in idx_to_display"

def test_label_map_no_empty_labels():
    with open(LABEL_MAP) as f:
        lm = json.load(f)
    for k, v in lm['idx_to_display'].items():
        assert v.strip() != '', f"Empty display name at index {k}"

def test_label_map_accuracy_recorded():
    with open(LABEL_MAP) as f:
        lm = json.load(f)
    acc = lm['model_info']['val_accuracy']
    assert acc > 0.80, f"Recorded accuracy {acc} is suspiciously low"

# ── CoreML model tests ────────────────────────────────────────
def test_mlpackage_exists():
    assert MLPACKAGE.exists(), f"NutriLens_v2.mlpackage not found at {MLPACKAGE}"

def test_mlpackage_has_required_files():
    assert (MLPACKAGE / 'Manifest.json').exists()
    assert (MLPACKAGE / 'Data' / 'com.apple.CoreML' / 'model.mlmodel').exists()

def test_mlpackage_manifest_version():
    with open(MLPACKAGE / 'Manifest.json') as f:
        manifest = json.load(f)
    assert 'itemInfoEntries' in manifest or 'rootModelIdentifier' in manifest, \
        "Manifest.json missing expected keys"

@pytest.mark.skipif(
    not __import__('importlib').util.find_spec('coremltools'),
    reason="coremltools not installed"
)
def test_coreml_model_loads_and_predicts():
    import coremltools as ct
    from PIL import Image

    model = ct.models.MLModel(str(MLPACKAGE))

    # Test with random image
    img    = Image.fromarray(np.random.randint(0, 255, (224, 224, 3), dtype=np.uint8))
    result = model.predict({'image': img})

    assert 'classLabel' in result, "classLabel missing from model output"
    assert 'classLabel_probs' in result, "classLabel_probs missing from model output"

    probs = result['classLabel_probs']
    assert len(probs) == NUM_CLASSES, f"Expected {NUM_CLASSES} classes, got {len(probs)}"

    total = sum(probs.values())
    assert abs(total - 1.0) < 0.01, f"Probabilities don't sum to 1.0: {total}"

    top_label = result['classLabel']
    assert top_label in probs, f"Top label '{top_label}' not in probs dict"
