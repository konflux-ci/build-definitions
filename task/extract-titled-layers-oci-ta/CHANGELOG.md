# Changelog

## 0.1

### Added

- New task: restore git `SOURCE_ARTIFACT`, fetch matching titled container-image
  layers (ModelCar/olot) into that tree, and emit a new `SOURCE_ARTIFACT` for
  SAST to scan. Untitled layers and filter misses (e.g. weights) are skipped.
  Image indexes resolve to linux/amd64.
