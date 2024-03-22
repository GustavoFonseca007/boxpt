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

class _PerfilState extends State<Perfil> {
  ChewieController? _chewieController;
  Widget? playerWidget;
  String _name = '';
  String _id = '';
  String _bio = '';
  String _videoCaption = '';
  String? _videoId;
  TextEditingController _nomeController = TextEditingController();
  String imageUrl = '';
  File? _image;
  File? _video;
  bool _isVideoLoading = false;
  bool _isVideoFormVisible = false;
  bool _isImagePickerActive = false;
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

  Future getPhoto() async {
    setState(() {
      _isImagePickerActive = true;
    });

    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      _isImagePickerActive = false;
      if (pickedFile != null) {
        _photo = File(pickedFile.path);
      } else {
        _logger.info('No photo selected');
      }
    });
  }

  void _showEditVideoCommentModal(Map<String, dynamic> comment) {
    final commentTextController = TextEditingController(text: comment['text']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar comentário'),
          content: TextFormField(
            controller: commentTextController,
            decoration: InputDecoration(labelText: 'Comentário'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final newComment = Map<String, dynamic>.from(comment);
                newComment['text'] = commentTextController.text;

                _db.collection('videos').doc(_videoId).update({
                  'comments': FieldValue.arrayRemove([comment]),
                });

                _db.collection('videos').doc(_videoId).update({
                  'comments': FieldValue.arrayUnion([newComment]),
                });

                Navigator.pop(context);
              },
              child: Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _showEditPhotoCommentModal(Map<String, dynamic> comment) {
    final commentTextController = TextEditingController(text: comment['text']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar comentário'),
          content: TextFormField(
            controller: commentTextController,
            decoration: InputDecoration(labelText: 'Comentário'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final newComment = Map<String, dynamic>.from(comment);
                newComment['text'] = commentTextController.text;

                _db.collection('photos').doc(_photoId).update({
                  'comments': FieldValue.arrayRemove([comment]),
                });

                _db.collection('photos').doc(_photoId).update({
                  'comments': FieldValue.arrayUnion([newComment]),
                });

                Navigator.pop(context);
              },
              child: Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _showPhotoCommentsModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Comentários'),
          content: Container(
            width: double.maxFinite,
            child: Column(
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: _db.collection('photos').doc(_photoId).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container();
                    }

                    final photoData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final comments = photoData['comments'] as List<dynamic>;

                    return Expanded(
                      child: ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          final text = comment['text'];
                          final userId = comment['userId'];

                          if (comment.containsKey('timestamp') &&
                              comment['timestamp'] != null) {
                            final timestamp = comment['timestamp'];
                            final date =
                                DateTime.fromMillisecondsSinceEpoch(timestamp);
                            final formattedDate =
                                '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';

                            return FutureBuilder<DocumentSnapshot>(
                              future: _db.collection('users').doc(userId).get(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return Container();
                                }

                                final userData = snapshot.data!.data()
                                    as Map<String, dynamic>;
                                final userName = userData['name'];
                                final userProfileImageUrl =
                                    userData['imageUrl'];

                                return Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                      ),
                                      margin:
                                          EdgeInsets.symmetric(vertical: 5.0),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage:
                                              NetworkImage(userProfileImageUrl),
                                        ),
                                        title: Text(text),
                                        subtitle: Text(userName),
                                        trailing: PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _showEditPhotoCommentModal(
                                                  comment);
                                            } else if (value == 'delete') {
                                              _db
                                                  .collection('photos')
                                                  .doc(_photoId)
                                                  .update({
                                                'comments':
                                                    FieldValue.arrayRemove(
                                                        [comment]),
                                              });
                                            }
                                          },
                                          itemBuilder: (BuildContext context) =>
                                              <PopupMenuEntry<String>>[
                                            const PopupMenuItem<String>(
                                              value: 'edit',
                                              child: Text('Editar'),
                                            ),
                                            const PopupMenuItem<String>(
                                              value: 'delete',
                                              child: Text('Excluir'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 16.0),
                                      child: Text(formattedDate,
                                          style: TextStyle(color: Colors.grey)),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else {
                            return Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                  margin: EdgeInsets.symmetric(vertical: 5.0),
                                  child: ListTile(
                                    title: Text(text),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
                TextFormField(
                  controller: _commentController,
                  decoration:
                      InputDecoration(labelText: 'Escreva um comentário'),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final date = DateTime.now();
                    final formattedDate =
                        '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';

                    _db.collection('photos').doc(_photoId).update({
                      'comments': FieldValue.arrayUnion([
                        {
                          'text': _commentController.text,
                          'date': formattedDate,
                          'timestamp': date.millisecondsSinceEpoch,
                          'userId': _id,
                        }
                      ]),
                    });
                    _commentController.clear();
                  },
                  child: Text('Comentar'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  void publishPhoto() async {
    // Verifique se uma foto foi selecionada
    if (_photo == null) {
      return;
    }

    final photoRef = _db.collection('photos').doc();

    await photoRef.set({
      'caption': _photoCaption,
      'likes': 0,
      'comments': [],
      'likedBy': [],
      'userId': _auth.currentUser?.uid,
    });

    setState(() {
      _isPhotoFormVisible = false;
      _photoCaption = _photoCaptionController.text;
      _photoCaptionController.clear();
      _photoId = photoRef.id;
    });
  }

  Widget _buildPublishedPhoto() {
    if (_photo == null || _photoCaption.isEmpty) {
      return Container();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('photos').doc(_photoId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Container();
        }

        final photoData = snapshot.data!.data() as Map<String, dynamic>;
        final likes = photoData['likes'] as int;
        final comments = photoData['comments'] as List<dynamic>;
        final likedBy = photoData['likedBy'] as List<dynamic>;

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_photoCaption),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        // Delete the photo
                        _db.collection('photos').doc(_photoId).delete();
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Excluir'),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              Image.file(_photo!),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.thumb_up),
                    onPressed: () {
                      if (likedBy.contains(_id)) {
                        _db.collection('photos').doc(_photoId).update({
                          'likes': likes - 1,
                          'likedBy': FieldValue.arrayRemove([_id]),
                        });
                      } else {
                        _db.collection('photos').doc(_photoId).update({
                          'likes': likes + 1,
                          'likedBy': FieldValue.arrayUnion([_id]),
                        });
                      }
                    },
                  ),
                  Text('$likes'),
                  IconButton(
                      icon: Icon(Icons.comment),
                      onPressed: _showPhotoCommentsModal),
                  Text('${comments.length}'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoForm() {
    if (!_isPhotoFormVisible) {
      return Container();
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _photoCaptionController,
              decoration: InputDecoration(
                labelText: 'Escrever uma legenda',
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isImagePickerActive ? null : getPhoto,
              child: Text('Escolher foto'),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isPhotoFormVisible = false;
                    });
                  },
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: publishPhoto,
                  child: Text('Publicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

    setState(() {
      if (mounted) {
        _id = userId ?? '';
        _name = doc['name'] ?? '';
        _bio = doc['bio'] ?? '';
        imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(imageUrl)
            : null;

        if (imageUrl.isEmpty) _image = null;
      }
    });
  }

  Future getImage(ImageSource source) async {
    final pickedFile = await picker.getImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        _logger.info('Showing video upload dialog');
      }
    });
  }

  void _showCommentsModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Comentários'),
          content: Container(
            width: double.maxFinite,
            child: Column(
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: _db.collection('videos').doc(_videoId).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container();
                    }

                    final videoData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final comments = videoData['comments'] as List<dynamic>;

                    return Expanded(
                      child: ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          final text = comment['text'];
                          final userId = comment['userId'];

                          if (comment.containsKey('timestamp') &&
                              comment['timestamp'] != null) {
                            final timestamp = comment['timestamp'];
                            final date =
                                DateTime.fromMillisecondsSinceEpoch(timestamp);
                            final formattedDate =
                                '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';

                            return FutureBuilder<DocumentSnapshot>(
                              future: _db.collection('users').doc(userId).get(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return Container();
                                }

                                final userData = snapshot.data!.data()
                                    as Map<String, dynamic>;
                                final userName = userData['name'];
                                final userProfileImageUrl =
                                    userData['imageUrl'];

                                return Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                      ),
                                      margin:
                                          EdgeInsets.symmetric(vertical: 5.0),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage:
                                              NetworkImage(userProfileImageUrl),
                                        ),
                                        title: Text(text),
                                        subtitle: Text(userName),
                                        trailing: PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _showEditVideoCommentModal(
                                                  comment);
                                            } else if (value == 'delete') {
                                              _db
                                                  .collection('videos')
                                                  .doc(_videoId)
                                                  .update({
                                                'comments':
                                                    FieldValue.arrayRemove(
                                                        [comment]),
                                              });
                                            }
                                          },
                                          itemBuilder: (BuildContext context) =>
                                              <PopupMenuEntry<String>>[
                                            const PopupMenuItem<String>(
                                              value: 'edit',
                                              child: Text('Editar'),
                                            ),
                                            const PopupMenuItem<String>(
                                              value: 'delete',
                                              child: Text('Excluir'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 16.0),
                                      child: Text(formattedDate,
                                          style: TextStyle(color: Colors.grey)),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else {
                            return Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                  margin: EdgeInsets.symmetric(vertical: 5.0),
                                  child: ListTile(
                                    title: Text(text),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
                TextFormField(
                  controller: _commentController,
                  decoration:
                      InputDecoration(labelText: 'Escreva um comentário'),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final date = DateTime.now();
                    final formattedDate =
                        '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';

                    _db.collection('videos').doc(_videoId).update({
                      'comments': FieldValue.arrayUnion([
                        {
                          'text': _commentController.text,
                          'date': formattedDate,
                          'timestamp': date.millisecondsSinceEpoch,
                          'userId': _id,
                        }
                      ]),
                    });
                    _commentController.clear();
                  },
                  child: Text('Comentar'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _videoController?.dispose();
  }

  Future getVideo() async {
    final pickedFile = await picker.getVideo(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _video = File(pickedFile.path);
      } else {
        _logger.info('No video selected');
      }
    });
  }

  void publishVideo() async {
    setState(() {
      _isVideoLoading = true;
    });

    await Future.delayed(Duration(seconds: 3));

    final videoRef = _db.collection('videos').doc();
    await videoRef.set({
      'likes': 0,
      'comments': [],
      'likedBy': [],
      'caption': _videoCaption,
    });
    setState(() {
      _videoCaption = _captionController.text;
      _isVideoFormVisible = false;
      _isVideoLoading = false;
      _videoId = videoRef.id;

      if (_video != null) {
        _videoController = VideoPlayerController.file(_video!);
        _videoController!.initialize();
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: false,
          looping: false,
        );
        playerWidget = Chewie(controller: _chewieController!);
      }
    });
  }

  Widget _buildPublishedVideo() {
    if (_video == null || _videoCaption.isEmpty || _videoController == null) {
      return Container();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('videos').doc(_videoId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }

        if (snapshot.data!.data() == null) {
          return Container();
        }

        final videoData = snapshot.data!.data() as Map<String, dynamic>;
        final likes = videoData['likes'] as int;
        final comments = videoData['comments'] as List<dynamic>;
        final likedBy = videoData['likedBy'] as List<dynamic>;

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_videoCaption),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        // Delete the video
                        _db.collection('videos').doc(_videoId).delete();
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Excluir'),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: Chewie(
                  controller: ChewieController(
                    videoPlayerController: _videoController!,
                    aspectRatio: _videoController!.value.aspectRatio,
                    autoPlay: false,
                    looping: false,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.thumb_up),
                    onPressed: () {
                      if (likedBy.contains(_id)) {
                        _db.collection('videos').doc(_videoId).update({
                          'likes': likes - 1,
                          'likedBy': FieldValue.arrayRemove([_id]),
                        });
                      } else {
                        _db.collection('videos').doc(_videoId).update({
                          'likes': likes + 1,
                          'likedBy': FieldValue.arrayUnion([_id]),
                        });
                      }
                    },
                  ),
                  Text('$likes'),
                  IconButton(
                      icon: Icon(Icons.comment), onPressed: _showCommentsModal),
                  Text('${comments.length}'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoForm() {
    if (!_isVideoFormVisible) {
      return Container();
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _captionController,
              decoration: InputDecoration(
                labelText: 'Escrever uma legenda',
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: getVideo,
              child: Text('Escolher vídeo'),
            ),
            SizedBox(height: 16),
            if (playerWidget != null) playerWidget!,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isVideoFormVisible = false;
                    });
                  },
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final User? user = _auth.currentUser;
                    final String? userId = user?.uid;

                    final CollectionReference videosRef = _db
                        .collection('users')
                        .doc(userId)
                        .collection('videos');

                    String videoUrl = '';
                    if (_video != null && _video!.existsSync()) {
                      final Reference ref = FirebaseStorage.instance
                          .ref()
                          .child(
                              'users/$userId/${_video!.path.split('/').last}');
                      final TaskSnapshot uploadTask =
                          await ref.putFile(_video!);
                      videoUrl = await uploadTask.ref.getDownloadURL();
                    }

                    await videosRef.add({
                      'caption': _captionController.text,
                      'videoUrl': videoUrl,
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    setState(() {
                      _isVideoFormVisible = false;
                      _captionController.clear();
                      _video = null;
                    });
                  },
                  child: Text('Publicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
                _buildVideoForm(),
                _buildPublishedVideo(),
                SizedBox(height: 20),
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
                _buildPhotoForm(),
                _buildPublishedPhoto(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
