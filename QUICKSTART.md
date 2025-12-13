# 🚀 Quick Start Guide

## 快速開始 - 5 分鐘設置

### 步驟 1: 確認 Flutter 安裝
```bash
flutter doctor
```
✅ 應該看到 Flutter 已安裝成功

### 步驟 2: 安裝依賴
```bash
cd /Users/woizhicheng/Desktop/TeamMate/teammate_app
flutter pub get
```
✅ 已完成！所有套件已安裝

### 步驟 3: 配置 Firebase (必需)

#### 選項 A: 使用 FlutterFire CLI (推薦)
```bash
# 安裝 FlutterFire CLI
dart pub global activate flutterfire_cli

# 配置 Firebase (會自動處理 iOS 和 Android)
flutterfire configure
```

#### 選項 B: 手動設置
1. 前往 [Firebase Console](https://console.firebase.google.com/)
2. 創建新專案
3. 加入 iOS App:
   - 下載 `GoogleService-Info.plist`
   - 放到 `ios/Runner/` 目錄
4. 加入 Android App:
   - 下載 `google-services.json`
   - 放到 `android/app/` 目錄

### 步驟 4: 配置 Supabase (必需)

1. 前往 [Supabase](https://supabase.com/) 並創建專案
2. 在 SQL Editor 中執行以下 SQL:

```sql
-- Users Table
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  display_name TEXT,
  photo_url TEXT,
  phone_number TEXT,
  interests TEXT[],
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Activities Table
CREATE TABLE activities (
  id TEXT PRIMARY KEY,
  creator_id TEXT REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT,
  activity_type TEXT NOT NULL,
  event_date TIMESTAMP NOT NULL,
  duration TEXT,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  address TEXT,
  max_participants INTEGER NOT NULL,
  current_participants INTEGER DEFAULT 0,
  status TEXT DEFAULT 'open',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Activity Participants Table
CREATE TABLE activity_participants (
  id SERIAL PRIMARY KEY,
  activity_id TEXT REFERENCES activities(id),
  user_id TEXT REFERENCES users(id),
  joined_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(activity_id, user_id)
);

-- Ratings Table
CREATE TABLE ratings (
  id SERIAL PRIMARY KEY,
  activity_id TEXT REFERENCES activities(id),
  user_id TEXT REFERENCES users(id),
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

3. 獲取 Supabase 憑證:
   - 前往 Settings > API
   - 複製 `Project URL` 和 `anon public` key

4. 更新 `lib/utils/constants.dart`:
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 步驟 5: 運行應用程式

```bash
# 查看可用設備
flutter devices

# 運行在特定設備 (例如: Chrome)
flutter run -d chrome

# 或運行在 iOS 模擬器
flutter run -d iPhone

# 或運行在 Android 模擬器
flutter run -d emulator
```

## ⚡ 開發中快速測試 (跳過後端設置)

如果您想先測試 UI，暫時跳過 Firebase 和 Supabase 設置:

1. 註解掉 `lib/main.dart` 中的 Firebase 和 Supabase 初始化:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // // Initialize Firebase
  // await Firebase.initializeApp();
  
  // // Initialize Supabase
  // await Supabase.initialize(
  //   url: Constants.supabaseUrl,
  //   anonKey: Constants.supabaseAnonKey,
  // );
  
  runApp(const MyApp());
}
```

2. 然後您可以查看 UI 設計，但登入功能將無法使用

## 🎯 功能測試清單

完成設置後，測試這些功能:

- [ ] 使用 Google 帳號登入
- [ ] 查看附近活動 (需要位置權限)
- [ ] 建立新活動
- [ ] 查看我的活動列表
- [ ] 查看個人資料
- [ ] 登出

## 🐛 常見問題

### Q: Flutter command not found
A: 重新啟動終端機或確認 Flutter 已正確安裝

### Q: Firebase 初始化錯誤
A: 確認 GoogleService-Info.plist 和 google-services.json 在正確位置

### Q: Location permission denied
A: 
- iOS: 檢查 Info.plist 中的位置權限描述
- Android: 檢查 AndroidManifest.xml 中的權限設定

### Q: Supabase connection error
A: 檢查 Constants.dart 中的 URL 和 Key 是否正確

## 📚 更多資訊

- 完整文檔: 查看 `README.md`
- 詳細設置: 查看 `SETUP.md`
- 專案概述: 查看 `PROJECT_SUMMARY.md`

## 🎉 準備好了！

現在您可以開始開發您的運動夥伴配對 App 了！

```bash
flutter run
```

Good luck! 🏀🏸🏃‍♂️
