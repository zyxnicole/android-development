import 'dart:async';
import 'dart:io';
import 'package:authorization_app/signin.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

class PostPage extends StatefulWidget {
  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  List<File> _imageFiles = [];
  List<String> _imageFileNames = [];
  List<String> _imageLocations = [];
  List<String> _imageLabels = [];

  File imageFile;
  String _imageLocation;
  String _title;
  double _price = 0.00;
  String _description = " ";
  final databaseReference = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _getLabels(File image, [int i]) async {
    final FirebaseVisionImage image = FirebaseVisionImage.fromFile(imageFile);
    final ImageLabeler imageLabeler = FirebaseVision.instance.imageLabeler();
    final List<ImageLabel> imgLabels = await imageLabeler.processImage(image);

    String labelText;
    for (ImageLabel cloudLabel in imgLabels) {
      final String content = cloudLabel.text;
      final double confidence = cloudLabel.confidence;
      labelText = labelText + content + " ";
    }

    if (i != null) {
      _imageLabels[i] = labelText;
    } else {
      _imageLabels.add(labelText);
    }

    imageLabeler.close();
  }

  Future<void> _showChoiceDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Make a Choice"),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  GestureDetector(
                    child: Text("Gallery"),
                    onTap: () {
                      _openGallery(context);
                    },
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  GestureDetector(
                      child: Text("Camera"),
                      onTap: () {
                        _openCamera(context);
                      })
                ],
              ),
            ),
          );
        });
  }

  void _postSave(BuildContext context) async {
    if (_title != null) {
      Navigator.of(context).pop();
      if (_imageLocations.isNotEmpty) {
        _uploadFiles().then((value) => _commitToDB());
      } else {
        _commitToDB();
      }
    } else {
      _showTitleRequirement(context);
    }
  }

  Future<void> _commitToDB() async {
    String _email = getCurrentUserEmail();

    DocumentReference documentRef =
        await databaseReference.collection("nicole-garage-0").add({
      'Date': new DateTime.now(),
      'Title': _title,
      'Price': _price,
      'Description': _description,
      'ImagePath': _imageLocations,
      'ImageFileName': _imageFileNames,
      'ImageLabel': _imageLabels,
      'ContactEmail': _email
    });

    print("Commit to Firebase DB: ref# " + documentRef.id);
  }

  Future<void> _uploadFiles() async {
    for (int i = 0; i < _imageFiles.length; i++) {
      var snapshot = await FirebaseStorage.instance
          .ref()
          .child("nicole-garage-0/${_imageFileNames[i]}")
          .putFile(_imageFiles[i])
          .whenComplete(() => print('uploaded'));
      var downloadUrl = await snapshot.ref.getDownloadURL();
      _imageLocations[i] = downloadUrl;
    }
  }

  Future<void> _showTitleRequirement(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Title Missed"),
            content: Text("Please enter a title"),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Back")),
            ],
          );
        });
  }

  _openCamera(BuildContext context, [int i]) async {
    final picker = ImagePicker();
    var pickedFile = await picker.getImage(source: ImageSource.camera);

    var imageLocation = pickedFile.path;
    var imageFile = File(imageLocation);
    var imageFileName = path.basename(imageFile.path);

    setState(() {
      if (pickedFile != null) {
        if (i != null) {
          _imageFiles[i] = imageFile;
          _imageLocations[i] = imageLocation;
          _imageFileNames[i] = imageFileName;
          _getLabels(imageFile, i);
        } else {
          _imageLocations.add(imageLocation);
          _imageFiles.add(imageFile);
          _imageFileNames.add(imageFileName);
          _getLabels(imageFile);
        }
      } else {
        print('No image selected');
      }
    });
    Navigator.of(context).pop();
  }

  _openGallery(BuildContext context, [int i]) async {
    final picker = ImagePicker();
    var pickedFile = await picker.getImage(source: ImageSource.gallery);

    var imageLocation = pickedFile.path;
    var imageFile = File(imageLocation);
    var imageFileName = path.basename(imageFile.path);

    setState(() {
      if (pickedFile != null) {
        if (i != null) {
          _imageFiles[i] = imageFile;
          _imageLocations[i] = imageLocation;
          _imageFileNames[i] = imageFileName;
          _getLabels(imageFile, i);
        } else {
          _imageLocations.add(imageLocation);
          _imageFiles.add(imageFile);
          _imageFileNames.add(imageFileName);
          _getLabels(imageFile);
        }
      } else {
        print('No image selected');
      }
    });
    Navigator.of(context).pop();
  }

  Widget _generateImageWidgets() {
    List<Widget> list = new List<Widget>();
    for (var i = 0; i < _imageFiles.length; i++) {
      list.add(
        Padding(
          padding: const EdgeInsets.only(top: 30.0, left: 5.0),
          child: GestureDetector(
            onTap: () {
              _showChoiceDialog(context);
            },
            child: Image.file(
              _imageFiles[i],
              width: 90,
            ),
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: list,
    );
  }

  Widget _onChoice() {
    if (_imageFiles.length < 4) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FloatingActionButton(
            onPressed: () {
              _showChoiceDialog(context);
            },
            child: Icon(
              Icons.add_photo_alternate_outlined,
              size: 35,
              color: Colors.white,
            ),
            backgroundColor: Colors.blueGrey,
          ),
        ],
      );
    } else {
      return Row();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("New Post"),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blueGrey,
        child: Container(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _onChoice(),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 20,
            ),
            Container(
              padding: const EdgeInsets.only(
                  top: 20.0, bottom: 8.0, left: 32, right: 32),
              child: TextField(
                decoration: InputDecoration(hintText: 'Item name'),
                onChanged: (text) {
                  _title = text;
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.only(
                  top: 8.0, bottom: 8.0, left: 32, right: 32),
              child: TextField(
                decoration: InputDecoration(hintText: '\u0024 0.00'),
                inputFormatters: [
                  CurrencyTextInputFormatter(symbol: '\u0024 ')
                ],
                keyboardType: TextInputType.number,
                onChanged: (input) {
                  if (input.isEmpty) {
                    _price = 0.00;
                  } else {
                    _price =
                        double.tryParse(input.substring(2).replaceAll(',', ''));
                  }
                },
              ),
            ),
            Container(
              height: 200,
              padding: const EdgeInsets.only(
                  top: 8.0, bottom: 8.0, left: 32, right: 32),
              child: TextField(
                keyboardType: TextInputType.multiline,
                maxLines: 6,
                decoration: InputDecoration(
                    hintText: 'Item description...',
                    fillColor: Colors.grey[100],
                    filled: true),
                onChanged: (text) {
                  _description = text;
                },
              ),
            ),
            _generateImageWidgets(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _postSave(context);
          },
          label: Text('POST'),
          tooltip: 'Post For Sale',
          icon: Icon(Icons.share),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16.0)))),
    );
  }
}
