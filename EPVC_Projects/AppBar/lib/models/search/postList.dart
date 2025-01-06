import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:my_flutter_project/models/listUsers.dart';


class PostList extends StatelessWidget {
  PostList({
    required this.posts,
    super.key,
  });

  final List<UsersModel> posts;

  @override
  Widget build(BuildContext context) {
    return  ListView.builder(
            itemCount: posts.length,
            itemBuilder: (BuildContext context, int index) {
              return Card(
                  child: InkWell(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(children: [
                        /*Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              posts[index].imageUrl.length <= 38
                                  ? Align(
                                      alignment: Alignment.center,
                                      child: Image.asset(
                                        "./lib/assets/images/no-image.png",
                                        height: 50,
                                        width: 50,
                                      ))
                                  : posts[index].imageUrl == ""
                                      ? Align(
                                          alignment: Alignment.center,
                                          child: Image.asset(
                                            "./lib/assets/images/no-image.png",
                                            height: 50,
                                            width: 50,
                                          ))
                                      : Align(
                                          alignment: Alignment.center,
                                          child: Image.network(
                                              posts[index].imageUrl,
                                              height: 50,
                                              width: 50, frameBuilder: (context,
                                                  child,
                                                  frame,
                                                  wasSynchronouslyLoaded) {
                                            return child;
                                          }, loadingBuilder: (context, child,
                                                  loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            } else {
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            }
                                          })),
                            ]),*/
                        SizedBox(
                          width: 20,
                        ),
                        Column(children: [
                          SizedBox(
                            width: 280,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: AutoSizeText(
                                posts[index].nome.toString(),
                                //troca.toString(),
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Color.fromARGB(255, 38, 61, 93),
                                    fontWeight: FontWeight.bold),
                                maxLines: 2,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          /*SizedBox(
                            width: 285,
                            child: AutoSizeText(
                              posts[index].description.toString(),
                              style: TextStyle(
                                  color: Colors.black54, fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              softWrap: true,
                            ),
                          )*/
                        ])
                      ])
                    ],
                  ),
                )
                /*onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SkillsDescriptions(
                      title: posts[index].name,
                      description: posts[index].description,
                      id: posts[index].uuid,
                      image: posts[index].imageUrl,
                      pdf: posts[index].technicalDocumentUrl,
                    ),
                  ),
                ),*/
              ));
            });
  }
}
