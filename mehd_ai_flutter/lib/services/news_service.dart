import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NewsArticle {
  final String category;
  final int datetime;
  final String headline;
  final int id;
  final String image;
  final String related;
  final String source;
  final String summary;
  final String url;

  NewsArticle({
    required this.category,
    required this.datetime,
    required this.headline,
    required this.id,
    required this.image,
    required this.related,
    required this.source,
    required this.summary,
    required this.url,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      category: json['category'] ?? '',
      datetime: json['datetime'] ?? 0,
      headline: json['headline'] ?? '',
      id: json['id'] ?? 0,
      image: json['image'] ?? '',
      related: json['related'] ?? '',
      source: json['source'] ?? '',
      summary: json['summary'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

class NewsService {
  // Use the User's Finnhub API Key
  static const _finnhubApiKey = 'd8rhtbpr01qnkitn2690d8rhtbpr01qnkitn269g'; 
  
  /// Fetches the latest general market news.
  Future<List<NewsArticle>> fetchGeneralNews() async {
    return _fetchNews('general');
  }

  /// Fetches the latest forex news.
  Future<List<NewsArticle>> fetchForexNews() async {
    return _fetchNews('forex');
  }
  
  /// Fetches the latest crypto news.
  Future<List<NewsArticle>> fetchCryptoNews() async {
    return _fetchNews('crypto');
  }

  Future<List<NewsArticle>> _fetchNews(String category) async {
    final url = Uri.parse('https://finnhub.io/api/v1/news?category=$category&minId=10&token=$_finnhubApiKey');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => NewsArticle.fromJson(json)).toList();
      } else {
        if (kDebugMode) {
          print('Failed to load news: \${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching news: $e');
      }
    }
    return [];
  }
}
