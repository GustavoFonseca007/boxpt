import 'dart:io';
import 'dart:async';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:eco/vermais.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:http/http.dart' as http;

final _logger = Logger('Perfil');

class Perfil extends StatefulWidget {
  @override
  _PerfilState createState() => _PerfilState();
}

final List locale = [
  {'name': 'PORTUGUESE', 'locale': Locale('pt', 'BR')},
  {'name': 'ITALIAN', 'locale': Locale('it', 'IT')},
  {'name': 'SPANISH', 'locale': Locale('es', 'ES')},
  {'name': 'ENGLISH', 'locale': Locale('en', 'EN')},
];
updatelanguage(Locale locale) {
  Get.updateLocale(locale);
}

class EditCommentForm extends StatefulWidget {
  final CollectionReference commentsRef;
  final DocumentSnapshot comment;
  final void Function() onCommentEdited;

  const EditCommentForm({
    Key? key,
    required this.commentsRef,
    required this.comment,
    required this.onCommentEdited,
  }) : super(key: key);

  @override
  _EditCommentFormState createState() => _EditCommentFormState();
}

class _EditCommentFormState extends State<EditCommentForm> {
  final TextEditingController _editingCommentController =
      TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _editingCommentController.text = widget.comment['text'];

    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _editingCommentController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: 'Edit Comment',
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            await widget.commentsRef.doc(widget.comment.id).update({
              'text': _editingCommentController.text,
            });

            setState(() {
              _editingCommentController.clear();
            });

            widget.onCommentEdited();
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}

class _PerfilState extends State<Perfil> {
  List<Map<String, dynamic>> _photos = [];

  String _name = '';
  String _id = '';
  String _bio = '';
  String? _videoId;
  String? _editingCommentId;
  final TextEditingController _editingCommentController =
      TextEditingController();

  TextEditingController _nomeController = TextEditingController();
  String imageUrl = '';
  File? _image;
  File? _video;
  bool _isVideoFormVisible = false;
  bool _isImagePickerActive = false;
  bool _isCommentsSectionVisible = false;
  VideoPlayerController? _videoController;
  File? _photo;
  String? _photoId;
  bool _isPhotoFormVisible = false;
  String _photoCaption = '';
  final TextEditingController _photoCaptionController = TextEditingController();
  final picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _commentController = TextEditingController();

  List<String> _captions = [];
  List<Map<String, dynamic>> _videos = [];

  void _toggleLike(String videoId) async {
    final FirebaseFirestore _db = FirebaseFirestore.instance;
    final CollectionReference usersRef = _db.collection('users');

    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;
    final String? userId = user?.uid;
    final CollectionReference videosRef =
        usersRef.doc(userId).collection('videos');

    final CollectionReference likesRef =
        videosRef.doc(videoId).collection('likes');

    final DocumentSnapshot likeDoc = await likesRef.doc(userId).get();
    if (likeDoc.exists) {
      await likesRef.doc(userId).delete();
      await videosRef.doc(videoId).update({'likes': FieldValue.increment(-1)});
    } else {
      await likesRef.doc(userId).set(<String, dynamic>{});

      await videosRef.doc(videoId).update({'likes': FieldValue.increment(1)});
    }

    await _getVideos();

    setState(() {
      final video = _videos.firstWhere((v) => v['id'] == videoId);
      video['likedByUser'] = !video['likedByUser'];
    });
  }

  void _publishVideo() async {
    if (_video != null) {
      final FirebaseFirestore _db = FirebaseFirestore.instance;
      final CollectionReference usersRef = _db.collection('users');

      final FirebaseAuth _auth = FirebaseAuth.instance;
      final User? user = _auth.currentUser;
      final String? userId = user?.uid;
      final CollectionReference videosRef =
          usersRef.doc(userId).collection('videos');

      final Reference ref = FirebaseStorage.instance
          .ref()
          .child('users/$userId/videos/${_video!.path.split('/').last}');

      final TaskSnapshot uploadTask = await ref.putFile(_video!);
      final String videoUrl = await uploadTask.ref.getDownloadURL();

      final post = {
        'caption': _captionController.text,
        'videoUrl': videoUrl,
      };
      await videosRef.add(post);

      setState(() {
        _video = null;
        _captionController.clear();
        _isVideoFormVisible = false;
      });

      await _getVideos();
    }
  }

  void _publishPhoto() async {
    if (_photo != null) {
      final FirebaseFirestore _db = FirebaseFirestore.instance;
      final CollectionReference usersRef = _db.collection('users');

      final FirebaseAuth _auth = FirebaseAuth.instance;
      final User? user = _auth.currentUser;
      final String? userId = user?.uid;
      final CollectionReference photosRef =
          usersRef.doc(userId).collection('photos');

      final Reference ref = FirebaseStorage.instance
          .ref()
          .child('users/$userId/photos/${_photo!.path.split('/').last}');

      final TaskSnapshot uploadTask = await ref.putFile(_photo!);
      final String photoUrl = await uploadTask.ref.getDownloadURL();

      final post = {
        'caption': _photoCaptionController.text,
        'photoUrl': photoUrl,
      };
      await photosRef.add(post);

      setState(() {
        _photo = null;
        _photoCaptionController.clear();
        _isPhotoFormVisible = false;
      });

      await _getPhotos();
    }
  }

  Future<void> _getPhotos() async {
    final FirebaseFirestore _db = FirebaseFirestore.instance;
    final CollectionReference usersRef = _db.collection('users');

    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;
    final String? userId = user?.uid;
    final CollectionReference photosRef =
        usersRef.doc(userId).collection('photos');

    final QuerySnapshot snapshot = await photosRef.get();

    setState(() {
      _photos = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> updateUserProfile() async {
    final User? user = _auth.currentUser;
    final String? userId = user?.uid;

    final DocumentReference userRef = _db.collection('users').doc(userId);

    if (_image != null && _image!.existsSync()) {
      final Reference ref =
          FirebaseStorage.instance.ref().child('users/$userId/profile.jpg');
      final TaskSnapshot uploadTask = await ref.putFile(_image!);
      imageUrl = await uploadTask.ref.getDownloadURL();
    }

    await userRef.set({
      'name': _name,
      'bio': _bio,
      'imageUrl': imageUrl,
    });

    setState(() {
      _id = userId ?? '';
    });
  }

  Future getPhoto(ImageSource source) async {
    final pickedFile = await picker.getImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _photo = File(pickedFile.path);
      });
    }
  }

  Future<void> getUserProfile() async {
    final User? user = _auth.currentUser;
    final String? userId = user?.uid;

    final DocumentSnapshot doc =
        await _db.collection('users').doc(userId).get();

    String imageUrl = '';

    if (doc.exists && doc.data() != null && doc.data() is Map) {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('imageUrl')) {
        final imageUrlFromDoc = data['imageUrl'];
        if (imageUrlFromDoc is String) {
          imageUrl = imageUrlFromDoc;
        }
      }
    }

    if (imageUrl.isNotEmpty) {
      final http.Response downloadData = await http.get(Uri.parse(imageUrl));
      final Directory systemTempDir = Directory.systemTemp;
      final File tempFile = File('${systemTempDir.path}/tmp.jpg');
      if (tempFile.existsSync()) {
        await tempFile.delete();
      }
      await tempFile.create();
      await tempFile.writeAsBytes(downloadData.bodyBytes);
      _image = tempFile;
    }

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;

      setState(() {
        if (mounted) {
          _id = userId ?? '';

          _name = data.containsKey('name') ? data['name'] : '';
          _bio = data.containsKey('bio') ? data['bio'] : '';

          if (data.containsKey('imageUrl') && data['imageUrl'].isNotEmpty) {
            _image = Image.network(data['imageUrl']) as File?;
          } else {
            _image = null;
          }
        }
      });
    } else {}
  }

  Future getImage(ImageSource source) async {
    final pickedFile = await picker.getImage(source: source);
  }

  Future<void> _getVideos() async {
    final FirebaseFirestore _db = FirebaseFirestore.instance;
    final CollectionReference usersRef = _db.collection('users');

    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;
    final String? userId = user?.uid;
    final CollectionReference videosRef =
        usersRef.doc(userId).collection('videos');

    final QuerySnapshot snapshot = await videosRef.get();

    setState(() {
      _videos = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['likes'] = data['likes'] ?? 0;
        return data;
      }).toList();
    });
  }

  Future getVideo(ImageSource source) async {
    final pickedFile = await picker.getVideo(source: source);
    if (pickedFile != null) {
      setState(() {
        _video = File(pickedFile.path);
      });
    }
  }

  void _openEditProfileModal() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<dynamic>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height *
              0.8, // Definir a altura como 80% da altura da tela
          padding: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20),
                Text(
                  'Editar Perfil'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _nomeController,
                  onChanged: (value) {
                    setState(() {
                      _name = value;
                    });
                  },
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nome'.tr,
                    hintText: _name,
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  initialValue: _bio,
                  onChanged: (value) {
                    setState(() {
                      _bio = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Biografia'.tr,
                    hintText: 'Escreva uma breve biografia...'.tr,
                    contentPadding: EdgeInsets.symmetric(vertical: -5),
                  ),
                  maxLines: 5,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.camera_alt),
                      onPressed: () => getImage(ImageSource.camera),
                    ),
                    IconButton(
                      icon: Icon(Icons.photo_library),
                      onPressed: () => getImage(ImageSource.gallery),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _image = null;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await updateUserProfile();
                    if (context != null) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Salvar'.tr),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: isDarkMode ? Colors.black : Colors.white,
                    backgroundColor: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    getUserProfile();
    _getVideos();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_name),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage:
                          _image != null ? FileImage(_image!) : null,
                      radius: 50,
                    ),
                    SizedBox(width: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events_outlined, color: Colors.amber),
                        SizedBox(width: 10),
                        Text(
                          '0',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  _bio,
                  textAlign: TextAlign.start,
                ),
                SizedBox(height: 50),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _openEditProfileModal,
                      child: Text('Editar perfil'.tr),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () async {
                        // Get the ID of the current user
                        final User? user = _auth.currentUser;
                        final String? userId = user?.uid;

                        final DocumentSnapshot doc =
                            await _db.collection('users').doc(userId).get();

                        final message =
                            'Nome: ${doc['name']}\nBiografia: ${doc['bio']}';

                        await FlutterShare.share(
                          title: 'Compartilhar Perfil'.tr,
                          text: message,
                          chooserTitle: 'Compartilhar com'.tr,
                        );
                      },
                      child: Text('Compartilhar Perfil'.tr),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Conquistas'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => VerMais()),
                        );
                      },
                      child: Text(
                        'Ver mais'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Vídeos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline),
                      onPressed: () {
                        setState(() {
                          _isVideoFormVisible = true;
                        });
                      },
                    ),
                  ],
                ),
                Column(
                  children: List.generate(_videos.length, (index) {
                    final video = _videos[index];
                    final videoId = video['id'];

                    return FutureBuilder(
                      future: () async {
                        final controller =
                            VideoPlayerController.network(video['videoUrl']);
                        await controller.initialize();
                        final width = controller.value.size.width;
                        final height = controller.value.size.height;
                        final aspectRatio = width / height;
                        return ChewieController(
                          videoPlayerController: controller,
                          aspectRatio: aspectRatio,
                          autoPlay: false,
                          looping: false,
                        );
                      }(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final chewieController =
                              snapshot.data as ChewieController;
                          return Container(
                            margin: EdgeInsets.only(bottom: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Text(video['caption']),
                                  ),
                                  Chewie(controller: chewieController),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.favorite,
                                            color:
                                                (video['likedByUser'] ?? false)
                                                    ? Colors.red
                                                    : Colors.grey),
                                        onPressed: () =>
                                            _toggleLike(video['id']),
                                      ),
                                      Text('${video['likes'] ?? 0}'),
                                      IconButton(
                                        icon: Icon(Icons.comment),
                                        onPressed: () {
                                          final FirebaseFirestore _db =
                                              FirebaseFirestore.instance;
                                          final CollectionReference usersRef =
                                              _db.collection('users');

                                          final FirebaseAuth _auth =
                                              FirebaseAuth.instance;
                                          final User? user = _auth.currentUser;
                                          final String? userId = user?.uid;
                                          final CollectionReference videosRef =
                                              usersRef
                                                  .doc(userId)
                                                  .collection('videos');

                                          showModalBottomSheet(
                                            context: context,
                                            builder: (BuildContext context) {
                                              final CollectionReference
                                                  commentsRef = videosRef
                                                      .doc(videoId)
                                                      .collection('comments');
                                              return StatefulBuilder(
                                                builder: (BuildContext context,
                                                    StateSetter setState) {
                                                  return StreamBuilder<
                                                      QuerySnapshot>(
                                                    stream:
                                                        commentsRef.snapshots(),
                                                    builder:
                                                        (context, snapshot) {
                                                      if (snapshot.hasData) {
                                                        final comments =
                                                            snapshot.data!.docs;
                                                        return Padding(
                                                          padding: EdgeInsets.only(
                                                              bottom: MediaQuery
                                                                      .of(context)
                                                                  .viewInsets
                                                                  .bottom),
                                                          child: Container(
                                                            child: Column(
                                                              children: [
                                                                Expanded(
                                                                  child: ListView
                                                                      .builder(
                                                                    itemCount:
                                                                        comments
                                                                            .length,
                                                                    itemBuilder:
                                                                        (context,
                                                                            index) {
                                                                      final comment =
                                                                          comments[
                                                                              index];
                                                                      final userId =
                                                                          comment[
                                                                              'userId'];

                                                                      return FutureBuilder<
                                                                          DocumentSnapshot>(
                                                                        future: _db
                                                                            .collection('users')
                                                                            .doc(userId)
                                                                            .get(),
                                                                        builder:
                                                                            (context,
                                                                                snapshot) {
                                                                          if (snapshot
                                                                              .hasData) {
                                                                            final userDoc =
                                                                                snapshot.data!;
                                                                            final userName =
                                                                                userDoc['name'];
                                                                            final imageUrl =
                                                                                userDoc['imageUrl'];

                                                                            final timestamp =
                                                                                comment['timestamp'];
                                                                            if (timestamp !=
                                                                                null) {
                                                                              final date = timestamp.toDate();
                                                                              final dateStr = date.toString();

                                                                              return ListTile(
                                                                                leading: CircleAvatar(
                                                                                  backgroundImage: NetworkImage(imageUrl),
                                                                                ),
                                                                                title: Text(comment['text']),
                                                                                subtitle: Text('$userName - $dateStr'),
                                                                                trailing: PopupMenuButton<String>(
                                                                                  onSelected: (String value) {
                                                                                    if (value == 'edit') {
                                                                                      setState(() {
                                                                                        _editingCommentId = comment.id;
                                                                                      });
                                                                                    } else if (value == 'delete') {
                                                                                      commentsRef.doc(comment.id).delete();
                                                                                    }
                                                                                  },
                                                                                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                                                                    const PopupMenuItem<String>(
                                                                                      value: 'edit',
                                                                                      child: Text('Edit'),
                                                                                    ),
                                                                                    const PopupMenuItem<String>(
                                                                                      value: 'delete',
                                                                                      child: Text('Delete'),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              );
                                                                            } else {
                                                                              return SizedBox();
                                                                            }
                                                                          } else {
                                                                            return SizedBox();
                                                                          }
                                                                        },
                                                                      );
                                                                    },
                                                                  ),
                                                                ),
                                                                if (_editingCommentId !=
                                                                    null)
                                                                  EditCommentForm(
                                                                    commentsRef:
                                                                        commentsRef,
                                                                    comment: comments
                                                                        .firstWhere((c) =>
                                                                            c.id ==
                                                                            _editingCommentId),
                                                                    onCommentEdited:
                                                                        () {
                                                                      setState(
                                                                          () {
                                                                        _editingCommentId =
                                                                            null;
                                                                      });
                                                                    },
                                                                  ),
                                                                TextField(
                                                                  controller:
                                                                      _commentController,
                                                                  decoration: InputDecoration(
                                                                      labelText:
                                                                          'Comentário'),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed:
                                                                      () async {
                                                                    final commentText =
                                                                        _commentController
                                                                            .text;

                                                                    await commentsRef
                                                                        .add({
                                                                      'text':
                                                                          commentText,
                                                                      'userId':
                                                                          userId,
                                                                      'timestamp':
                                                                          FieldValue
                                                                              .serverTimestamp(),
                                                                    });

                                                                    _commentController
                                                                        .clear();
                                                                    Navigator.pop(
                                                                        context);
                                                                  },
                                                                  child: Text(
                                                                      'Enviar'),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      } else {
                                                        return Center(
                                                            child:
                                                                CircularProgressIndicator());
                                                      }
                                                    },
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          return CircularProgressIndicator();
                        }
                      },
                    );
                  }),
                ),
                SizedBox(height: 20),
                Visibility(
                  visible: _isVideoFormVisible,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _captionController,
                          decoration: InputDecoration(
                            labelText: 'Legenda',
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => getVideo(ImageSource.gallery),
                          child: Text('Escolher Vídeo'),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _isVideoFormVisible = false;
                                });
                              },
                              child: Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: _publishVideo,
                              child: Text('Publicar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Visibility(
                  visible: _isPhotoFormVisible,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _photoCaptionController,
                          decoration: InputDecoration(
                            labelText: 'Legenda',
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => getPhoto(ImageSource.gallery),
                          child: Text('Escolher Foto'),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _isPhotoFormVisible = false;
                                });
                              },
                              child: Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: _publishPhoto,
                              child: Text('Publicar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Fotos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline),
                      onPressed: () {
                        setState(() {
                          _isPhotoFormVisible = true;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
