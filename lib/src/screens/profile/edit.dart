import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:unilink/src/screens/start.dart';
import 'package:unilink/src/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'image_picker.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PaginaDeRegistoState createState() => _PaginaDeRegistoState();
}

class _PaginaDeRegistoState extends State<EditProfilePage> {
  final TextEditingController _numeController = TextEditingController();
  final TextEditingController _nrElevController = TextEditingController();

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final userData = await userRef.get();
    return userData;
  }

  String? pickedImageUrl;

  void _selectImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      Reference ref = FirebaseStorage.instance
          .ref()
          .child('ProfileImages/${FirebaseAuth.instance.currentUser?.uid}');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;

      String imageUrl = await taskSnapshot.ref.getDownloadURL();

      setState(() {
        pickedImageUrl = imageUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Eroare la colecatrea datelor'));
          } else {
            final userData = snapshot.data!;
            final name = userData.get('name');
            final number = userData.get('number');
            final photo = userData.get('photo');

            Future<String?> getImageUrl(String imagePath) async {
              final ref = FirebaseStorage.instance
                  .ref()
                  .child('ProfileImages/$imagePath');
              final url = await ref.getDownloadURL();
              return url;
            }

            return FutureBuilder<String?>(
                future: getImageUrl(photo),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(
                        child: Text('Eroare la obtinerea adresei imaginii'));
                  } else {
                    final imageUrl = snapshot.data;

                    return Scaffold(
                        resizeToAvoidBottomInset: false,
                        extendBodyBehindAppBar: true,
                        appBar: AppBar(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          leading: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: const Padding(
                                padding: EdgeInsets.only(left: 20),
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white,
                                )),
                          ),
                        ),
                        backgroundColor: Colors.black,
                        body: Center(
                            child: SingleChildScrollView(
                                child: Column(children: [
                          const SizedBox(height: 40),
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 100,
                                backgroundImage: pickedImageUrl != null
                                    ? NetworkImage(pickedImageUrl!)
                                    : NetworkImage(imageUrl!),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: FloatingActionButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return ImagePickerDialog(
                                          onImageSourceSelected: (source) {
                                            _selectImage(source);
                                          },
                                        );
                                      },
                                    );
                                  },
                                  child: const Icon(
                                    Icons.edit,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 50),
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 30),
                              child: Column(
                                children: [
                                  AuthenticationTextField(
                                    controller: _numeController,
                                    hintText: name,
                                  ),
                                  AuthenticationTextField(
                                    controller: _nrElevController,
                                    hintText: number,
                                  ),
                                  const SizedBox(height: 40),
                                  AuthenticationBtn(
                                    text: 'Schimbă numele',
                                    backgroundColor:
                                        Color.fromARGB(255, 146, 74, 187),
                                    foregroundColor: Colors.white,
                                    function: () {
                                      User? user =
                                          FirebaseAuth.instance.currentUser;
                                      if (user != null) {
                                        FirebaseAuth.instance
                                            .sendPasswordResetEmail(
                                                email: user.email!)
                                            .then((_) {})
                                            .catchError((error) {});
                                      }
                                    },
                                  ),
                                  AuthenticationBtn(
                                      text: 'Salveaza modificari',
                                      backgroundColor:
                                          Color.fromARGB(255, 146, 74, 187),
                                      foregroundColor: Colors.white,
                                      function: () {
                                        if (_numeController.text == '' &&
                                            _nrElevController.text == '') {
                                          showDialog(
                                            context: context,
                                            builder: (context) =>
                                                const AlertDialog(
                                                    title: Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                top: 10),
                                                        child: Icon(
                                                          Icons.warning,
                                                          size: 50,
                                                          color: Color.fromARGB(
                                                              255,
                                                              146,
                                                              74,
                                                              187),
                                                        )),
                                                    content: Text(
                                                        '\nCompletați câmpurile necesare!\n\n')),
                                          );
                                        } else if (_numeController.text.length >
                                            15) {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                                title: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 10),
                                                    child: Icon(
                                                      Icons.warning,
                                                      size: 50,
                                                      color: Color(int.parse(
                                                              "#8c52ff"
                                                                  .substring(
                                                                      1, 7),
                                                              radix: 16) +
                                                          0xFF000000),
                                                    )),
                                                content: const Text(
                                                    '\nNume max 15 length!\n\n')),
                                          );
                                        } else {
                                          User? user =
                                              FirebaseAuth.instance.currentUser;
                                          if (user != null) {
                                            FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(user.uid)
                                                .update({
                                              'name': _numeController.text,
                                              'number': _nrElevController.text,
                                              'photo': FirebaseAuth
                                                  .instance.currentUser?.uid,
                                            }).then((_) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const Start()),
                                              );
                                            }).catchError((error) {});
                                          }
                                        }
                                      }),
                                ],
                              ))
                        ]))));
                  }
                });
          }
        });
  }
}
