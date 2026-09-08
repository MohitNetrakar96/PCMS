# React Native Map & Navigation Feature Module

A complete, plug-and-play **React Native Map & Turn-by-Turn Navigation Module** built for collection agent apps.

---

## 📁 File Structure

All feature files are placed inside `react-native-map-feature/src/`:

```
react-native-map-feature/
└── src/
    ├── types.ts                        # Data models (HouseRecord, AgentLocation, etc.)
    ├── AgentMapNavigationScreen.tsx     # Main React Native Screen component
    ├── hooks/
    │   └── useAgentLocation.ts         # Location permission & live GPS tracking hook
    └── utils/
        ├── geocoding.ts                # Google Geocoding API with AsyncStorage caching
        ├── routeOptimizer.ts           # Nearest-Neighbor TSP route ordering algorithm
        ├── navigationLauncher.ts       # Deep-link launcher for Google Maps / Apple Maps
        └── offlineSync.ts              # Local cache & offline sync queue
```

---

## 📦 1. Installation

Run in your React Native project:

```bash
npm install react-native-maps react-native-geolocation-service @react-native-asyncstorage/asyncstorage @react-native-community/netinfo
```

For iOS:
```bash
cd ios && pod install && cd ..
```

---

## ⚙️ 2. Native Permissions & API Keys

### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />

<application>
  <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="YOUR_GOOGLE_MAPS_API_KEY" />
</application>
```

### iOS (`ios/YourAppName/Info.plist`)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location access is needed to show nearby collection stops and provide turn-by-turn navigation.</string>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>comgooglemaps</string>
    <string>maps</string>
</array>
```

---

## 🔌 3. Integration Example

Slot `AgentMapNavigationScreen` directly into your existing React Native Navigation stack:

```tsx
import React from 'react';
import AgentMapNavigationScreen from './src/features/map/AgentMapNavigationScreen';
import { api } from './src/services/api'; // Your existing backend API service

export default function MapScreen(props) {
  return (
    <AgentMapNavigationScreen
      {...props}
      fetchHouseListApi={api.getDailyHouses}
      updateHouseStatusApi={api.updateHouseStatus}
    />
  );
}
```
