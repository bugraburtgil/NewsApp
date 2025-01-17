import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:news_app/models/articles.dart';
import 'package:news_app/models/news.dart';
// ignore: duplicate_import
import 'dart:convert';
// ignore: duplicate_import
import 'package:http/http.dart' as http;

class NewsService {
  Future<List<Articles>> fetchNews(String category) async {
    String apiKey = '6c2643e026824c38851c1e4b1c5d316e';
    String baseUrl = 'https://newsapi.org/v2/top-headlines';

    String url = '$baseUrl?country=us&category=$category&apiKey=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      News news = News.fromJson(result);
      return news.articles ?? [];
    }
    throw Exception('Bad Request');
  }
}
