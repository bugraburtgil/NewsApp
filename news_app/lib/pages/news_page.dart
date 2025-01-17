import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app/models/articles.dart';
import 'package:news_app/pages/CategorySelectionPage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../models/category.dart';
import '../services/news_service.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({Key? key}) : super(key: key);

  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  List<Category> categories = <Category>[
    Category('general', 'Genel',
        'https://w7.pngwing.com/pngs/926/161/png-transparent-news-logo-logo-newspaper-computer-icons-newspaper-miscellaneous-television-text-thumbnail.png'),
    Category('business', 'İş',
        'https://w7.pngwing.com/pngs/311/397/png-transparent-logo-business-logistics-service-business-angle-hand-service.png'),
    Category('entertainment', 'Eğlence',
        'https://w7.pngwing.com/pngs/994/399/png-transparent-computer-icons-amusement-park-icon-design-park-text-photography-logo.png'),
    Category('health', 'Sağlık',
        'https://e7.pngegg.com/pngimages/311/461/png-clipart-public-health-computer-icons-health-hand-logo.png'),
    Category('science', 'Bilim',
        'https://w7.pngwing.com/pngs/694/678/png-transparent-computer-icons-atom-physics-science-science-logo-atom-symbol.png'),
    Category('sports', 'Spor',
        'https://w7.pngwing.com/pngs/546/1022/png-transparent-running-free-content-runner-text-sport-logo.png'),
    Category('technology', 'Teknoloji',
        'https://e7.pngegg.com/pngimages/847/65/png-clipart-technology-logo-virtual-reality-symbol-technology-electronics-3d-computer-graphics.png'),
  ];

  String selectedCategory = '';
  List<Map<String, dynamic>> news = [];
  List<String> userCategories = [];
  bool _isLoading = false;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _fetchUserCategories();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> _fetchUserCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (_isMounted) {
        setState(() {
          userCategories = [];
        });
      }
      return;
    }

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (_isMounted) {
      final fetchedUserCategories =
          List<String>.from(userDoc['categories'] ?? []);

      // Eğer belge varsa ve "categories" alanı yoksa veya kullanıcı kategori seçmediyse
      // varsayılan olarak 'general' kategorisini ekleyelim ve Firestore'a kaydedelim.
      if (!userDoc.exists || fetchedUserCategories.isEmpty) {
        fetchedUserCategories.add('general');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'categories': fetchedUserCategories});

        // Kullanıcıyı kategori seçim ekranına yönlendir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CategorySelectionPage()),
        );
      } else {
        setState(() {
          userCategories = fetchedUserCategories;
          selectedCategory = userCategories.first; // İlk kategoriyi seçelim
        });

        _fetchNewsByCategory(); // Seçilen kategoriye göre haberleri getirelim
      }
    }
  }

  Future<void> _fetchNewsByCategory() async {
    if (_isMounted) {
      setState(() {
        _isLoading = true;
      });
    }

    List<Articles> articles = await NewsService().fetchNews(selectedCategory);
    if (_isMounted) {
      setState(() {
        news = articles.map((article) => article.toJson()).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (_isMounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
        titleTextStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 25.0),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const CategorySelectionPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 60,
            width: double.infinity,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...categories
                    .where((category) => userCategories.contains(category.key))
                    .map((category) {
                  final isSelected = category.key == selectedCategory;
                  return GestureDetector(
                    onTap: () {
                      if (_isMounted) {
                        setState(() {
                          selectedCategory = category.key;
                        });
                        _fetchNewsByCategory();
                      }
                    },
                    child: Card(
                      color: isSelected ? Colors.red : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Text(
                          category.key.toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : news.isEmpty
                    ? const Center(child: Text('No news available'))
                    : ListView.builder(
                        itemCount: news.length,
                        itemBuilder: (context, index) {
                          final newsItem = news[index];
                          return Card(
                            child: Column(
                              children: [
                                Image.network(
                                  newsItem['urlToImage'] ??
                                      'https://thumbs.dreamstime.com/b/no-image-available-icon-flat-vector-no-image-available-icon-flat-vector-illustration-132484366.jpg',
                                ),
                                ListTile(
                                  title: Text(
                                    newsItem['title'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(newsItem['description'] ?? ''),
                                ),
                                ButtonBar(
                                  children: [
                                    MaterialButton(
                                      onPressed: () async {
                                        final url = newsItem['url'];
                                        if (url != null) {
                                          await _launchUrl(url);
                                        }
                                      },
                                      child: const Text(
                                        'DETAILS',
                                        style: TextStyle(color: Colors.blue),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
