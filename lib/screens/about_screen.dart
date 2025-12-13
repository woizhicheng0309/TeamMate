import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '載入中...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      setState(() {
        _version = '1.0.0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('關於我們'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Logo
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.groups,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'TeamMate',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '版本 $_version',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Description
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '關於 TeamMate',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'TeamMate 是一個運動社交平台，幫助運動愛好者找到志同道合的夥伴，'
                    '輕鬆組織和參與各種運動活動。無論是籃球、足球、羽毛球還是跑步，'
                    '都能在這裡找到合適的隊友！',
                    style: TextStyle(color: Colors.grey, height: 1.5),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Links
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.web),
                  title: const Text('官方網站'),
                  subtitle: const Text('https://teammate.com'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    // TODO: Open URL
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('開啟網頁功能開發中')),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('隱私政策'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showPolicyDialog(context, '隱私政策', _privacyPolicyText);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('服務條款'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showPolicyDialog(context, '服務條款', _termsOfServiceText);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('開源授權'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'TeamMate',
                      applicationVersion: _version,
                      applicationIcon: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.groups,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Center(
            child: Text(
              '© 2025 TeamMate. All rights reserved.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPolicyDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  static const _privacyPolicyText = '''
TeamMate 隱私政策

最後更新：2025年12月

1. 信息收集
我們收集以下類型的信息：
• 個人信息（姓名、電子郵件）
• 活動記錄
• 位置信息（經用戶同意）

2. 信息使用
收集的信息用於：
• 提供和改進服務
• 匹配運動夥伴
• 發送通知和更新

3. 信息保護
我們採取適當的安全措施保護您的信息。

4. 用戶權利
您有權：
• 訪問您的個人信息
• 要求更正或刪除信息
• 選擇退出特定服務

如有疑問，請聯絡：privacy@teammate.com
''';

  static const _termsOfServiceText = '''
TeamMate 服務條款

最後更新：2025年12月

1. 服務說明
TeamMate 提供運動社交平台服務。

2. 用戶責任
用戶同意：
• 提供真實信息
• 遵守社區規範
• 不從事非法活動

3. 內容政策
用戶發布的內容應：
• 尊重他人
• 不包含違法內容
• 不侵犯他人權利

4. 免責聲明
我們不對以下情況負責：
• 用戶之間的糾紛
• 活動中的安全事故
• 第三方服務的問題

5. 服務變更
我們保留隨時修改或終止服務的權利。

如有疑問，請聯絡：support@teammate.com
''';
}
