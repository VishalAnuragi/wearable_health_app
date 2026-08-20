# Wearable Health & Shopping Application

## Overview

This repository contains a full-stack mobile solution featuring a Flutter application (Android & iOS) and a Node.js/PostgreSQL backend. The application simulates a wearable health device providing live biometric data and includes an authenticated e-commerce flow for purchasing products.

The system is engineered with an **offline-first architecture**, ensuring data integrity during network drops, and utilizes Clean Architecture principles for high testability and separation of concerns.

---

## 1. Architecture Overview

The application follows a strictly decoupled **Clean Architecture** utilizing the **BLoC (Business Logic Component)** pattern for state management. This ensures maximum testability and a clear separation of concerns.

* **Presentation Layer:** Flutter UI and BLoCs.
* **Domain Layer:** Business logic, entities, and abstract repository interfaces.
* **Data Layer:** API clients, local SQLite database, and the Mock Wearable Implementation.



---

## 2. Wearable Integration Approach

Currently, the application utilizes a **Mock Wearable Implementation** separated from the Flutter application via a clean **Wearable Service Interface**.

**Replacing the Mock with a Real Vendor SDK:**
To integrate a real hardware SDK (e.g., a Smart Ring or smartwatch), I would implement a **Native Plugin** architecture using **Flutter Platform Channels**.

* **Why Native Plugins?** Vendor SDKs are provided in Kotlin/Java for Android and Swift/Obj-C for iOS. By writing a custom Flutter Plugin via `MethodChannel` and `EventChannel`, the heavy lifting (Bluetooth pairing, low-level data streaming, background execution) remains in native code optimized for the respective OS.


* **Integration:** The native plugin would stream serialized data over an `EventChannel`. Our existing Flutter Domain Interface would subscribe to this channel, meaning **zero UI or BLoC code needs to change** when swapping the mock for the real hardware.

---

## 3. Connection & Retry Strategy

The wearable service handles various connection states: device connected, device disconnected, connection failure, and manual reconnection.

* **Automatic Reconnect:** If the Bluetooth connection drops unexpectedly, the service triggers an automatic reconnect attempt using an **Exponential Backoff** strategy (retrying at 2s, 4s, 8s, up to a maximum cap) to preserve device battery.
* **Manual Override:** If the auto-reconnect fails after the maximum attempts, the state transitions to `disconnected`. The UI presents a manual "Reconnect" button, allowing the user to initiate the connection.

---

## 4. Handling Large Volumes of Health Data

The application stores health readings (heart rate, SpO₂, steps) locally. A real wearable can generate thousands of readings a day (e.g., every 3 seconds). Loading unlimited raw records into the UI at once would cause severe UI lag and Out of Memory (OOM) crashes.

**The Solution: Database-Level Downsampling**
The application relies on SQLite to perform data aggregation at the disk level. Instead of pulling all raw records into Dart memory, queries utilize SQL `GROUP BY`, `AVG()`, and `MAX()` functions.

* For the **Daily History**, data is grouped into a maximum of 24 hourly rows.


* For the **Weekly Summary**, it is aggregated into 7 daily rows.
This guarantees a constant $O(1)$ memory footprint for the UI charting libraries, regardless of how much data the device generates.



---

## 5. Offline Synchronization Approach

The application uses an offline-first strategy where all health data is written to a local SQLite database immediately.

* **Sync Queue:** Each record has an `is_synced` boolean flag. Un-synced data forms the pending sync queue.


* **Target Scenario Execution:** If the device generates 100 readings while the phone is in Airplane Mode, they are saved locally with `is_synced = 0`. When network connectivity returns, a background `SyncManager` detects the connection, queries the 100 pending items, and pushes them in a batch to the Node.js API.


* **Retry After Failure:** If the API fails mid-sync, the transaction is caught, and the `is_synced` flag remains `0`. The data will be retried on the next sync cycle.


* **Duplicate Prevention:** The backend PostgreSQL database utilizes a `UNIQUE(device_id, timestamp)` constraint. If the app accidentally transmits the same batch twice, the database silently rejects the duplicates.



---

## 6. Database Design (PostgreSQL)

The relational database handles users, devices, health data, and e-commerce orders.

| Table | Primary Key | Relationships & Constraints |
| --- | --- | --- |
| **users** | `id` (UUID) | Stores authentication details. |
| **devices** | `id` (UUID) | Belongs to `users` (`user_id`). Tracks `device_id` (e.g., FITRING-001).

 |
| **health_readings** | `id` (UUID) | Belongs to `devices` (`device_id`). Enforces `UNIQUE(device_id, timestamp)`.

 |
| **products** | `id` (UUID) | Stores product details, price, and stock.

 |
| **cart_items** | `id` (UUID) | Links `users` and `products`. Enforces `UNIQUE(user_id, product_id)`. |
| **orders** | `id` (UUID) | Belongs to `users`. Tracks total amount and status. |
| **order_items** | `id` (UUID) | Links `orders` and `products`. Captures `price_at_purchase` to protect historical receipts.

 |

---

## 7. API Documentation

The Node.js (Express) backend exposes the following RESTful endpoints:

### Auth & Devices

* `POST /auth/login`: Authenticates user and returns JWT.


* `POST /devices`: Registers a new wearable device.


* `GET /devices`: Retrieves user's registered devices.



### Health Data

* `POST /health/readings`: Accepts batched offline health readings.


* `GET /health/readings`: Retrieves raw health history.


* `GET /health/summary`: Retrieves aggregated daily/weekly metrics.



### E-Commerce

* `GET /products`: Lists available shop inventory.


* `GET /products/:id`: Fetches product details.


* `POST /cart`: Adds item to user's cart.


* `GET /cart`: Retrieves current cart state.


* `POST /orders`: Converts cart to an order.


* `GET /orders`: Retrieves user's order history.



---

## 8. Setup Instructions

### Backend (Node.js)

1. Navigate to the `/backend` directory.
2. Run `npm install` to install dependencies.
3. Configure your PostgreSQL connection string in a `.env` file.
4. Run `npm run start` to boot the Express server on port 3000.

### Mobile App (Flutter)

1. Ensure you have the Flutter SDK installed and an emulator running (or a physical device connected).
2. Run `flutter pub get` to install dependencies.
3. *If testing on a physical Android device pointing to local Node.js:* Run `adb reverse tcp:3000 tcp:3000`.
4. Run `flutter run`.
5. Run automated tests using `flutter test`.



---

## 9. Major Technical Decisions & Trade-offs

* **Dio + Custom Interceptors over http:** Used `dio` for network requests to easily implement a centralized `ErrorHandler`. This cleanly maps API failures, 401 Unauthorized errors, and SocketExceptions into user-friendly UI exceptions.


* **In-Memory vs. Background Sync:** Currently, the `SyncManager` relies on the app being in the foreground/memory to push data. *Trade-off:* For a true production app, this would be migrated to the Android `WorkManager` and iOS `BGTaskScheduler` to guarantee uploads even if the app is killed.
* **Price Snapshotting:** The `order_items` table intentionally duplicates the product price as `price_at_purchase`. *Trade-off:* This denormalization uses slightly more storage but guarantees that historical order totals do not change if a product's price is updated in the future.

---



## 10. Exception Handling

**📱 Handled by the Flutter App (Client-Side)**
* **No internet: Yes. We tested this earlier.** By queuing data in local SQLite and using a background sync process, the app safely holds onto health readings and cart items until Wi-Fi or cellular data returns.

* **Backend unavailable:** Yes. In your earlier code snippet, your Flutter ApiClient had connectTimeout and receiveTimeout set to 30 seconds. If the backend is down, the app will time out gracefully rather than freezing forever.

* **Bluetooth / device disconnect:** Yes. This is entirely hardware-dependent. If the physical wearable disconnects, the Flutter BLE (Bluetooth Low Energy) library should catch the disconnect event, pause the data collection, and resume queuing data once it reconnects.

---

---

## ⚠️ Reviewer Notice: APK & Network Connectivity

Please note that the backend for this application is currently configured to run in a **local development environment** (Node.js running on a local machine, connecting to a remote Supabase database). 

*   The generated `app-release.apk` provided with this submission has the API base URL hardcoded to the local Wi-Fi IP address used during development.
*   Because of this, **if you install the APK on a device outside of this specific local network, the app will not be able to reach the Node.js server**, resulting in API timeouts for logins, checkout, and health syncing.
*   To evaluate the full-stack functionality (Flutter UI ↔ Node.js Backend ↔ Supabase Database), **please refer to the included screen recording session**. The video comprehensively demonstrates the offline queuing, successful data synchronization, database constraints, and the e-commerce checkout flow working seamlessly together.
