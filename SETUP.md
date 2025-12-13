### 1. Supabase Auth（Google OAuth）設定

1. 前往 [Supabase](https://supabase.com/) 建立專案
2. 啟用 Google Provider：
   - 進入 Dashboard → Authentication → Providers
   - 啟用 Google，設定必要的 Client ID / Secret（依官方指南）
   - 設定 Redirect URLs（Web/Native）：
     - Web: `http://localhost:3000/auth/callback`（開發環境可用）
     - Native: `io.supabase.teammate://login-callback/`
3. 取得 `Project URL` 與 `anon public key`（Settings → API）
4. 更新 `lib/utils/constants.dart` 中 Supabase 設定
5. 在 `main.dart` 解除註解 `Supabase.initialize()` 初始化
### 2. OneSignal Setup（選填）

1. Go to [OneSignal](https://onesignal.com/)
2. Create a new app
3. Get your App ID from Settings > Keys & IDs
4. Configure for iOS and Android following OneSignal's guides
5. Update `lib/utils/constants.dart` with your App ID
### 3. Location Permissions

#### iOS - Update `ios/Runner/Info.plist`:
<key>NSLocationWhenInUseUsageDescription</key>
<string>我們需要您的位置來顯示附近的運動活動</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>我們需要您的位置來顯示附近的運動活動</string>
### 4. iOS Additional Setup

Add to `ios/Podfile`:
```ruby
platform :ios, '13.0'
```
Then run:
```bash
cd ios
pod install
cd ..
```
### 5. Android Additional Setup

Update `android/app/build.gradle`:
```gradle
android {
  compileSdkVersion 34
    
  defaultConfig {
    minSdkVersion 21
    targetSdkVersion 34
  }
}
```
## Environment Variables（選填）

Create a `.env` file in the root directory (optional, for future use):
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
ONESIGNAL_APP_ID=your_onesignal_app_id
```
## Verify Setup

Run the following command to check for issues:
```bash
flutter doctor -v
```
## Troubleshooting

### Supabase Auth Issues
- 確認 Providers 已啟用 Google，且 Redirect URLs 正確
- 檢查 `constants.dart` 的 URL/Key 是否正確
- Web 平台需使用對應的 redirect URL
# Configuration Setup Guide

## Step-by-Step Configuration

### 1. Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing project
3. Enable Google Sign-In:
   - Go to Authentication > Sign-in method
   - Enable "Google" provider
   - Add support email

#### For iOS:
\`\`\`bash
# Install Firebase CLI if not already installed
curl -sL https://firebase.tools | bash

# Login to Firebase
firebase login

# Initialize Firebase in your project
cd ios
firebase init

# Add iOS app in Firebase Console and download GoogleService-Info.plist
# Move the file to ios/Runner/ directory
\`\`\`

#### For Android:
\`\`\`bash
# Add Android app in Firebase Console
# Download google-services.json
# Move the file to android/app/ directory
\`\`\`

### 2. Supabase Setup

1. Go to [Supabase](https://supabase.com/)
2. Create a new project
3. Get your project URL and anon key from Settings > API
4. Create the database tables using the SQL from README.md
5. Update \`lib/utils/constants.dart\` with your credentials

### 3. Google Maps API Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Geocoding API
4. Create credentials (API Key)
5. Restrict the API key (recommended for production)

#### For iOS:
Add to \`ios/Runner/AppDelegate.swift\`:
\`\`\`swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
\`\`\`

#### For Android:
Add to \`android/app/src/main/AndroidManifest.xml\`:
\`\`\`xml
<manifest ...>
    <application ...>
        ...
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
    </application>
</manifest>
\`\`\`

### 4. OneSignal Setup

1. Go to [OneSignal](https://onesignal.com/)
2. Create a new app
3. Get your App ID from Settings > Keys & IDs
4. Configure for iOS and Android following OneSignal's guides
5. Update \`lib/utils/constants.dart\` with your App ID

### 5. Location Permissions

#### iOS - Update \`ios/Runner/Info.plist\`:
\`\`\`xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>我們需要您的位置來顯示附近的運動活動</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>我們需要您的位置來顯示附近的運動活動</string>
\`\`\`

#### Android - Update \`android/app/src/main/AndroidManifest.xml\`:
\`\`\`xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
\`\`\`

### 6. iOS Additional Setup

Add to \`ios/Podfile\`:
\`\`\`ruby
platform :ios, '13.0'
\`\`\`

Then run:
\`\`\`bash
cd ios
pod install
cd ..
\`\`\`

### 7. Android Additional Setup

Update \`android/app/build.gradle\`:
\`\`\`gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
\`\`\`

## Environment Variables

Create a \`.env\` file in the root directory (optional, for future use):
\`\`\`
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
ONESIGNAL_APP_ID=your_onesignal_app_id
\`\`\`

## Verify Setup

Run the following command to check for issues:
\`\`\`bash
flutter doctor -v
\`\`\`

## Troubleshooting

### Firebase Issues
- Make sure Firebase packages are up to date
- Verify GoogleService-Info.plist (iOS) or google-services.json (Android) are in correct locations
- Run \`flutter clean\` and rebuild

### Location Issues
- Check permissions in Info.plist (iOS) and AndroidManifest.xml (Android)
- Test on physical device (simulators may have limited location features)

### Build Issues
- Run \`flutter clean\`
- Delete \`ios/Pods\` and \`Podfile.lock\`, then run \`pod install\`
- For Android, clean build with \`cd android && ./gradlew clean\`
