import 'dart:async';
import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'image_detail_page.dart';

class DetailPage extends StatefulWidget {
  final DocumentSnapshot document;

  const DetailPage({
    Key key,
    this.document,
  }) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  @override
  void initState() {
    super.initState();
  }

  File imageFile;
  final TextStyle _style = TextStyle(color: Colors.black, fontSize: 40);
  final TextStyle _stylePrice = TextStyle(color: Colors.red[900], fontSize: 20);
  final TextStyle _styleDesc = TextStyle(
    fontSize: 18,
  );

  Widget _generateImageWidgets() {
    List<Widget> list = new List<Widget>();

    if (widget.document["ImagePath"] != null) {
      for (var i = 0; i < widget.document["ImagePath"].length; i++) {
        list.add(Padding(
          padding: const EdgeInsets.all(1.0),
          child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ImageViewPage(
                            imageLocation: widget.document["ImagePath"][i],
                          )),
                );
              },
              child: CachedNetworkImage(
                imageUrl: widget.document["ImagePath"][i],
                imageBuilder: (context, imageProvider) => Image(
                  image: imageProvider,
                  height: 120,
                ),
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Image(
                  image: AssetImage("assets/no-image-available.jpeg"),
                  height: 100,
                ),
              )),
        ));
      }
    }

    if (widget.document["ImagePath"] == null ||
        widget.document["ImagePath"].length < 1) {
      list.add(Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 20.0),
        child: new GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ImageViewPage(
                        imageLocation: "assets/no-image-available.jpeg",
                      )),
            );
          },
          child: Image(
            image: AssetImage("assets/no-image-available.jpeg"),
            height: 100,
          ),
        ),
      ));
    }

    return new Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: list);
  }

  Widget container() {
    Container(
        child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 4.0, mainAxisSpacing: 4.0),
            itemBuilder: (BuildContext context, int index) {
              return Image.network(widget.document["ImagePath"][index]);
            }));
  }

  Widget _titleWidget() {
    String title = "Untitled...";
    if (widget.document.data().containsKey("Title")) {
      title = widget.document["Title"];
    }
    return Center(
      child: Container(
          padding: const EdgeInsets.only(
              top: 20.0, bottom: 8.0, left: 32, right: 32),
          child: Text(
            title,
            style: _style,
          )),
    );
  }

  Widget _priceWidget() {
    String price = "\$" + widget.document["Price"].toString();
    return Center(
      child: Container(
          padding: const EdgeInsets.only(
              top: 10.0, bottom: 8.0, left: 32, right: 32),
          child: Text(
            price,
            style: _stylePrice,
          )),
    );
  }

  Widget _descriptionWidget() {
    String desc = "No description...";
    if (widget.document.data().containsKey("Description")) {
      desc = widget.document["Description"];
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          padding:
              const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 32, right: 32),
          child: AutoSizeText(
            "$desc",
            style: _styleDesc,
            textAlign: TextAlign.left,
            minFontSize: 15,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ))
    ]);
  }

  Widget _posterWidget() {
    String email = "No attribution...";
    if (widget.document.data().containsKey("ContactEmail")) {
      email = widget.document["ContactEmail"];
    }
    return Center(
      child: Container(
          padding: const EdgeInsets.only(
              top: 18.0, bottom: 8.0, left: 32, right: 32),
          child: RichText(
              text: TextSpan(
                  text: "",
                  style: TextStyle(color: Colors.black),
                  children: <TextSpan>[
                TextSpan(
                    text: "Contact: ",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                    text: email,
                    style: TextStyle(fontWeight: FontWeight.normal))
              ]))),
    );
  }

  Widget _dateWidget() {
    if (widget.document.data().containsKey("Date")) {
      return Center(
          child: Container(
        padding:
            const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 32, right: 32),
        child: Text(_time(widget.document["Date"])),
      ));
    } else {
      return Container();
    }
  }

  _time(Timestamp time) {
    return timeago.format(time.toDate(), locale: 'en');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Review Post"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _generateImageWidgets(),
            _titleWidget(),
            _priceWidget(),
            _descriptionWidget(),
            _posterWidget(),
            _dateWidget(),
          ],
        ),
      ),
    );
  }
}
