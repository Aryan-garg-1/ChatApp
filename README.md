# 📡 ChatApp
### Talk to nearby strangers — no internet required.

ChatApp is an iOS application that lets you chat with people physically nearby using Apple's **MultipeerConnectivity** framework. No Wi-Fi, no cellular, no accounts — just open the app and start talking to whoever is around you.

---

## 📸 Overview

| Feature | Detail |
|---|---|
| Platform | iOS |
| Language | Swift + SwiftUI |
| Connectivity | Apple MultipeerConnectivity (Bluetooth + Wi-Fi Direct) |
| Internet Required | ❌ None |
| Accounts Required | ❌ None |
| Max Peers | Up to 8 (MCSession hardware limit) |

---

## 🗂️ Project Structure

```
ChatApp/
├── EntryPoint.swift        # App entry point, loads saved user data on launch
├── MultipeerSession.swift  # Core networking — advertise, browse, send, receive
├── MainView.swift          # Chat UI — message list, toolbar, input bar
├── Bubbles.swift           # Custom chat bubble shapes (left/right tailed)
├── Controls.swift          # Reusable UI components (BottomField, SettingsButton)
├── Name.swift              # Username modal sheet + UserName observable class
├── Data_Handle.swift       # Persist/load user data to local JSON file
└── Info.plist              # App permissions (Bonjour, Local Network)
```

---

## ⚙️ How It Works

### 1. App Launch — `EntryPoint.swift`
On startup, `loadAppData()` restores any previously saved user data (the display name) from the device's local Documents directory. `UserName` is created as a `@StateObject` and injected into the SwiftUI environment so all views share the same source of truth.

### 2. Peer Discovery — `MultipeerSession.swift`
This is the heart of the app. On init, `ChatMultipeerSession`:

- Creates an `MCSession` using the device's model name as its peer ID
- Starts an **`MCNearbyServiceAdvertiser`** — broadcasts presence under the service type `"nearby-chat"`
- Starts an **`MCNearbyServiceBrowser`** — actively scans for other devices on the same service

**Auto-connection:** When a peer is found, the browser immediately invites them. When an invitation arrives, it is automatically accepted — no manual pairing needed.

```
Device A                            Device B
  │                                    │
  │── startAdvertising ───────────────▶│ (visible)
  │◀─ Browser finds A ─────────────────│
  │◀─ invitePeer ───────────────────── │
  │── invitationHandler(true) ────────▶│
  │◀═══════════ MCSession Connected ═══│
  │◀═══════════ Messages flow ══════════│
```

### 3. Sending a Message — `send()` in `MultipeerSession.swift`
When you hit send:

1. Two `MessageElementType` structs are created from the same text — one with `isSelf: true` (stored locally) and one with `isSelf: false` (broadcast to peers)
2. The local copy is appended to `chatMessages` immediately so you see your own message right away
3. The outgoing copy is JSON-encoded and sent to all connected peers via `session.send(_:toPeers:with: .reliable)`

### 4. Receiving a Message — `MCSessionDelegate`
Incoming `Data` is decoded from JSON into a `MessageElementType`. It's appended to `chatMessages` on the main thread, triggering a SwiftUI re-render that shows the new bubble.

### 5. Chat UI — `MainView.swift`
- **Toolbar left:** live peer count with a radio-wave icon — updates as devices connect/disconnect
- **Toolbar right:** "Name" button opens the username sheet
- **Message list:** a `ScrollView` of `ChatMessage` views; sender name appears below the last consecutive bubble from that person (iMessage-style grouping)
- **Bottom bar (`BottomField`):** capsule text field + paperplane button; button is greyed out when field is empty

### 6. Chat Bubbles — `Bubbles.swift`
Bubbles are custom SwiftUI `Shape`s drawn with hand-crafted Bézier curves — the classic messenger tail. Your messages appear **blue on the right**; others appear **grey on the left**.

### 7. Username — `Name.swift`
A modal sheet lets you set a display name. It's stored via `@AppStorage` (UserDefaults) so it survives app restarts. The default name is `"Anonymous"`.

### 8. Data Persistence — `Data_Handle.swift`
The `DataTemplate` object (currently just the user's name) is JSON-serialized and saved to `chatapp.data` in the app's Documents directory. It's loaded at launch and saved on changes.

> **Note:** Chat messages are NOT persisted. They exist only for the duration of the session.

---

## 🔒 Privacy

- **No server** — messages never leave the local device-to-device network
- **No message history** — chat is wiped when the app closes
- **No login** — identity is just a name you choose yourself
- The peer's `identifierForVendor` UUID is used internally to group bubbles by sender but is never shown to users

---

## 📋 Requirements

- iOS 16+ (uses `NavigationStack`)
- Xcode 14+
- **Two physical iPhones** — MultipeerConnectivity does not work on the Simulator

---

## 🔑 Permissions (`Info.plist`)

```xml
NSLocalNetworkUsageDescription  →  "Used to find and connect to nearby devices"
NSBonjourServices               →  _nearby-chat._tcp
                                    _nearby-chat._udp
```

---

## 🚀 Getting Started

```bash
git clone https://github.com/yourusername/ChatApp.git
```

1. Open `ChatApp.xcodeproj` in Xcode
2. Set your Apple Developer team under **Signing & Capabilities**
3. Build and run on **two physical iPhones**
4. Both devices will auto-discover and connect within seconds
5. Tap **Name** to set your display name, then start chatting

---

## ⚠️ Known Limitations

| Issue | Detail |
|---|---|
| Max ~8 peers | Hard limit imposed by `MCSession` |
| No message history | Chat is ephemeral by design |
| Device model as peer ID | Two identical iPhone models (e.g. two iPhone 14s) may show duplicate peer IDs |
| All invitations auto-accepted | No way to block or approve specific peers |
| No auto-scroll | New messages don't scroll the view to the bottom |
| Force-unwrapped `identifierForVendor` | Will crash if `nil` (rare edge case) |

---

## 💡 Possible Improvements

- Auto-scroll to latest message
- Scroll-to-bottom button
- Peer approval / block list
- Image or file sharing
- Custom room/session names
- Unique display names as peer IDs instead of device model

---

## 📄 License

[MIT](LICENSE)
