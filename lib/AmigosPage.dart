import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eco/chatscreen.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  int _friendRequestCount = 0;
  TextEditingController _searchController = TextEditingController();
  TextEditingController _searchFriendsController = TextEditingController();
  String _searchText = "";
  String _searchFriendsText = "";

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _showNotifications = false;
  ImageProvider<Object>? _getUserImage(DocumentSnapshot user) {
    if (user.exists && user.data() != null) {
      dynamic userData = user.data();
      if (userData.containsKey('imageUrl') &&
          userData['imageUrl'] != null &&
          userData['imageUrl'].isNotEmpty) {
        return NetworkImage(userData['imageUrl']);
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _listenForFriendRequests();
  }

  void _listenForFriendRequests() {
    FirebaseFirestore.instance
        .collection("friendRequests")
        .where("recipient", isEqualTo: _auth.currentUser!.uid)
        .where("status", isEqualTo: "pending")
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _friendRequestCount = snapshot.docs.length;
      });
    });
  }

  void _sendFriendRequest(String recipientUid) async {
    String senderUid = _auth.currentUser!.uid;
    await FirebaseFirestore.instance.collection("friendRequests").add({
      "sender": senderUid,
      "recipient": recipientUid,
      "status": "pending",
    });
  }

  void _acceptFriendRequest(DocumentSnapshot friendRequest) async {
    await friendRequest.reference.update({"status": "accepted"});

    String recipientUid = friendRequest["recipient"];
    String senderUid = friendRequest["sender"];
    await FirebaseFirestore.instance
        .collection("users")
        .doc(recipientUid)
        .update({
      "friends": FieldValue.arrayUnion([senderUid])
    });

    await FirebaseFirestore.instance.collection("users").doc(senderUid).update({
      "friends": FieldValue.arrayUnion([recipientUid])
    });
  }

  void _rejectFriendRequest(DocumentSnapshot friendRequest) async {
    await friendRequest.reference.update({"status": "rejected"});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Search Page"),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () {
                      setState(() {
                        _showNotifications = !_showNotifications;
                      });
                    },
                  ),
                  if (_friendRequestCount > 0)
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '$_friendRequestCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                ],
              ),
            ],
          ),
          if (_showNotifications)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("friendRequests")
                  .where("recipient", isEqualTo: _auth.currentUser!.uid)
                  .where("status", isEqualTo: "pending")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("Something went wrong");
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text("Loading");
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot friendRequest = snapshot.data!.docs[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection("users")
                          .doc(friendRequest["sender"])
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text("Something went wrong");
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text("Loading");
                        }

                        DocumentSnapshot user = snapshot.data!;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: _getUserImage(user),
                          ),
                          title: Text(user["name"]),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.check),
                                onPressed: () {
                                  _acceptFriendRequest(friendRequest);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () {
                                  _rejectFriendRequest(friendRequest);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchText = value;
              });
            },
            decoration: InputDecoration(
                labelText: "Search", prefixIcon: Icon(Icons.search)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .where("name", isGreaterThanOrEqualTo: _searchText)
                  .where("name", isLessThan: _searchText + 'z')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("Something went wrong");
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text("Loading");
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot docSnapshot = snapshot.data!.docs[index];
                    Map<String, dynamic> user =
                        docSnapshot.data() as Map<String, dynamic>;

                    // Verifique se os campos necessários existem antes de acessá-los
                    String imageUrl =
                        user.containsKey('imageUrl') ? user['imageUrl'] : '';
                    String name = user.containsKey('name') ? user['name'] : '';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.containsKey('imageUrl') &&
                                user['imageUrl'] != null
                            ? NetworkImage(user['imageUrl'])
                            : null,
                        child: user.containsKey('imageUrl') &&
                                user['imageUrl'] == null
                            ? Icon(Icons.person)
                            : null,
                      ),
                      title: Text(name),
                      trailing: IconButton(
                        icon: Icon(Icons.person_add),
                        onPressed: () {
                          _sendFriendRequest(docSnapshot.id);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          TextField(
            controller: _searchFriendsController,
            onChanged: (value) {
              setState(() {
                _searchFriendsText = value;
              });
            },
            decoration: InputDecoration(
                labelText: "Search Friends", prefixIcon: Icon(Icons.search)),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_auth.currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Something went wrong');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text('Loading');
                }
                List<dynamic> friends = [];
                List<dynamic> sentFriendRequests = [];

                if (snapshot.data!.exists) {
                  var data = snapshot.data!.data();
                  if (data is Map<String, dynamic>) {
                    friends = data['friends'] ?? [];
                    sentFriendRequests = data['sentFriendRequests'] ?? [];
                  }
                }
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Something went wrong');
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text('Loading');
                    }
                    List<DocumentSnapshot> filteredUsers = snapshot.data!.docs
                        .where((user) =>
                            (friends.contains(user.id) ||
                                sentFriendRequests.contains(user.id)) &&
                            user['name']
                                .toLowerCase()
                                .startsWith(_searchFriendsText.toLowerCase()))
                        .toList();
                    return ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot user = filteredUsers[index];
                        return ListTile(
                          title: Text(user['name']),
                          trailing: IconButton(
                            icon: Icon(Icons.chat),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    recipientUid: user.id,
                                    recipientName: user['name'],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
// import 'dart:io';
// import 'package:firebase_auth/firebase_auth.dart';

// class AmigosPage extends StatefulWidget {
//   @override
//   _AmigosPageState createState() => _AmigosPageState();
// }

// class BellIcon extends StatefulWidget {
//   final CollectionReference friendRequestsRef;
//   final User currentUser;
//   final VoidCallback onPressed;

//   BellIcon({
//     required this.friendRequestsRef,
//     required this.currentUser,
//     required this.onPressed,
//   });

//   @override
//   _BellIconState createState() => _BellIconState();
// }

// class _BellIconState extends State<BellIcon> {
//   int friendRequestCount = 0;

//   @override
//   void initState() {
//     super.initState();
//     widget.friendRequestsRef
//         .where('to', isEqualTo: widget.currentUser.uid)
//         .snapshots()
//         .listen((querySnapshot) {
//       setState(() {
//         friendRequestCount = querySnapshot.docs.length;
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         IconButton(
//           icon: Icon(Icons.notifications),
//           onPressed: widget.onPressed,
//         ),
//         if (friendRequestCount > 0)
//           Positioned(
//             right: 0,
//             child: Container(
//               padding: EdgeInsets.all(2),
//               decoration: BoxDecoration(
//                 color: Colors.red,
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               constraints: BoxConstraints(
//                 minWidth: 14,
//                 minHeight: 14,
//               ),
//               child: Text(
//                 friendRequestCount.toString(),
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 8,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//           )
//       ],
//     );
//   }
// }

// class _AmigosPageState extends State<AmigosPage> {
//   final currentUser = FirebaseAuth.instance.currentUser!;
//   List<Map<String, dynamic>> searchResults = [];
//   String imageUrl = ''; // initialize the variable
//   File? _image;
//   final friendRequestsRef =
//       FirebaseFirestore.instance.collection('friendRequests');

//   @override
//   void initState() {
//     super.initState();

//     final userRef =
//         FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
//   }

//   void sendFriendRequest(String toUserId) {
//     final currentUser = FirebaseAuth.instance.currentUser!;
//     friendRequestsRef.add({
//       'from': currentUser.uid,
//       'to': toUserId,
//       'timestamp': DateTime.now().millisecondsSinceEpoch,
//     });
//   }

//   void showFriendRequestsModal() {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return StreamBuilder<QuerySnapshot>(
//           stream: friendRequestsRef
//               .where('to', isEqualTo: currentUser.uid)
//               .snapshots(),
//           builder: (context, snapshot) {
//             if (!snapshot.hasData) {
//               return Center(child: CircularProgressIndicator());
//             }
//             final friendRequests = snapshot.data!.docs;
//             return ListView.builder(
//               itemCount: friendRequests.length,
//               itemBuilder: (context, index) {
//                 final friendRequest = friendRequests[index];
//                 return ListTile(
//                   title: Text(friendRequest['from']),
//                   trailing: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       IconButton(
//                         icon: Icon(Icons.check),
//                         onPressed: () {
//                           // Accept friend request
//                           FirebaseFirestore.instance.collection('friends').add({
//                             'user1': currentUser.uid,
//                             'user2': friendRequest['from'],
//                           });
//                           friendRequest.reference.delete();
//                         },
//                       ),
//                       IconButton(
//                         icon: Icon(Icons.close),
//                         onPressed: () {
//                           // Reject friend request
//                           friendRequest.reference.delete();
//                         },
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             );
//           },
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         title: Text("Amigos"),
//         centerTitle: true,
//         actions: [
//           BellIcon(
//             friendRequestsRef: friendRequestsRef,
//             currentUser: currentUser,
//             onPressed: showFriendRequestsModal,
//           ),
//         ],
//       ),
//       body: Container(
//         padding: EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Descubra Novos Amigos",
//               style: TextStyle(
//                 fontSize: 20.0,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 20.0),
//             Container(
//               decoration: BoxDecoration(
//                 border: Border.all(color: Color.fromARGB(255, 0, 0, 0)),
//                 borderRadius: BorderRadius.circular(10.0),
//               ),
//               child: Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 10.0),
//                 child: Row(
//                   children: [
//                     Icon(Icons.search),
//                     SizedBox(width: 10.0),
//                     Expanded(
//                       child: TextField(
//                         decoration: InputDecoration(
//                           border: InputBorder.none,
//                           hintText: 'Pesquisar Utilizadores',
//                           contentPadding: EdgeInsets.zero,
//                         ),
//                         onChanged: (value) {
//                           setState(() {
//                             searchResults = [];
//                           });
//                           // Executa a consulta para buscar os usuários cujos nomes correspondem à consulta do usuário
//                           FirebaseFirestore.instance
//                               .collection('users')
//                               .where('nomeUsuario',
//                                   isGreaterThanOrEqualTo: value)
//                               .where('nomeUsuario',
//                                   isLessThanOrEqualTo: value + '\uf8ff')
//                               .get()
//                               .then((querySnapshot) {
//                             // Adiciona os resultados da pesquisa à lista de resultados
//                             setState(() {
//                               searchResults = querySnapshot.docs
//                                   .map((doc) => doc.data())
//                                   .toList();
//                             });
//                           });
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             Expanded(
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: searchResults.length,
//                 itemBuilder: (BuildContext context, int index) {
//                   final user = searchResults[index];
//                   return ListTile(
//                     leading: CircleAvatar(
//                       backgroundImage:
//                           _image != null ? FileImage(_image!) : null,
//                     ),
//                     title: Row(
//                       children: [
//                         Text(user['nomeUsuario']),
//                         Spacer(),
//                         IconButton(
//                           icon: searchResults[index]['requested'] == true
//                               ? Icon(Icons.person)
//                               : Icon(MdiIcons.accountPlus),
//                           onPressed: () {
//                             sendFriendRequest(user['id']);
//                           },
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//             SizedBox(height: 20.0),
//             Text(
//               "Seus Amigos",
//               style: TextStyle(
//                 fontSize: 20.0,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 20.0),
//             Container(
//               decoration: BoxDecoration(
//                 border: Border.all(color: Color.fromARGB(255, 0, 0, 0)),
//                 borderRadius: BorderRadius.circular(10.0),
//               ),
//               child: Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 10.0),
//                 child: Row(
//                   children: [
//                     Icon(Icons.search),
//                     SizedBox(width: 10.0),
//                     Expanded(
//                       child: TextField(
//                         decoration: InputDecoration(
//                           border: InputBorder.none,
//                           hintText: 'Pesquisar Amigos',
//                           contentPadding: EdgeInsets.zero,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
