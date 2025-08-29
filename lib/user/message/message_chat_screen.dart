import 'package:flutter/material.dart';

class MessageChatScreen extends StatefulWidget {
  const MessageChatScreen({Key? key}) : super(key: key);

  @override
  State<MessageChatScreen> createState() => _MessageChatScreenState();
}

class _MessageChatScreenState extends State<MessageChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> messages = [
    {'fromMe': true, 'text': 'Good morning, ma’am castro.'},
    {'fromMe': false, 'text': 'Good morning john, yes, how may i help you?'},
    {'fromMe': true, 'text': 'May i ask what is the activity all about for lesson 8?'},
    {'fromMe': false, 'text': 'Will be posted later john.'},
    {'fromMe': true, 'text': 'okay ma’am, thank you so much!'},
    {'fromMe': false, 'text': 'you’re always welcome'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/images/Photo (1).png'),
              radius: 18,
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mia Castro', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16)),
                Text('Online', style: TextStyle(color: Color(0xFF34A853), fontSize: 13)),
              ],
            ),
          ],
        ),
        centerTitle: false,
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final m = messages[i];
                final isMe = m['fromMe'] as bool;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isMe)
                          CircleAvatar(
                            backgroundImage: AssetImage('assets/images/Photo (1).png'),
                            radius: 16,
                          ),
                        if (!isMe) const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isMe ? const Color(0xFF34A853) : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                              boxShadow: [if (!isMe) BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                            ),
                            child: Text(
                              m['text'],
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        if (isMe) const SizedBox(width: 8),
                        if (isMe)
                          CircleAvatar(
                            backgroundImage: AssetImage('assets/images/Photo (3).png'),
                            radius: 16,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Image.asset('assets/icons/Vector (8).png', width: 26, color: Colors.black45),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    cursorColor: Colors.black54,
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_controller.text.trim().isNotEmpty) {
                      setState(() {
                        messages.add({'fromMe': true, 'text': _controller.text.trim()});
                        _controller.clear();
                      });
                    }
                  },
                  child: Image.asset('assets/icons/akar-icons_send.png', width: 28, color: Color(0xFF34A853)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 