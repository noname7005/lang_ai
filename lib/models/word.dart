import 'dart:convert';

class Word {
  final int id;
  String term;
  String meaning;
  String topic;
  bool favorite;

  Word({
    required this.id,
    required this.term,
    required this.meaning,
    this.topic = '',
    this.favorite = false,
  });

  String get text => term;
  bool get isFavorite => favorite;
  set isFavorite(bool v) => favorite = v;


  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] as int,
      term: json['term'] as String,
      meaning: json['meaning'] as String,
      favorite: json['favorite'] as bool? ?? false,
    );
  }
  Map<String, dynamic> toJson() {
    return{
      'id' : id,
      'term' : term,
      'meaning' : meaning,
      'favorite' : favorite
    };
  }
}
