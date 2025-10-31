import 'package:flutter/material.dart';
import '../../shared/login/custom_drawer.dart';
import '../../shared/services/instructor_service.dart';
import '../../shared/widgets/instructor_avatar.dart';
import 'message_chat_screen.dart';

class MessageListScreen extends StatefulWidget {
  const MessageListScreen({super.key});

  @override
  State<MessageListScreen> createState() => _MessageListScreenState();
}

class _MessageListScreenState extends State<MessageListScreen> {
  int selectedDrawerIndex = 1;
  Map<String, dynamic>? selectedInstructor;
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedInstructor();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _isSearching = _searchController.text.isNotEmpty;
    });
  }

  bool _shouldShowInstructor() {
    if (selectedInstructor == null) return false;

    if (!_isSearching) return true;

    final searchQuery = _searchController.text.toLowerCase().trim();
    if (searchQuery.isEmpty) return true;

    final instructorName = (selectedInstructor!['name'] ?? '').toLowerCase();
    final instructorEmail = (selectedInstructor!['email'] ?? '').toLowerCase();

    return instructorName.contains(searchQuery) ||
        instructorEmail.contains(searchQuery);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
    });
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  void _handleTapOutside() {
    // Remove focus from search field and dismiss keyboard
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  Future<void> _loadSelectedInstructor() async {
    try {
      final instructor = await InstructorService.getSelectedInstructor();
      setState(() {
        selectedInstructor = instructor;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading selected instructor: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(
        selectedIndex: selectedDrawerIndex,
        onSelect: (i) {
          setState(() => selectedDrawerIndex = i);
          Navigator.pop(context);
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        title: const Text(
          'Message',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: _handleTapOutside,
        child: SafeArea(
          child: Column(
            children: [
              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    cursorColor: Colors.black54,
                    style: const TextStyle(color: Colors.black87, fontSize: 15),
                    textInputAction: TextInputAction.search,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Image.asset(
                          'assets/icons/akar-icons_search.png',
                          width: 22,
                          color: Colors.black45,
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      suffixIcon:
                          _isSearching
                              ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: _clearSearch,
                                color: Colors.black45,
                              )
                              : null,
                      hintText: 'Search instructor...',
                      hintStyle: const TextStyle(
                        color: Colors.black38,
                        fontSize: 15,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _isSearching = value.isNotEmpty;
                      });
                    },
                    onSubmitted: (value) {
                      setState(() {
                        _isSearching = value.isNotEmpty;
                      });
                      _searchFocusNode.unfocus();
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
              ),

              // Main content
              Expanded(
                child: GestureDetector(
                  onTap: _handleTapOutside,
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34A853)),
        ),
      );
    }

    if (selectedInstructor == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No instructor selected',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Please select an instructor first',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!_shouldShowInstructor()) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No instructor found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Try searching with a different term',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _clearSearch,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Clear Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34A853),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListTile(
      leading: InstructorProfileAvatar(
        profileImage:
            selectedInstructor!['profileImageUrl'] ??
            selectedInstructor!['profileImage'],
        name: selectedInstructor!['name'],
        isOnline: selectedInstructor!['isOnline'] ?? false,
      ),
      title: Text(
        selectedInstructor!['name'] ?? 'Unknown Instructor',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        selectedInstructor!['isOnline'] == true ? 'Online' : 'Offline',
        style: TextStyle(
          color:
              selectedInstructor!['isOnline'] == true
                  ? const Color(0xFF34A853)
                  : Colors.grey,
        ),
      ),
      trailing: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => MessageChatScreen(instructor: selectedInstructor!),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF34A853),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
        ),
        child: const Text('Chat'),
      ),
    );
  }
}
