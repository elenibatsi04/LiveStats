# LiveStats 🏀

A native iOS application built with **SwiftUI** for tracking live sports schedules and box scores. This project demonstrates modern iOS development practices, including MVVM architecture and modular state management.

![App Screenshot]

<img width="585" height="1266" alt="IMG_5053" src="https://github.com/user-attachments/assets/230a4069-b26f-40c9-a574-545198ce283a" />
<img width="585" height="1266" alt="IMG_5052" src="https://github.com/user-attachments/assets/b7b7d774-feb8-4d8f-844e-0e331f94d6ad" />
<img width="585" height="1266" alt="IMG_5051" src="https://github.com/user-attachments/assets/fdcc8c06-88ec-4dc8-909f-692431c277fc" />


## 🚀 Features

* **Live Schedule:** View daily game schedules with a clean, date-aware interface.
* **Box Scores:** Detailed game statistics (`BoxScoreView`).
* **Favorites System:** users can track their favorite teams (`FavoritesManager`).
* **Notifications:** Local alert integration for game start times (`NotificationManager`).
* **Modern UI:** Built entirely with SwiftUI, supporting Dark Mode and dynamic type.

## 🛠 Tech Stack

* **Language:** Swift
* **UI Framework:** SwiftUI
* **Architecture:** MVVM (Model-View-ViewModel)
* **Platform:** iOS 15+

## 📂 Project Structure

 The app is organized into clean modules to ensure scalability:

* **`/Views`**: Contains the UI layer (e.g., `ScheduleView`, `BoxScoreView`).
* **`/Models`**: Data definitions and structs.
* **`/Managers`**: Singleton services for handling logic like Favorites and Notifications.
* **`/ViewModels`**: Handles business logic for views (e.g., `ScheduleViewModel`).

## 📱 Code Highlight

Using Swift's modern `Date` formatting API for localization-friendly displays:

```swift
// Automatically formats the date based on the user's locale
Text(Date().formatted(date: .long, time: .omitted))
    .font(.subheadline)
    .foregroundColor(.secondary)
