import 'package:authorization_app/detail_page.dart';
import 'package:authorization_app/login_page.dart';
import 'package:authorization_app/post_page.dart';
import 'package:authorization_app/signin.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class BrowsePostsActivity extends StatefulWidget {
  @override
  _BrowsePostsActivityState createState() => _BrowsePostsActivityState();
}

class _BrowsePostsActivityState extends State<BrowsePostsActivity> {
  final TextStyle _titleStyle = TextStyle(color: Colors.black54, fontSize: 20);
  final TextStyle _descStyle = TextStyle(color: Colors.grey, fontSize: 14);
  final TextStyle _timeStyle =
      TextStyle(color: Colors.blueAccent[100], fontSize: 12);

  int numOfPosts = 0;
  bool initialLoad = false;

  Future<void> _showSignOutDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Do you want to sign out?'),
            actions: <Widget>[
              MaterialButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("No"),
              ),
              MaterialButton(
                onPressed: () {
                  signOutGoogle();
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => LoginPage()),
                      ModalRoute.withName('/'));
                },
                child: Text("Yes"),
              ),
            ],
          );
        });
  }

  void initState() {
    super.initState();
  }

  Widget _titleWidget(DocumentSnapshot document) {
    String title = "Untitled...";
    if (document.data().containsKey("Title")) {
      title = document["Title"].length < 15
          ? document["Title"]
          : (document["Title"].substring(0, 13) + "...");
    }
    return Center(
      child: Container(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: _titleStyle)),
    );
  }

  Widget _descriptionWidget(DocumentSnapshot document) {
    String title = "No description...";
    if (document.data().containsKey("Description")) {
      title = document["Description"].length < 25
          ? document["Description"]
          : (document["Description"].substring(0, 22) + "...");
    }
    return Center(
      child: Container(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: _descStyle)),
    );
  }

  Future<void> _deletePost(DocumentSnapshot document) async {
    await FirebaseFirestore.instance
        .runTransaction((Transaction myTransaction) async {
      await myTransaction.delete(document.reference);
    });

    String _title = document["Title"];
    if (document.data().containsKey("ImageFilename") &&
        document["ImageFilename"].length > 0) {
      for (int i = 0; i < document["ImagePath"].length; i++) {
        String _imageName = document["ImageFilename"][i];

        final firebase_storage.Reference firebaseStorageRef = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('images/$_title/$_imageName');
        await firebaseStorageRef.delete();
      }
    }
  }

  Future<void> _showDeleteDialog(
      BuildContext context, DocumentSnapshot document) {
    String _title = document["Title"];
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Delete post?"),
            content: Text("$_title"),
            actions: <Widget>[
              FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("No")),
              FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deletePost(document);
                  },
                  child: Text("Yes")),
            ],
          );
        });
  }

  void _showSnack(BuildContext context) {
    final snackBar = SnackBar(
      content: Text('You have a new post!'),
    );
    Scaffold.of(context).showSnackBar(snackBar);
  }

  _ago(Timestamp time) {
    return timeago.format(time.toDate(), locale: 'en_short');
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DetailPage(
                    document: document,
                  )),
        );
      },
      child: Padding(
        padding:
            const EdgeInsets.only(top: 2.0, bottom: 2.0, left: 8, right: 8),
        child: Container(
          height: 100,
          child: Card(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                document["ImagePath"] != null &&
                        document["ImagePath"].length > 0
                    ? Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: CachedNetworkImage(
                          imageUrl: document["ImagePath"][0],
                          imageBuilder: (context, imageProvider) => Image(
                            image: imageProvider,
                            width: 40,
                          ),
                          placeholder: (context, url) =>
                              CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Image(
                            image: AssetImage("assets/no-image-available.jpeg"),
                            width: 40,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image(
                          image: AssetImage("assets/no-image-available.jpeg"),
                          width: 40,
                        ),
                      ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _titleWidget(document),
                    _descriptionWidget(document),
                  ],
                ),
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        document["Price"] != null
                            ? document["Price"] is double
                                ? Text(
                                    "\$" + document["Price"].toStringAsFixed(0))
                                : Text("\$" + document["Price"].toString())
                            : Text(""),
                        document.data().containsKey("Date")
                            ? Text(
                                _ago(document["Date"]),
                                style: _timeStyle,
                              )
                            : Container(),
                        GestureDetector(
                          onTap: () {
                            _showDeleteDialog(context, document);
                          },
                          child: Icon(
                            Icons.clear,
                            color: Colors.red[900],
                          ),
                        )
                      ]),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        title: Text("Garage Sale"),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
                left: 8.0, top: 8.0, right: 15.0, bottom: 8.0),
            child: GestureDetector(
              onTap: () {
                _showSignOutDialog(context);
              },
              child: Logout(),
            ),
          ),
        ],
      ),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection("nicole-garage-0")
              .orderBy('Date', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return CircularProgressIndicator();
            if (snapshot.requireData.docs.length > numOfPosts && initialLoad) {
              Future.delayed(const Duration(milliseconds: 100), () {
                _showSnack(context);
              });
              numOfPosts = snapshot.data.docs.length;
            } else {
              numOfPosts = snapshot.data.docs.length;
              initialLoad = true;
            }
            return ListView.builder(
              itemCount: snapshot.data.docs.length,
              itemBuilder: (context, index) =>
                  _buildListItem(context, snapshot.data.docs[index]),
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PostPage()),
          );
        },
        tooltip: "New Post",
        child: Icon(Icons.add),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(30.0))),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class Logout extends StatelessWidget {
  const Logout({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String _imageUrl = getCurrentUserImageUrl();

    return Tooltip(
      message: 'Logout',
      child: CircleAvatar(
        backgroundImage: new NetworkImage(_imageUrl),
        radius: 20,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
