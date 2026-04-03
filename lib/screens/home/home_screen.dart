import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product_model.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/product_card.dart';
import '../../utils/constants.dart';
import 'post_item_screen.dart';
import 'product_details_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _saveToken();
  }

  Future<void> _saveToken() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user != null) {
      final notificationService = NotificationService();
      final token = await notificationService.getToken();
      if (token != null) {
        await chatProvider.saveUserToken(user.uid, token);
      }
    }
  }

  final List<Widget> _screens = [
    const HomeContent(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: StreamBuilder<List<Map<String, dynamic>>>(
        stream: user != null ? chatProvider.getUserChats(user.uid) : const Stream.empty(),
        builder: (context, snapshot) {
          int totalUnread = 0;
          if (snapshot.hasData) {
            for (var chat in snapshot.data!) {
              final unreadCountMap = chat['unreadCount'] as Map<String, dynamic>?;
              if (unreadCountMap != null && user != null) {
                totalUnread += (unreadCountMap[user.uid] ?? 0) as int;
              }
            }
          }

          return NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Badge(
                  label: Text(totalUnread.toString()),
                  isLabelVisible: totalUnread > 0,
                  child: const Icon(Icons.chat_bubble_outline),
                ),
                selectedIcon: Badge(
                  label: Text(totalUnread.toString()),
                  isLabelVisible: totalUnread > 0,
                  child: const Icon(Icons.chat_bubble),
                ),
                label: 'Chat',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PostItemScreen()));
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
          appBar: AppBar(
            title: const Text('CampusBazaar'),
            actions: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatListScreen()),
                  );
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                    });
                  },
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              // Category Filter
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    _buildCategoryChip('All'),
                    ...Constants.categories.map((c) => _buildCategoryChip(c)),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<ProductModel>>(
                  stream: productProvider.productsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingIndicator();
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No items found'));
                    }

                    final products = snapshot.data!.where((product) {
                      final matchCategory = _selectedCategory == 'All' ||
                          product.category == _selectedCategory;
                      final matchSearch =
                          product.title.toLowerCase().contains(_searchQuery) ||
                              product.description.toLowerCase().contains(_searchQuery);
                      return matchCategory && matchSearch;
                    }).toList();

                    if (products.isEmpty) {
                      return const Center(child: Text('No matching items'));
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return ProductCard(
                          product: products[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailsScreen(product: products[index]),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = _selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = label;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            )),
      ),
    );
  }
}
