import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Invite {
  final String id;
  final String title;
  final String author;
  final DateTime publicationDate;
  final String content;
  final String contactLink;

  const Invite({
    required this.id,
    required this.title,
    required this.author,
    required this.publicationDate,
    required this.content,
    required this.contactLink,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'publicationDate': Timestamp.fromMillisecondsSinceEpoch(
        publicationDate.millisecondsSinceEpoch,
      ),
      'content': content,
      'contactLink': contactLink,
    };
  }

  factory Invite.fromMap(Map<String, dynamic> map) {
    return Invite(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      publicationDate: (map['publicationDate'] as Timestamp).toDate(),
      content: map['content'] ?? '',
      contactLink: map['contactLink'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Invite.fromJson(String source) => Invite.fromMap(json.decode(source));
}
