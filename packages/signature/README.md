# signature (local fork)

Fork of [`signature` 5.5.0](https://pub.dev/packages/signature) with mutable
`penColor`, `penStrokeWidth`, and `strokeCap` on `SignatureController`.

Upstream marks those fields `final`, which forces apps to dispose/recreate the
controller when changing style — wiping the internal undo stack. This fork
keeps one controller alive across style changes so `.undo()` works correctly.
