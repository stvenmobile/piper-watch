# Jetson side

Runs on the Jetson Orin NX. Planned modules:

- `piper_watch/link.py`: the Jetson ↔ head protocol (COBS + CRC-16 over USB serial)
- `piper_watch/vision/`: capture, face detection (SCRFD / YOLOv8-face) and recognition (ArcFace)
- `piper_watch/track.py`: turns face positions into pan/tilt `LOOK` targets
- dashboard: camera view with overlays, served on the Jetson

Face images and embeddings live in `jetson/data/`, which is git-ignored and never leaves the Jetson.
