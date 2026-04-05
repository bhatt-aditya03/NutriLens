"""
ProteinLens — Day 3: Keras -> CoreML Conversion
Fix: Export to SavedModel first, then convert to CoreML
"""

import json, os, shutil
import numpy as np
import tensorflow as tf
import coremltools as ct
from PIL import Image

KERAS_MODEL_PATH = 'ProteinLens_model.keras'
SAVED_MODEL_PATH = 'ProteinLens_savedmodel'
COREML_OUTPUT    = 'ProteinLens.mlpackage'
LABEL_MAP_PATH   = 'label_map.json'

# ── Load label map ────────────────────────────────────────────
print('Loading label map...')
with open(LABEL_MAP_PATH) as f:
    label_map = json.load(f)

class_labels  = label_map['idx_to_display']
num_classes   = len(class_labels)
display_names = [class_labels[str(i)] for i in range(num_classes)]
protein_data  = label_map['idx_to_protein']

print(f'Classes      : {num_classes}')
print(f'Labels       : {display_names}')

# ── Load Keras model ──────────────────────────────────────────
print(f'\nLoading {KERAS_MODEL_PATH}...')
keras_model = tf.keras.models.load_model(KERAS_MODEL_PATH)

# Quick test
dummy = np.random.uniform(-1, 1, (1, 224, 224, 3)).astype(np.float32)
pred  = keras_model.predict(dummy, verbose=0)
print(f'Output shape : {pred.shape}')
print(f'Probs sum    : {pred.sum():.4f}')
print(f'Top class    : {display_names[np.argmax(pred)]}')

# ── Step 1: Export to SavedModel ──────────────────────────────
# This is the key fix — coremltools works with SavedModel, not .keras
print(f'\nStep 1: Exporting to SavedModel...')
if os.path.exists(SAVED_MODEL_PATH):
    shutil.rmtree(SAVED_MODEL_PATH)

# Build concrete function with fixed input shape
@tf.function(input_signature=[
    tf.TensorSpec(shape=(1, 224, 224, 3), dtype=tf.float32, name='image')
])
def serving_fn(image):
    return {'output': keras_model(image, training=False)}

tf.saved_model.save(
    keras_model,
    SAVED_MODEL_PATH,
    signatures={'serving_default': serving_fn}
)
print(f'SavedModel saved to: {SAVED_MODEL_PATH}')

# ── Step 2: Convert SavedModel to CoreML ──────────────────────
print(f'\nStep 2: Converting SavedModel to CoreML...')

image_input = ct.ImageType(
    name='image',
    shape=(1, 224, 224, 3),
    scale=1 / 127.5,
    bias=[-1.0, -1.0, -1.0],
    color_layout=ct.colorlayout.RGB,
    channel_first=False
)

coreml_model = ct.convert(
    SAVED_MODEL_PATH,
    source='tensorflow',
    inputs=[image_input],
    classifier_config=ct.ClassifierConfig(display_names),
    compute_units=ct.ComputeUnit.ALL,
    minimum_deployment_target=ct.target.iOS16,
)

# ── Add metadata ──────────────────────────────────────────────
print('Adding metadata...')
coreml_model.short_description = 'ProteinLens India — Food classifier 86% accuracy'
coreml_model.author            = 'Aditya Bhatt'
coreml_model.license           = 'MIT'
coreml_model.version           = '1.0'

nutrition_json = json.dumps({
    str(i): {
        'display' : display_names[i],
        'food_id' : label_map['idx_to_class'][str(i)],
        **protein_data[str(i)]
    }
    for i in range(num_classes)
})
coreml_model.user_defined_metadata['nutrition_data'] = nutrition_json
coreml_model.user_defined_metadata['num_classes']    = str(num_classes)
coreml_model.user_defined_metadata['model_version']  = '1.0'

# ── Save .mlpackage ───────────────────────────────────────────
if os.path.exists(COREML_OUTPUT):
    shutil.rmtree(COREML_OUTPUT)

print(f'\nSaving {COREML_OUTPUT}...')
coreml_model.save(COREML_OUTPUT)
print(f'Saved!')

# ── Verify ────────────────────────────────────────────────────
print('\nVerifying CoreML model...')
loaded = ct.models.MLModel(COREML_OUTPUT)

spec = loaded.get_spec()
print('Inputs :')
for inp in spec.description.input:
    print(f'  {inp.name}')
print('Outputs:')
for out in spec.description.output:
    print(f'  {out.name}')

# Test prediction
test_img = Image.fromarray(
    np.random.randint(0, 255, (224, 224, 3), dtype=np.uint8)
)
result = loaded.predict({'image': test_img})
label  = result.get('classLabel', 'unknown')
probs  = result.get('classLabelProbs', {})
top3   = sorted(probs.items(), key=lambda x: x[1], reverse=True)[:3]
print(f'\nTest prediction:')
for lbl, prob in top3:
    print(f'  {lbl:<20} {prob*100:.1f}%')

# Model size
total_size = sum(
    os.path.getsize(os.path.join(dp, f))
    for dp, dn, files in os.walk(COREML_OUTPUT)
    for f in files
)
print(f'\nModel size: {total_size/1024/1024:.1f} MB')

# Cleanup SavedModel temp folder
shutil.rmtree(SAVED_MODEL_PATH)
print(f'Cleaned up {SAVED_MODEL_PATH}')

print('\n' + '='*50)
print('Day 3 COMPLETE')
print('='*50)
print(f'Output : {COREML_OUTPUT}')
print('Next   : Drag ProteinLens.mlpackage into Xcode')
print('='*50)
