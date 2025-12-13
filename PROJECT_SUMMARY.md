# TeamMate App - Project Summary

## 專案概述
TeamMate 是一個運動夥伴配對應用程式，讓使用者可以找到附近的運動夥伴，一起參與各種運動活動。

## 已完成功能

### ✅ 專案架構設置
- Flutter 專案初始化
- 完整的資料夾結構 (models, screens, services, widgets, utils)
- 依賴套件安裝完成

### ✅ 身份驗證系統
- **Google Authentication**（透過 Supabase Auth，取代原本的 World ID）
- 登入/登出功能
- 自動身份驗證狀態管理（監聽 Supabase `onAuthStateChange`）

### ✅ 資料模型 (Models)
1. **UserProfile** - 使用者資料
   - 基本資訊 (ID, email, 名稱, 照片)
   - 運動偏好
   - GPS 位置

2. **Activity** - 活動資料
   - 活動資訊 (標題, 描述, 類型)
   - 時間與地點
   - 參加人數管理
   - 狀態追蹤

3. **Rating** - 評價系統
   - 1-5 星評分
   - 評論功能

### ✅ 服務層 (Services)
1. **AuthService** - 身份驗證服務
   - Google 登入整合
   - Firebase 與 Supabase 同步
   - 用戶狀態管理

2. **DatabaseService** - 資料庫服務
   - Supabase 整合
   - CRUD 操作 (建立、讀取、更新、刪除)
   - 附近活動查詢
   - 參加者管理

3. **LocationService** - 位置服務
   - GPS 定位
   - 權限管理
   - 地址解析
   - 距離計算

### ✅ 使用者介面 (Screens)
1. **LoginScreen** - 登入畫面
   - Google 一鍵登入
   - 友善的 UI 設計

2. **HomeScreen** - 主畫面
   - 底部導航列
   - 四個主要功能區塊

3. **NearbyActivitiesScreen** - 附近活動
   - 顯示附近的運動活動
   - 活動類型篩選
   - 下拉重新整理

4. **CreateActivityScreen** - 建立活動
   - 選擇運動類型 (籃球、羽毛球、跑步等)
   - 設定時間與地點
   - 參加人數上限設定

5. **MyActivitiesScreen** - 我的活動
   - 顯示使用者建立的活動
   - 活動管理

6. **ProfileScreen** - 個人資料
   - 顯示使用者資訊
   - 設定選項
   - 登出功能

### ✅ UI 組件 (Widgets)
1. **ActivityCard** - 活動卡片
   - 顯示活動詳細資訊
   - 運動類型圖示
   - 距離顯示
   - 狀態標籤

## 技術堆疊

### 前端
- **Framework**: Flutter 3.38.5
- **語言**: Dart 3.10.4
- **狀態管理**: Provider (已安裝)
- **UI**: Material Design 3

### 後端服務
- **Authentication**: Supabase Auth（Google OAuth，支援 Web/Native）
- **Database**: Supabase (PostgreSQL)
- **位置服務**: Google Maps, Geolocator, Geocoding
- **推播通知**: OneSignal (已設置，待實作)

### 已安裝套件
```yaml
dependencies:
  # 狀態管理
  provider: ^6.1.2
  
  # 身份驗證
   # 資料庫與認證
  supabase_flutter: ^2.9.6
  
  # HTTP
  http: ^1.2.2
  dio: ^5.7.0
  
  # 地圖與位置
  google_maps_flutter: ^2.10.0
  geolocator: ^13.0.2
  geocoding: ^3.0.0
  
  # 推播通知
  onesignal_flutter: ^5.2.9
  
  # UI 組件
  flutter_svg: ^2.0.16
  cached_network_image: ^3.4.1
  shimmer: ^3.0.0
  
  # 工具
  intl: ^0.19.0
  shared_preferences: ^2.3.4
  uuid: ^4.5.1
```

## 資料庫結構 (Supabase)

### Users Table
- 儲存使用者基本資料
- GPS 位置資訊
- 運動偏好

### Activities Table  
- 活動詳細資訊
- 時間地點
- 參加人數

### Activity_Participants Table
- 活動參加者關聯
- 加入時間記錄

### Ratings Table
- 活動評價
- 星級評分與評論

## 待完成功能

### 🔲 高優先級
1. **Supabase 配置**
   - 建立資料庫表格
   - 更新 Constants 中的 URL 和 API Key

2. **Google Maps 整合**
   - 地圖顯示
   - 標記活動位置
   - 路線規劃

3. **活動詳情頁面**
   - 完整活動資訊
   - 參加者列表
   - 加入/退出功能

### 🔲 中優先級
5. **OneSignal 推播通知**
   - 活動提醒
   - 新參加者通知
   - 活動更新通知

6. **評價系統實作**
   - 活動完成後評分
   - 查看其他使用者評價
   - 信譽分數計算

7. **進階搜尋**
   - 多條件篩選
   - 地圖模式查看
   - 收藏功能

### 🔲 低優先級
8. **社交功能**
   - 好友系統
   - 追蹤使用者
   - 私人訊息

9. **數據分析**
   - 參與統計
   - 活動熱度分析
   - 使用者行為追蹤

10. **AI 推薦**
    - 基於偏好的活動推薦
    - 智能配對

## 下一步行動

### 立即需要做的事情:

1. **設置 Supabase**
   - 登入 [Supabase](https://supabase.com)
   - 創建專案並執行 SQL (見 README.md)
   - 更新 `lib/utils/constants.dart`

2. **測試基本功能**
   ```bash
   flutter run
   ```

3. **配置位置權限**
   - iOS: 更新 Info.plist
   - Android: 已在 AndroidManifest.xml 中

## 文件說明

- **README.md** - 專案說明與資料庫結構
- **SETUP.md** - 詳細配置指南
- **lib/** - 所有原始碼
  - **main.dart** - 應用程式入口
  - **models/** - 資料模型
  - **screens/** - 畫面頁面
  - **services/** - 後端服務整合
  - **widgets/** - 可重用 UI 組件
  - **utils/** - 常數與工具函數

## 備註

- 移除了 World ID 驗證，改用 Supabase Google Authentication
- 所有畫面使用繁體中文介面
- 已預留 OneSignal 推播通知功能
- 資料庫使用 Supabase (PostgreSQL)
- 支援 8 種運動類型 (籃球、羽毛球、跑步、騎車、游泳、登山、網球、足球)

## 聯絡與支援

如有任何問題，請參考:
- README.md - 完整專案說明
- SETUP.md - 配置步驟指南
- 程式碼註解 - 詳細的功能說明
