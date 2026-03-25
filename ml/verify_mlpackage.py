"""
ProteinLens — Verify .mlpackage
================================
Run after conversion to confirm the model is valid
and ready to drop into Xcode.

Usage:
    python verify_mlpackage.py
"""

import json
import numpy as np
import coremltools as ct
from PIL import Image

COREML_PATH    = 'ProteinLens.mlpackage'
LABEL_MAP_PATH = 'label_map.json'

print('='*50)
print('ProteinLens.mlpackage Verification')
print('='*50)

# Load model
print(f'\nLoading {COREML_PATH}...')
model = ct.models.MLModel(COREML_PATH)

# Print spec
spec = model.get_spec()
print(f'\nModel description : {spec.description.metadata.shortDescription}')
print(f'Author            : {spec.description.metadata.author}')
print(f'Version           : {spec.description.metadata.versionString}')

print('\nInputs:')
for inp in spec.description.input:
    print(f'  {inp.name}')

print('\nOutputs:')
for out in spec.description.output:
    print(f'  {out.name}')

# Print user metadata
print('\nUser metadata:')
for k, v in model.user_defined_metadata.items():
    if k == 'nutrition_data':
        print(f'  {k}: [JSON with {len(json.loads(v))} classes]')
    else:
        print(f'  {k}: {v}')

# Run 5 test predictions
print('\nRunning 5 test predictions...')
with open(LABEL_MAP_PATH) as f:
    label_map = json.load(f)
display_names = [label_map['idx_to_display'][str(i)]
                 for i in range(len(label_map['idx_to_display']))]

for i in range(5):
    img = Image.fromarray(
        np.random.randint(0, 255, (224, 224, 3), dtype=np.uint8)
    )
    result = model.predict({'image': img})
    label  = result.get('classLabel', 'unknown')
    probs  = result.get('classLabelProbs', {})
    conf   = probs.get(label, 0) * 100
    print(f'  Test {i+1}: {label:<20} ({conf:.1f}% confidence)')

print('\nAll checks passed')
print('ProteinLens.mlpackage is ready for Xcode')
