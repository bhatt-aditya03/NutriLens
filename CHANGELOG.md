# Changelog

All notable changes to NutriLens are documented here.

---

## v2.0 — IndianFoodDB-30 (April 2026)

### Changed
- Replaced Food-101 (Western dataset) with **IndianFoodDB-30** — a custom dataset of 5,191 images across 30 Indian food classes curated from two Kaggle sources
- Model retrained from scratch on the new dataset
- Validation accuracy: **86.4%** (vs 86.0% on v1, but on genuinely Indian food)
- App renamed from ProteinLens → **NutriLens** to reflect full macro tracking

### Added
- 10 new food classes: Dal Makhani, Butter Chicken, Chana Masala, Dosa, Idli, Pani Puri, Pav Bhaji, Dhokla, Vada, Rajma
- Scan history screen with daily protein + calorie totals
- Serving size slider (50g–500g) with live nutrition scaling
- Freeze frame — tap screen to lock detection and adjust serving size
- App icon

### Removed
- Western food classes (hamburger, steak, sushi, crab cakes etc.)
- Dependency on Food-101 TFDS dataset

---

## v1.0 — Food-101 (March 2026)

### Added
- Initial release — MobileNetV2 fine-tuned on Food-101 (20 India-optimised classes)
- Real-time food detection via AVFoundation + Vision + CoreML
- Live nutrition card overlay (protein, calories, fat, carbs)
- On-device inference — no internet required
- Validation accuracy: **86.0%**
- Model size: 5.9MB (.mlpackage)
