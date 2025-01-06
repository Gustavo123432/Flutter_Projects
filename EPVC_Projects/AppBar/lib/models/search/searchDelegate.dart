import 'package:flutter/material.dart';
import 'package:my_flutter_project/models/listUsers.dart';
import 'package:my_flutter_project/models/search/postList.dart';


class PostSearchDelegate extends SearchDelegate {
  PostSearchDelegate({required this.users});

  final List<UsersModel> users;
  List<UsersModel> results = <UsersModel>[];

@override
List<Widget>? buildActions(BuildContext context) => [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query.isEmpty ? close(context, null) : query = '',
      ),
    ];

@override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.of(context).pop(),
        // Exit from the search screen.
    );
  }
 @override
Widget buildResults(BuildContext context) => results.isEmpty
    ? const Center(
        child: Text('No Results', style: TextStyle(fontSize: 24)),
      )
    : PostList(posts: results);

@override
Widget buildSuggestions(BuildContext context) {
  
  results = users.where((UsersModel jogos) {
    final String title = jogos.nome.toLowerCase();
    final String input = query.toLowerCase();

    return title.contains(input);
  }).toList();

  return results.isEmpty
      ? const Center(
          child: Text('No Results', style: TextStyle(fontSize: 24)),
        )
      : PostList(posts: results);
}
}