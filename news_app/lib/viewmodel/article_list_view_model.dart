import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app/services/news_service.dart';
// ignore: unused_import
import 'package:news_app/viewmodel/article_view_model.dart';

enum Status { initial, loading, loaded }

class ArticleListViewModel extends ChangeNotifier {
  ArticleViewModel viewModel = ArticleViewModel('general', []);
  Status status = Status.initial;

  ArticleListViewModel() {
    _fetchUserCategoriesAndNews();
  }

  Future<void> _fetchUserCategoriesAndNews() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    // Kullanıcının seçtiği kategorileri Firebase'den çekme
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    List<String> selectedCategories =
        List<String>.from(userDoc['categories'] ?? []);

    if (selectedCategories.isEmpty) {
      // Eğer kullanıcı kategori seçmediyse, genel haberleri göster
      await getNews('general');
    } else {
      // Seçilen kategorilerle haberleri çek
      await getNewsForCategories(selectedCategories);
    }
  }

  Future<void> getNewsForCategories(List<String> categories) async {
    status = Status.loading;
    notifyListeners();

    List<ArticleViewModel> allArticles = [];
    for (String category in categories) {
      final news = await NewsService().fetchNews(category);
      allArticles.addAll(news
          .map((article) => ArticleViewModel.fromArticle(article as Article))
          .toList());
    }

    viewModel =
        ArticleViewModel(categories.join(','), allArticles.cast<Article>());
    status = Status.loaded;
    notifyListeners();
  }

  Future<void> getNews(String category) async {
    status = Status.loading;
    notifyListeners();

    final news = await NewsService().fetchNews(category);
    viewModel.articles = news
        .map((article) => ArticleViewModel.fromArticle(article as Article))
        .cast<Article>()
        .toList();
    status = Status.loaded;
    notifyListeners();
  }
}

class ArticleViewModel {
  final String category;
  late final List<Article> articles;

  ArticleViewModel(this.category, this.articles);

  factory ArticleViewModel.fromArticle(Article article) {
    return ArticleViewModel(article.category, [article]);
  }
}

class Article {
  final String category;
  final String title;
  final String description;
  final String url;
  final String urlToImage;

  Article({
    required this.category,
    required this.title,
    required this.description,
    required this.url,
    required this.urlToImage,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      category: json['category'],
      title: json['title'],
      description: json['description'],
      url: json['url'],
      urlToImage: json['urlToImage'],
    );
  }
}
