import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class ChatScreen extends StatefulWidget {
  final String recipientUid;
  final String recipientName;

  ChatScreen({required this.recipientUid, required this.recipientName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() async {
    String messageText = _messageController.text;
    if (messageText.isEmpty) return;

    String senderUid = _auth.currentUser!.uid;
    String recipientUid = widget.recipientUid;

    DocumentReference messageRef =
        FirebaseFirestore.instance.collection("messages").doc();

    await Future.wait([
      messageRef.set({
        "text": messageText,
        "sender": senderUid,
        "recipient": recipientUid,
        "timestamp": FieldValue.serverTimestamp(),
        "read": false, // Set the read field to false
      }),
      FirebaseFirestore.instance
          .collection("users")
          .doc(senderUid)
          .collection("messages")
          .doc(messageRef.id)
          .set({"exists": true}),
      FirebaseFirestore.instance
          .collection("users")
          .doc(recipientUid)
          .collection("messages")
          .doc(messageRef.id)
          .set({"exists": true}),
    ]);

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot> sentMessagesStream = FirebaseFirestore.instance
        .collection("messages")
        .where("sender", isEqualTo: _auth.currentUser!.uid)
        .where("recipient", isEqualTo: widget.recipientUid)
        .orderBy("timestamp", descending: true)
        .snapshots();

    Stream<QuerySnapshot> receivedMessagesStream = FirebaseFirestore.instance
        .collection("messages")
        .where("sender", isEqualTo: widget.recipientUid)
        .where("recipient", isEqualTo: _auth.currentUser!.uid)
        .orderBy("timestamp", descending: true)
        .snapshots();

    Stream<DocumentSnapshot> recipientProfileStream = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.recipientUid)
        .snapshots();

    Stream<List<QueryDocumentSnapshot>> messagesStream = Rx.combineLatest2(
        sentMessagesStream,
        receivedMessagesStream,
        (QuerySnapshot sent, QuerySnapshot received) => [
              ...sent.docs.where((doc) => doc["timestamp"] != null),
              ...received.docs.where((doc) => doc["timestamp"] != null)
            ]..sort((a, b) => b["timestamp"].compareTo(a["timestamp"])));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(width: 10),
            Text(widget.recipientName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text("Loading");
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot message = snapshot.data![index];
                    bool isMe = message["sender"] == _auth.currentUser!.uid;
                    return ListTile(
                      leading: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("users")
                            .doc(message["sender"])
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            Map<String, dynamic>? userData =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            String imageUrl = userData!['imageUrl'] ?? '';
                            return CircleAvatar(
                              backgroundImage: imageUrl.isNotEmpty
                                  ? NetworkImage(imageUrl)
                                  : null, // Use uma imagem padrão ou ícone aqui se quiser
                            );
                          } else {
                            return CircleAvatar(); // Use um ícone padrão ou cor de fundo aqui se quiser
                          }
                        },
                      ),
                      title: Text(message["text"]),
                      subtitle: Text(message["timestamp"].toDate().toString()),
                      trailing: isMe ? Icon(Icons.check_circle_outline) : null,
                    );
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration:
                      InputDecoration(labelText: "Type your message here"),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: _sendMessage,
              )
            ],
          )
        ],
      ),
    );
  }
}
