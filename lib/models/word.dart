import 'dart:convert';

class Word {
  final int id;
  String term;
  String meaning;
  bool favorite;

  Word({
    required this.id,
    required this.term,
    required this.meaning,
    this.favorite = false,
  });

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
