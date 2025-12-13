import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('幫助中心'),
      ),
      body: ListView(
        children: [
          _buildSection(
            context,
            title: '常見問題',
            icon: Icons.help_outline,
            items: [
              _HelpItem(
                question: '如何創建活動？',
                answer: '在首頁點擊「+」按鈕，填寫活動詳情後即可發布。',
              ),
              _HelpItem(
                question: '如何加入活動？',
                answer: '瀏覽附近活動列表，點擊感興趣的活動查看詳情，然後點擊「加入」按鈕。',
              ),
              _HelpItem(
                question: '如何與其他參與者聊天？',
                answer: '加入活動後，可以在活動詳情頁面進入群組聊天室。',
              ),
              _HelpItem(
                question: '如何修改個人資料？',
                answer: '進入個人資料頁面，點擊「編輯個人資料」即可修改。',
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            context,
            title: '聯絡我們',
            icon: Icons.contact_support,
            items: [
              _HelpItem(
                question: '客服信箱',
                answer: 'support@teammate.com',
              ),
              _HelpItem(
                question: '回覆時間',
                answer: '週一至週五 9:00-18:00',
              ),
            ],
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('意見反饋'),
            subtitle: const Text('告訴我們你的想法'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showFeedbackDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<_HelpItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => ExpansionTile(
              title: Text(item.question),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    item.answer,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            )),
      ],
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('意見反饋'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '請輸入你的意見或建議...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Submit feedback
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('感謝你的反饋！')),
              );
            },
            child: const Text('提交'),
          ),
        ],
      ),
    );
  }
}

class _HelpItem {
  final String question;
  final String answer;

  _HelpItem({required this.question, required this.answer});
}
