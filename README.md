# PogonaHealth

**IoT and Deep Learning-based monitoring system for temperature tracking and early fungal skin infection detection in *Pogona vitticeps* (bearded dragon).**

![Python](https://img.shields.io/badge/Python-3.9-blue)
![YOLOv8](https://img.shields.io/badge/YOLOv8n-Ultralytics-purple)
![ESP32](https://img.shields.io/badge/ESP32-Arduino-teal)
![Laravel](https://img.shields.io/badge/Laravel-Framework-red)
![Raspberry Pi](https://img.shields.io/badge/Raspberry_Pi-4B-c51a4a)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

Final Year Project (Tugas Akhir) — Applied Bachelor of Telecommunication Engineering, Politeknik Negeri Semarang, 2026.

---

## Overview

*Pogona vitticeps* is highly susceptible to *yellow fungus disease*, a progressive skin infection that is difficult for owners to detect early through visual inspection alone. PogonaHealth combines an IoT temperature monitoring pipeline with a real-time computer vision detection system to help owners catch early signs of infection and maintain optimal enclosure conditions — accessible remotely via a web dashboard and Telegram bot.

## Key results

| Metric | Result |
|---|---|
| Temperature sensor accuracy (DS18B20) | 98.22% |
| Automated relay control (NTP-based) | 100% success |
| YOLOv8n detection accuracy | 97.17% |
| YOLOv8n mAP50 | 98.62% |
| Average temperature transmission delay | 271.32 ms ("Good", TIPHON standard) |
| Network packet loss (Wireshark test) | 0% |
| Optimal camera position (confidence) | 83.0%, 100% accuracy |

## System architecture

```
DS18B20 --(One-Wire)--> ESP32 --(MQTT)--> Raspberry Pi --(HTTP API)--> Hostinger (Laravel + MySQL)
                            |                    |
                       Relay / LCD          YOLOv8n detection
                                                  |
                                          Flask streaming (MJPEG)
                                                  |
                                          Cloudflare Tunnel
                                                  |
                                    Website Dashboard  +  Telegram Bot
```

- **ESP32** reads ambient temperature via a DS18B20 sensor, displays it locally on an LCD, and controls UVB/daylight lamps via relay based on NTP-synced scheduling.
- **Raspberry Pi 4** runs a YOLOv8n model for real-time fungal lesion detection from a live camera feed, and bridges sensor data from MQTT to a cloud REST API.
- **Laravel + MySQL (Hostinger)** stores temperature history and serves the web dashboard.
- **Telegram Bot** sends automatic alerts on detection and responds to interactive commands (`/status`, `/suhu`, `/jamur`).
- **Cloudflare Tunnel** exposes the local video stream publicly without requiring a static IP.

## Tech stack

**Hardware:** ESP32, DS18B20, Raspberry Pi 4 Model B, Logitech C920 webcam, 2-channel relay module, I2C LCD

**Firmware / Embedded:** Arduino IDE (C++), OneWire, DallasTemperature, PubSubClient

**Computer vision:** Python, OpenCV, Ultralytics YOLOv8n, Roboflow (dataset annotation & augmentation)

**Backend:** Laravel (PHP), MySQL, REST API

**IoT communication:** MQTT (Mosquitto broker), HTTP

**Deployment:** Raspberry Pi OS, Cloudflare Tunnel, Hostinger

**Notifications:** Telegram Bot API

## Repository structure

```
pogonahealth/
├── esp32-firmware/        ESP32 firmware (temperature reading, relay control, MQTT publish)
├── raspberry-pi/          YOLOv8n detection server, MQTT-to-API bridge, Telegram bot
├── website-laravel/       Web dashboard, REST API, database migrations
├── model-training/        Dataset preprocessing and YOLOv8n training notebook
└── docs/                  Architecture diagrams and documentation assets
```

## How it works

1. **Temperature pipeline** — DS18B20 publishes readings to a local MQTT broker on the Raspberry Pi every 5 seconds. A bridge script forwards each reading to a Laravel REST API endpoint, which persists it to a MySQL database on Hostinger.
2. **Detection pipeline** — A webcam feed is continuously processed by a YOLOv8n model running on the Raspberry Pi. Detected bounding boxes and confidence scores are rendered onto the video frame and served as an MJPEG stream via Flask.
3. **Remote access** — Cloudflare Tunnel exposes the local video stream through a public URL, embedded directly into the Laravel dashboard.
4. **Alerts** — When a fungal lesion is detected above a confidence threshold, the system triggers an automatic Telegram notification (with a 30-minute cooldown to prevent spam) including detection confidence, current temperature, and a suggested action.

## Setup

### 1. ESP32 firmware
Open `esp32-firmware/pogonahealth_esp32.ino` in Arduino IDE, update WiFi and MQTT credentials, then flash to the ESP32.

### 2. Raspberry Pi
```bash
cd raspberry-pi
pip install -r requirements.txt
python3 detect_web_server.py     # YOLOv8n detection + video stream
python3 bridge_iot.py            # MQTT-to-API bridge
python3 telegram_bot.py          # Telegram bot service
```

### 3. Laravel dashboard
```bash
cd website-laravel
composer install
cp .env.example .env             # then fill in your own database credentials
php artisan key:generate
php artisan migrate
php artisan serve
```

## Model training

The YOLOv8n model was trained on a custom dataset of 706 images (later augmented to 1,554), annotated on the back and leg regions of *Pogona vitticeps* across two classes: `healthy` and `fungal`. Training was run for 100 epochs with batch size 8 on a GPU-enabled Google Colab instance. Full training notebook available in `model-training/`.

## Testing methodology

The system was evaluated across five dimensions: sensor accuracy (against a calibrated digital thermometer), relay control timing, model detection accuracy (confusion matrix, precision/recall/mAP), network QoS (application-level delay/data loss plus infrastructure-level packet loss/RTT/jitter via Wireshark and Ookla Speedtest), and optimal camera placement (9-zone grid test across 3 lighting conditions).

## Authors

**Cahaya Jaya Prabasa** & **Nurul Hidayah**
Applied Bachelor of Telecommunication Engineering, Politeknik Negeri Semarang

Supervised by Dr. Ir. Eko Supriyanto, S.T., M.T., IPM and Roni Apriantoro, S.Tr.T., M.Tr.T.

## License

This project is released under the MIT License for educational and portfolio purposes.
