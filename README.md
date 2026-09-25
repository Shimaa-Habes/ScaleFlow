# 🚀 ScaleFlow

<p align="center">
  <img src="https://img.shields.io/badge/ScaleFlow-Enterprise%20Project%20Intelligence-6C5CE7?style=for-the-badge&logo=target&logoColor=white" />
  <img src="https://img.shields.io/badge/Flutter-Mobile-5B9BD5?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/.NET%208-Backend-512BD4?style=for-the-badge&logo=dotnet&logoColor=white" />
  <img src="https://img.shields.io/badge/Python-AI%2FML-3776AB?style=for-the-badge&logo=python&logoColor=white" />
  <img src="https://img.shields.io/badge/SQL%20Server-Database-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white" />
</p>

<p align="center">
  <strong>Enterprise Project Intelligence Platform</strong>
</p>

<p align="center">
  A smart project management platform that combines project management with AI-powered insights.
</p>

---

## 📌 About ScaleFlow

**ScaleFlow** is an Enterprise Project Intelligence Platform designed to help teams plan, monitor, and manage projects more efficiently.

The platform combines traditional project management features with AI-powered analysis to help teams understand:

- 📊 Project progress
- ⚠️ Project risks
- ⏱️ Potential delays
- 🚧 Task bottlenecks
- ❤️ Overall project health
- 👥 Team activity and workload

Instead of only showing what is happening inside a project, ScaleFlow uses Machine Learning to analyze project data and provide actionable insights.

---

# ✨ Key Features

## 📁 Project Management

- Create and manage projects
- Update project information
- Track project progress
- Manage project status
- Archive projects
- Upload project images
- Add project architecture and technologies

## ✅ Task Management

- Create tasks
- Update tasks
- Delete tasks
- Assign tasks
- Set priorities
- Set planned dates
- Track completion percentage
- Track estimated and actual hours
- Manage task dependencies

## 📋 Project Organization

- Project dashboard
- Task management
- Project progress tracking
- Team members
- Task dependencies
- Project files
- Project architecture
- Workload monitoring

## 🤖 AI-Powered Intelligence

ScaleFlow includes four Machine Learning services:

| AI Service          | Purpose                                   |
| ------------------- | ----------------------------------------- |
| 🛡️ Risk Model       | Analyzes overall project risk             |
| ⏱️ Delay Model      | Predicts potential project delay          |
| 🚧 Bottleneck Model | Detects tasks that may become bottlenecks |
| ❤️ Health Model     | Evaluates overall project health          |

## 🔐 Authentication & Authorization

- User registration
- User login
- JWT Authentication
- ASP.NET Core Identity
- Role-Based Access Control (RBAC)
- Protected API endpoints

Supported roles:

- Project Manager
- Team Leader
- Team Member
- Client

---

# 🏗️ System Architecture

```text
                    ┌─────────────────────┐
                    │    Flutter Mobile   │
                    │         App        │
                    └──────────┬──────────┘
                               │
                               │ REST API
                               ▼
                    ┌─────────────────────┐
                    │   ASP.NET Core      │
                    │       .NET 8        │
                    │      Backend        │
                    └──────────┬──────────┘
                               │
                ┌──────────────┴──────────────┐
                │                             │
                ▼                             ▼
       ┌─────────────────┐          ┌─────────────────────┐
       │    SQL Server   │          │   Python FastAPI    │
       │     Database    │          │     AI Services     │
       └─────────────────┘          └──────────┬──────────┘
                                               │
                ┌──────────────────────────────┼────────────────────────┐
                │                              │                        │
                ▼                              ▼                        ▼
        ┌──────────────┐              ┌──────────────┐          ┌──────────────┐
        │ Risk Model   │              │ Delay Model  │          │ Bottleneck   │
        │    :8002     │              │    :8004     │          │    :8003     │
        └──────────────┘              └──────────────┘          └──────────────┘
                                               │
                                               ▼
                                       ┌──────────────┐
                                       │ Health Model │
                                       │    :8005     │
                                       └──────────────┘
```

---

# 🛠️ Technology Stack

## Frontend

- Flutter
- Dart
- Material UI
- HTTP
- Image Picker
- Archive

## Backend

- ASP.NET Core
- .NET 8
- C#
- Entity Framework Core
- ASP.NET Core Identity
- JWT Authentication
- Swagger / OpenAPI

## Database

- Microsoft SQL Server
- Entity Framework Core

## AI / Machine Learning

- Python
- FastAPI
- Uvicorn
- Pandas
- NumPy
- Scikit-learn
- Joblib
- Logistic Regression

## External Services

- Google Gemini API

## Development & Project Management

- Git
- GitHub
- ClickUp
- Visual Studio Code
- Swagger
- Postman

---

# 📦 Prerequisites

Before running ScaleFlow, make sure the following are installed:

- Git
- Flutter SDK
- Dart SDK
- .NET 8 SDK
- Python 3.13
- SQL Server
- SQL Server Management Studio
- Visual Studio Code
- Google Chrome

Verify the installations:

```bash
git --version
flutter --version
dart --version
dotnet --version
python --version
```

---

# 📂 Project Structure

```text
ScaleFlow-Integration/
│
├── Backend/
│   └── ScaleFlow/
│       ├── Controllers/
│       ├── DTOs/
│       ├── Models/
│       ├── Services/
│       ├── Data/
│       ├── Migrations/
│       ├── Program.cs
│       └── appsettings.json
│
├── AI-ML/
│   │
│   ├── Risk-Model/
│   │   ├── data/
│   │   ├── models/
│   │   ├── src/
│   │   ├── api.py
│   │   └── requirements.txt
│   │
│   ├── Bottleneck-Model/
│   │   ├── models/
│   │   ├── api.py
│   │   └── requirements.txt
│   │
│   ├── Delay-Model/
│   │   ├── models/
│   │   ├── api.py
│   │   └── requirements.txt
│   │
│   └── Health-Model/
│       ├── models/
│       ├── api.py
│       └── requirements.txt
│
└── Flutter/
    ├── lib/
    ├── assets/
    ├── pubspec.yaml
    └── ...
```

---

# ⚙️ Installation & Setup

## 1️⃣ Clone the Repository

```bash
git clone https://github.com/Shimaa-Habes/ScaleFlow.git
cd ScaleFlow
```

---

# 🗄️ 2️⃣ Database Setup

Make sure SQL Server is installed and running.

Create a database for ScaleFlow and configure the connection string in:

```text
Backend/ScaleFlow/appsettings.json
```

Example:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=ScaleFlowDb;Trusted_Connection=True;TrustServerCertificate=True;"
  }
}
```

> Use your own SQL Server instance name if it is different.

If the project contains Entity Framework migrations, apply them using:

```bash
dotnet ef database update
```

---

# 🔐 3️⃣ JWT Configuration

ScaleFlow uses JWT Authentication.

Configure your local JWT settings:

```json
{
  "JwtSettings": {
    "Issuer": "ScaleFlow",
    "Audience": "ScaleFlow-Api",
    "SecretKey": "YOUR_SECRET_KEY",
    "ExpiryMinutes": 60
  }
}
```

⚠️ Never commit real JWT secrets or API keys to GitHub.

---

# 🤖 4️⃣ AI/ML Dependencies

Each Machine Learning service runs independently using Python and FastAPI.

The required Python libraries include:

```text
fastapi
uvicorn
pandas
numpy
scikit-learn
joblib
```

Install the dependencies from each service's `requirements.txt`.

---

# 🛡️ 5️⃣ Run Risk Model

Open a terminal:

```powershell
cd "AI-ML\Risk-Model"
```

Create the virtual environment:

```powershell
python -m venv .venv
```

Activate it:

```powershell
.\.venv\Scripts\Activate.ps1
```

Install dependencies:

```powershell
pip install -r requirements.txt
```

Run the service:

```powershell
python -m uvicorn api:app --reload --port 8002
```

Risk Model:

```text
http://127.0.0.1:8002
```

Swagger:

```text
http://127.0.0.1:8002/docs
```

---

# 🚧 6️⃣ Run Bottleneck Model

Open another terminal:

```powershell
cd "AI-ML\Bottleneck-Model"
```

Create the virtual environment:

```powershell
python -m venv .venv
```

Activate:

```powershell
.\.venv\Scripts\Activate.ps1
```

Install dependencies:

```powershell
pip install -r requirements.txt
```

Run:

```powershell
python -m uvicorn api:app --reload --port 8003
```

Bottleneck Model:

```text
http://127.0.0.1:8003
```

Swagger:

```text
http://127.0.0.1:8003/docs
```

---

# ⏱️ 7️⃣ Run Delay Model

Open another terminal:

```powershell
cd "AI-ML\Delay-Model"
```

Create the virtual environment:

```powershell
python -m venv .venv
```

Activate:

```powershell
.\.venv\Scripts\Activate.ps1
```

Install dependencies:

```powershell
pip install -r requirements.txt
```

Run:

```powershell
python -m uvicorn api:app --reload --port 8004
```

Delay Model:

```text
http://127.0.0.1:8004
```

Swagger:

```text
http://127.0.0.1:8004/docs
```

---

# ❤️ 8️⃣ Run Health Model

Open another terminal:

```powershell
cd "AI-ML\Health-Model"
```

Create the virtual environment:

```powershell
python -m venv .venv
```

Activate:

```powershell
.\.venv\Scripts\Activate.ps1
```

Install dependencies:

```powershell
pip install -r requirements.txt
```

Run:

```powershell
python -m uvicorn api:app --reload --port 8005
```

Health Model:

```text
http://127.0.0.1:8005
```

Swagger:

```text
http://127.0.0.1:8005/docs
```

---

# 🔗 Backend AI Configuration

The backend connects to the four AI services using HTTP.

Configuration:

```text
Backend/ScaleFlow/appsettings.Development.json
```

Example:

```json
{
  "MlService": {
    "BaseUrl": "http://127.0.0.1:8002",
    "BottleneckBaseUrl": "http://127.0.0.1:8003",
    "DelayBaseUrl": "http://127.0.0.1:8004",
    "HealthBaseUrl": "http://127.0.0.1:8005"
  }
}
```

---

# 🚀 9️⃣ Run ASP.NET Core Backend

Open another terminal:

```powershell
cd "Backend\ScaleFlow"
```

Run:

```powershell
dotnet run
```

Backend:

```text
http://localhost:5233
```

Swagger:

```text
http://localhost:5233/swagger
```

---

# 📱 🔟 Run Flutter Application

Open another terminal:

```powershell
cd "Flutter"
```

Install Flutter dependencies:

```powershell
flutter pub get
```

Check available devices:

```powershell
flutter devices
```

Run the application:

```powershell
flutter run
```

For Chrome:

```powershell
flutter run -d chrome
```

---

# 📚 Flutter Dependencies

The Flutter application uses packages including:

```yaml
dependencies:
  flutter:
    sdk: flutter

  http:
  image_picker:
  archive:
```

Install all dependencies using:

```powershell
flutter pub get
```

---

# 🔌 API Endpoints

## Authentication

```text
POST /api/Auth/register
POST /api/Auth/login
```

## Projects

```text
GET    /api/Projects
POST   /api/Projects
GET    /api/Projects/{id}
PUT    /api/Projects/{id}
DELETE /api/Projects/{id}
```

## AI Analysis

### 🛡️ Risk Analysis

```text
POST /api/projects/{projectId}/ai/risk-analysis
```

### ⏱️ Delay Prediction

```text
POST /api/projects/{projectId}/ai/delay-prediction
```

### 🚧 Bottleneck Detection

```text
POST /api/projects/{projectId}/ai/bottleneck-detection
```

### ❤️ Project Health

```text
POST /api/projects/{projectId}/ai/project-health
```

Example request:

```json
{
  "inputWindowDays": 30
}
```

---

# 🔄 AI Integration Flow

```text
┌───────────────┐
│ Flutter App   │
└───────┬───────┘
        │
        │ HTTP Request
        ▼
┌─────────────────────┐
│ ASP.NET Core .NET 8 │
│      Backend        │
└──────────┬──────────┘
           │
           │ Project Data
           │ Tasks
           │ Dependencies
           ▼
┌─────────────────────┐
│ Python FastAPI      │
│ AI/ML Services      │
└──────────┬──────────┘
           │
           ▼
┌────────────────────────────────────┐
│ Risk │ Delay │ Bottleneck │ Health │
└────────────────┬───────────────────┘
                 │
                 │ Prediction
                 ▼
┌─────────────────────┐
│ ASP.NET Core        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Flutter AI Insights │
└─────────────────────┘
```

---

# 🧠 AI Models

## 🛡️ Risk Model

The Risk Model analyzes project features and predicts:

- Risk Level
- Risk Score
- Confidence
- Class probabilities

Risk levels:

```text
Low
Medium
High
Critical
```

The model is based on Machine Learning using preprocessing, class balancing, and Logistic Regression.

The training dataset contains:

- 4,000 project records
- 49 input features
- 4 risk classes

---

## ⏱️ Delay Model

The Delay Model predicts the expected delay category.

Possible categories:

```text
Fast    → ≤ 30 days
Medium  → 31–365 days
Slow    → > 365 days
```

---

## 🚧 Bottleneck Model

The Bottleneck Model analyzes project tasks and identifies tasks that may become bottlenecks.

Output includes:

- Task ID
- Bottleneck Score
- Bottleneck Classification
- Explanation

---

## ❤️ Health Model

The Health Model evaluates the overall health of a project using project activity, workload, tasks, and logged hours.

It can use information such as:

- Planned hours
- Task count
- Task planned hours
- Logged hours
- Active users
- Active days
- Average logged hours
- Team activity

Output includes:

- Health Score
- Health Status
- Failure Probability

---

# 🩺 Service Health Checks

Before testing the complete application, verify that all services are running.

| Service          | URL                     | Port |
| ---------------- | ----------------------- | ---: |
| Backend          | `http://localhost:5233` | 5233 |
| Risk Model       | `http://127.0.0.1:8002` | 8002 |
| Bottleneck Model | `http://127.0.0.1:8003` | 8003 |
| Delay Model      | `http://127.0.0.1:8004` | 8004 |
| Health Model     | `http://127.0.0.1:8005` | 8005 |

---

# ▶️ Complete Startup Order

For the complete system, run the following services:

### Terminal 1 — Risk Model

```powershell
cd "AI-ML\Risk-Model"
.\.venv\Scripts\Activate.ps1
python -m uvicorn api:app --reload --port 8002
```

### Terminal 2 — Bottleneck Model

```powershell
cd "AI-ML\Bottleneck-Model"
.\.venv\Scripts\Activate.ps1
python -m uvicorn api:app --reload --port 8003
```

### Terminal 3 — Delay Model

```powershell
cd "AI-ML\Delay-Model"
.\.venv\Scripts\Activate.ps1
python -m uvicorn api:app --reload --port 8004
```

### Terminal 4 — Health Model

```powershell
cd "AI-ML\Health-Model"
.\.venv\Scripts\Activate.ps1
python -m uvicorn api:app --reload --port 8005
```

### Terminal 5 — Backend

```powershell
cd "Backend\ScaleFlow"
dotnet run
```

### Terminal 6 — Flutter

```powershell
cd "Flutter"
flutter pub get
flutter run -d chrome
```

---

# 🧪 Testing

## Backend Swagger

Open:

```text
http://localhost:5233/swagger
```

## Risk Swagger

```text
http://127.0.0.1:8002/docs
```

## Bottleneck Swagger

```text
http://127.0.0.1:8003/docs
```

## Delay Swagger

```text
http://127.0.0.1:8004/docs
```

## Health Swagger

```text
http://127.0.0.1:8005/docs
```

---

# 🔐 Security

ScaleFlow uses:

- JWT Authentication
- ASP.NET Core Identity
- Role-Based Access Control
- Protected API endpoints
- Authentication and authorization middleware
- Secure separation between Flutter, backend, database, and AI services

### ⚠️ Never commit sensitive information

Do not upload:

```text
API keys
JWT secrets
Passwords
Database credentials
.env files
Private tokens
```

Use environment variables or local configuration files for sensitive information.

---

# 🧩 Troubleshooting

## Flutter dependency problems

Run:

```powershell
flutter clean
flutter pub get
```

Then:

```powershell
flutter run -d chrome
```

---

## Backend does not start

Check:

```powershell
dotnet --version
```

Then verify:

- SQL Server is running
- Database connection string is correct
- JWT configuration is available
- Required .NET dependencies are installed

---

## AI service does not start

Activate the corresponding virtual environment:

```powershell
.\.venv\Scripts\Activate.ps1
```

Install dependencies:

```powershell
pip install -r requirements.txt
```

Then run the service again.

---

## AI connection error

Make sure all four AI services are running:

```text
8002 → Risk
8003 → Bottleneck
8004 → Delay
8005 → Health
```

Then verify:

```text
Backend/ScaleFlow/appsettings.Development.json
```

---

# 🔄 Project Workflow

```text
Create Project
      ↓
Add Project Architecture
      ↓
Add Team Members
      ↓
Create Tasks
      ↓
Assign Tasks
      ↓
Set Dates & Priorities
      ↓
Add Dependencies
      ↓
Track Progress
      ↓
Analyze Project Data
      ↓
AI Risk Analysis
      ↓
AI Delay Prediction
      ↓
AI Bottleneck Detection
      ↓
AI Project Health
      ↓
Actionable Insights
```

---

# 🎯 Project Goals

ScaleFlow aims to:

- Centralize project and task management
- Improve project visibility
- Track team workload
- Detect risks earlier
- Predict potential delays
- Identify task bottlenecks
- Evaluate project health
- Reduce manual monitoring
- Transform project data into actionable insights
- Support project teams with AI-powered intelligence

---

# 👥 Team

## ScaleFlow — Team 4

| Member                              | Responsibility                                                 |
| ----------------------------------- | -------------------------------------------------------------- |
| **Shimaa Mahmoud Habes**            | Team Leader, AI/ML, UI & Graphic Design                        |
| **Sadeel Ahmad Abd Elafaw Ardah**   | AI/ML                                                          |
| **Saba Fadi Abu Al-own**            | AI/ML                                                          |
| **Lana Hani Daraghmeh**             | Frontend                                                       |
| **Lama Waleed Khalid Sabaneh**      | Flutter                                                        |
| **Mohammad Imad Wasef Abdelfattah** | Backend .NET                                                   |
| **Mostafa Wisam Alnatshe**          | Backend .NET, Security Testing, Authentication & Authorization |

---

# 📋 Project Management

The team uses **ClickUp** to organize the development workflow.

ClickUp is used for:

- Task assignment
- Progress tracking
- Deadlines
- Team coordination
- Documentation
- Daily work tracking
- Project organization

GitHub is used for:

- Source code management
- Branching
- Pull requests
- Code review
- Integration

---

# 🌐 Repository

GitHub Repository:

**https://github.com/Shimaa-Habes/ScaleFlow**

---

# 📱 Demo Flow

The main demonstration flow is:

```text
Login
  ↓
Home
  ↓
Create Project
  ↓
Project Details
  ↓
Add Architecture
  ↓
Add Team Members
  ↓
Create Tasks
  ↓
Set Dependencies
  ↓
Track Progress
  ↓
AI Insights
  ↓
Risk Analysis
  ↓
Delay Prediction
  ↓
Bottleneck Detection
  ↓
Project Health
```

---

# 🤖 AI Intelligence

The four AI services answer different project-management questions:

```text
🛡️ Risk
How risky is the project?

⏱️ Delay
What delay category is predicted?

🚧 Bottleneck
Which tasks may block progress?

❤️ Health
How healthy is the project overall?
```

The models are integrated into the ScaleFlow backend and exposed to the Flutter application through API endpoints.

---

# 💡 Why ScaleFlow?

Traditional project management tools mainly show project information.

ScaleFlow adds an intelligence layer that analyzes project data and provides additional insights.

```text
Management
     ↓
Monitoring
     ↓
Data Analysis
     ↓
Prediction
     ↓
AI Insights
```

This helps project teams understand project status and potential problems through a unified platform.

---

# 📌 Quick Reference

```text
ScaleFlow
│
├── Flutter
│   └── Mobile Application
│
├── ASP.NET Core .NET 8
│   └── Backend API
│
├── SQL Server
│   └── Project Database
│
└── Python FastAPI
    ├── Risk Model       → 8002
    ├── Bottleneck Model → 8003
    ├── Delay Model      → 8004
    └── Health Model     → 8005
```

---

<p align="center">

## 🚀 ScaleFlow

### From Project Management to Project Intelligence

**Flutter • .NET 8 • SQL Server • Python • FastAPI • Machine Learning**

</p>
