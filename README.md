# SmartVault 🚀

**SmartVault** is a modern, AI-powered cryptocurrency portfolio tracker and financial advisor application built with Flutter.

> **Note:** This project is currently under active development and serves as a demonstration of advanced Flutter capabilities, Clean Architecture, and AI integration.

## ✨ Key Features
*   **Real-time Portfolio Tracking**: Live price updates via Binance WebSocket connection.
*   **AI Financial Advisor**: Personalized financial insights powered by Google Gemini AI.
*   **Secure Authentication**: Biometric login (FaceID/TouchID) using `local_auth`.
*   **Premium UI/UX**: Glassmorphism design system, custom charts, and smooth animations.
*   **Clean Architecture**: Separation of concerns with Domain, Data, and Presentation layers.

## 🛠 Tech Stack
*   **Framework**: Flutter & Dart
*   **State Management**: `flutter_bloc`
*   **Dependency Injection**: `get_it`
*   **Local Storage**: `hive`
*   **Networking**: `dio`, `web_socket_channel`
*   **AI Integration**: `google_generative_ai`

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK
*   Dart SDK

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/yourusername/smart_vault.git
    cd smart_vault
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Configure API Keys**
    *   Open `lib/injection_container.dart`.
    *   Find the `AIService` registration.
    *   Replace `'YOUR_API_KEY_HERE'` with your valid Google Gemini API Key.

4.  **Run the App**
    ```bash
    flutter run
    ```

## 📸 Functionality
*   **Dashboard**: Overview of assets, total balance, and P&L.
*   **Asset Details**: Interactive charts and detailed market statistics.
*   **AI Chat**: Ask questions about your portfolio and get intelligent advice.
*   **Settings**: Customize theme (Dark/Light) and currency.

---
Developed by [Your Name]
