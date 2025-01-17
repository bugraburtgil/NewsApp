import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:news_app/main.dart';
import 'package:news_app/models/category.dart';

class CategorySelectionHelper {
  static Future<bool> hasSelectedCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasSelectedCategories') ?? false;
  }

  static Future<void> setSelectedCategories(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSelectedCategories', value);
  }
}

class CategorySelectionPage extends StatefulWidget {
  const CategorySelectionPage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _CategorySelectionPageState createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  final List<Category> categories = [
    Category('business', 'BUSINESS',
        'https://w7.pngwing.com/pngs/311/397/png-transparent-logo-business-logistics-service-business-angle-hand-service.png'),
    Category('entertainment', 'ENTERTAINMENT',
        'https://w7.pngwing.com/pngs/994/399/png-transparent-computer-icons-amusement-park-icon-design-park-text-photography-logo.png'),
    Category('health', 'HEALTH',
        'https://e7.pngegg.com/pngimages/311/461/png-clipart-public-health-computer-icons-health-hand-logo.png'),
    Category('science', 'SCIENCE',
        'https://w7.pngwing.com/pngs/694/678/png-transparent-computer-icons-atom-physics-science-science-logo-atom-symbol.png'),
    Category('sports', 'SPORTS',
        'https://w7.pngwing.com/pngs/546/1022/png-transparent-running-free-content-runner-text-sport-logo.png'),
    Category('technology', 'TECHNOLOGY',
        'https://e7.pngegg.com/pngimages/847/65/png-clipart-technology-logo-virtual-reality-symbol-technology-electronics-3d-computer-graphics.png'),
  ];

  Set<String> selectedCategories = {};
  @override
  void initState() {
    super.initState();
    // initState içinde selectedCategories set'ini boşalt
    selectedCategories.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                children: categories.map((category) {
                  final isSelected = selectedCategories.contains(category.key);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedCategories.remove(category.key);
                        } else {
                          selectedCategories.add(category.key);
                        }
                      });
                    },
                    child: Card(
                      color: isSelected ? Colors.red : Colors.white,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            category.imageLink,
                            height: 100,
                            width: 100,
                            fit: BoxFit.contain,
                          ),
                          Text(
                            category.value,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Save Selection',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveSelection() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Seçilen kategorilerin listesini oluştur
      List<String> selectedCategoriesList = selectedCategories.toList();

      // Eğer seçilen kategoriler listesi boşsa, "general" kategorisini ekleyelim
      if (selectedCategoriesList.isEmpty) {
        selectedCategoriesList.add('general');
      }

      // Firestore'da kullanıcı belgesini güncelleyelim
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'categories': selectedCategoriesList}, SetOptions(merge: true));

      // Kullanıcıya seçim kaydedildiğine dair bir mesaj gösterelim
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selection Saved!')),
      );

      // Seçim durumu SharedPreferences'a kaydediliyor
      await CategorySelectionHelper.setSelectedCategories(true);

      // Yeni seçilen kategorileri ve "general" kategorisini aldıktan sonra
      // uygulamayı NewsPage'e yönlendirelim
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MyApp(
            hasSelectedCategories:
                true, // Kullanıcının kategorileri seçtiği varsayılsın
          ),
        ),
      );
    }
  }
}
