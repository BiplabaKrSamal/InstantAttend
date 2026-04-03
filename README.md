<div align="center">

<br/>

<h1>InstantAttend</h1>

<p><strong>Computer Vision Project &nbsp;·&nbsp; Python + Flask + OpenCV</strong></p>

<p>Zero manual roll calls. Real-time face recognition marks attendance automatically via webcam,<br/>
logs it to a daily CSV, and surfaces it on a live web dashboard — all in a single Python file.</p>

<br/>

[![Python](https://img.shields.io/badge/Python-3.8+-3776AB?style=flat-square&logo=python&logoColor=white)](https://python.org)
[![Flask](https://img.shields.io/badge/Flask-2.x-000000?style=flat-square&logo=flask&logoColor=white)](https://flask.palletsprojects.com)
[![OpenCV](https://img.shields.io/badge/OpenCV-4.x-5C3EE8?style=flat-square&logo=opencv&logoColor=white)](https://opencv.org)
[![scikit-learn](https://img.shields.io/badge/scikit--learn-KNN-F7931E?style=flat-square&logo=scikit-learn&logoColor=white)](https://scikit-learn.org)
[![License](https://img.shields.io/badge/License-MIT-1d9e75?style=flat-square)](LICENSE)

<br/>

![InstantAttend Dashboard](screenshot.png)

</div>

---

## At a glance

| | |
|---|---|
| **50** face samples captured per registered user |
| **50×50 px** crop flattened into 7,500-dim vector for KNN |
| **k = 5** neighbours for face identification |
| **1 file** — all Flask routes + CV logic live in `app.py` (147 lines) |

---

## Recognition pipeline

```
Webcam frame
    │
    ▼
① Detect — Haar Cascade finds face bounding rect
    │
    ▼
② Preprocess — crop → grayscale → resize to 50×50
    │
    ▼
③ Classify — KNN predicts "Name_Roll" from flattened vector
    │
    ▼
④ Deduplicate — roll number already in today's CSV? → skip
    │
    ▼
⑤ Log — append Name, Roll, Time to Attendance-MM_DD_YY.csv
    │
    ▼
Flask dashboard refreshes
```

---

## Features

- **Live face detection** — Haar Cascade (`haarcascade_frontalface_default.xml`) processes every webcam frame in real time
- **KNN face recognition** — 50×50 face images flattened to 7,500-dim vectors, classified by `KNeighborsClassifier(n_neighbors=5)`
- **Auto-retraining** — adding a new user immediately retrains the KNN model on all registered faces and saves the `.pkl`
- **No duplicate logging** — roll number check prevents a person being marked more than once per session
- **Daily CSVs** — one `Attendance-MM_DD_YY.csv` per day with `Name, Roll, Time` columns, ready for spreadsheet export
- **No cloud dependency** — fully local, runs on any machine with Python and a webcam

---

## Flask routes

| Route | Method | Action |
|---|---|---|
| `/` | GET | Dashboard — render today's attendance table |
| `/start` | GET | Open webcam, run recognition loop, log attendance |
| `/add` | POST | Register new user — capture 50 samples, retrain model |

---

## How it works

### Taking attendance

```python
# /start route — core recognition loop
while ret:
    ret, frame = cap.read()
    if extract_faces(frame) != ():
        (x, y, w, h) = extract_faces(frame)[0]
        face = cv2.resize(frame[y:y+h, x:x+w], (50, 50))
        identified_person = identify_face(face.reshape(1, -1))[0]
        add_attendance(identified_person)   # deduplication handled here
```

### Registering a new user

```python
# /add route — capture 50 samples, retrain in-place
if j % 10 == 0:                            # every 10th frame
    cv2.imwrite(userimagefolder + name, frame[y:y+h, x:x+w])
    i += 1
if j == 500: break                         # 500 frames → 50 images

train_model()                              # retrain KNN immediately
```

### Model training

```python
for user in os.listdir('static/faces'):
    for img_path in os.listdir(f'static/faces/{user}'):
        img = cv2.imread(img_path)
        faces.append(cv2.resize(img, (50, 50)).ravel())   # flatten to 7,500-dim
        labels.append(user)

knn = KNeighborsClassifier(n_neighbors=5)
knn.fit(faces, labels)
joblib.dump(knn, 'static/face_recognition_model.pkl')
```

---

## Project structure

```
InstantAttend/
├── app.py                              # All Flask routes + CV logic (147 lines)
├── requirements.txt
├── screenshot.png
│
├── templates/
│   └── home.html                       # Jinja2 dashboard template
│
├── static/
│   ├── faces/                          # Auto-created on first registration
│   │   └── Name_ID/                    # 50 JPG samples per user
│   └── face_recognition_model.pkl      # Auto-generated after first registration
│
├── Attendance/                         # Auto-created on first run
│   └── Attendance-MM_DD_YY.csv         # Name, Roll, Time — one file per day
│
└── docs/
    ├── data_architecture.png
    └── use_case_diagram.png
```

---

## Getting started

### Requirements

- Python 3.8+
- A working webcam (built-in or USB)

### Install & run

```bash
git clone https://github.com/BiplabaKrSamal/InstantAttend.git
cd InstantAttend
pip install -r requirements.txt
python app.py
```

Open **http://127.0.0.1:5000** in your browser.

### Usage

**Register a new person**
1. Enter name and roll number in the web form
2. Click **Add New User** — webcam opens and captures 50 face images automatically
3. Model retrains immediately; person is ready to be recognised

**Take attendance**
1. Click **Take Attendance** — webcam opens
2. Walk in front of the camera; name overlays the frame when recognised
3. Press `ESC` to close — dashboard updates with the logged entry

**View records**
- Live table on the dashboard at `http://127.0.0.1:5000`
- Raw CSV at `Attendance/Attendance-MM_DD_YY.csv` for spreadsheet export

---

## Tech stack

| Layer | Technology |
|---|---|
| Web framework | Flask 2.x |
| Face detection | OpenCV — Haar Cascade (`haarcascade_frontalface_default.xml`) |
| Face recognition | scikit-learn — `KNeighborsClassifier(n_neighbors=5)` |
| Model persistence | joblib → `.pkl` |
| Data storage | CSV via pandas — no database required |
| Frontend | HTML5, Bootstrap 5, Jinja2 |

---

## Architecture diagrams

| Data architecture | Use case diagram |
|---|---|
| ![](docs/data_architecture.png) | ![](docs/use_case_diagram.png) |

---

## Limitations & roadmap

| Limitation | Status |
|---|---|
| Single face per frame — first detected face only | Multi-person support planned |
| Flat 50×50 vectors discard spatial structure | FaceNet / DeepFace upgrade on roadmap |
| No anti-spoofing — printed photo fools the model | Liveness detection planned |
| Haar Cascade degrades in low light | SSD / MTCNN detector upgrade planned |
| Local-only storage | Firebase / PostgreSQL integration planned |
| No automated reports | Daily CSV email to admin coming soon |

---

## Contributing

Pull requests are welcome. For significant changes please open an issue first.

```bash
git checkout -b feature/your-feature
git commit -m "feat: describe your change"
git push origin feature/your-feature
# → open a Pull Request
```

---

## License

[MIT](LICENSE) &nbsp;·&nbsp; Made by [BiplabaKrSamal](https://github.com/BiplabaKrSamal)
