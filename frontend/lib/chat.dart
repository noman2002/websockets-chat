import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return ChatPageState();
  }
}

class ChatPageState extends State<ChatPage> {
  late IOWebSocketChannel channel;
  late bool connected;

  String myid = "1234";
  String recieverid = "1234";
  String auth = "addauthkeyifrequired";

  List<MessageData> msglist = [];

  TextEditingController msgtext = TextEditingController();

  @override
  void initState() {
    connected = false;
    msgtext.text = "";
    channelconnect();
    super.initState();
  }

  void channelconnect() {
    try {
      channel = IOWebSocketChannel.connect("ws://10.0.2.2:6060/$myid");
      channel.stream.listen(
        (message) {
          if (kDebugMode) {
            print("Received: $message");
          }
          setState(() {
            if (message == "connected") {
              connected = true;
              if (kDebugMode) {
                print("Connection established.");
              }
            } else if (message == "send:success") {
              if (kDebugMode) {
                print("Message send success");
              }
              setState(() {
                msgtext.text = "";
              });
            } else if (message == "send:error") {
              if (kDebugMode) {
                print("Message send error");
              }
            } else {
              try {
                var jsondata = json.decode(message);
                if (jsondata['cmd'] == 'send') {
                  msglist.add(MessageData(
                    msgtext: jsondata["msgtext"],
                    userid: jsondata["userid"],
                    isme: false,
                  ));
                }
              } catch (e) {
                if (kDebugMode) {
                  print("Error parsing message: $e");
                }
              }
            }
          });
        },
        onDone: () {
          if (kDebugMode) {
            print("Web socket is closed");
          }
          setState(() {
            connected = false;
          });
          reconnect();
        },
        onError: (error) {
          if (kDebugMode) {
            print("WebSocket error: $error");
          }
          setState(() {
            connected = false;
          });
          reconnect();
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error connecting to WebSocket: $e");
      }
      setState(() {
        connected = false;
      });
      reconnect();
    }
  }

  void reconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!connected) {
        channelconnect();
      }
    });
  }

  Future<void> sendmsg(String sendmsg, String id) async {
    if (connected == true) {
      Map<String, dynamic> msg = {
        'auth': auth,
        'cmd': 'send',
        'userid': id,
        'msgtext': sendmsg
      };
      setState(() {
        msgtext.text = "";
        msglist.add(MessageData(msgtext: sendmsg, userid: myid, isme: true));
      });
      channel.sink.add(jsonEncode(msg));
    } else {
      channelconnect();
      if (kDebugMode) {
        print("Websocket is not connected.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // appBar: AppBar(
        //   // title: Text("My ID: $myid - Chat App Example"),
        //   leading: Icon(Icons.circle,
        //       color: connected ? Colors.greenAccent : Colors.redAccent),
        //   titleSpacing: 0,
        // ),
        body: Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 70,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(15),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Text("Your Messages",
                          style: TextStyle(fontSize: 20)),
                      Column(
                        children: msglist.map((onemsg) {
                          return Align(
                            alignment: onemsg.isme
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            // margin: EdgeInsets.only(
                            //   left: onemsg.isme ? 40 : 0,
                            //   right: onemsg.isme ? 0 : 40,
                            // ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                  color: onemsg.isme
                                      ? Colors.blue[100]
                                      : Colors.red[100],
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(10),
                                    topRight: const Radius.circular(10),
                                    bottomLeft: !onemsg.isme
                                        ? const Radius.circular(0)
                                        : const Radius.circular(10),
                                    bottomRight: onemsg.isme
                                        ? const Radius.circular(0)
                                        : const Radius.circular(10),
                                  )),
                              child: Container(
                                // width: double.infinity,
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(onemsg.isme
                                        ? "ID: ME"
                                        : "ID: ${onemsg.userid}"),
                                    Container(
                                      margin: const EdgeInsets.only(
                                          top: 10, bottom: 10),
                                      child: Text(
                                        onemsg.msgtext,
                                        style: const TextStyle(fontSize: 17),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black12,
                height: 70,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        child: TextField(
                          controller: msgtext,
                          decoration: const InputDecoration(
                            hintText: "Enter your Message",
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(10),
                      child: ElevatedButton(
                        child: const Icon(Icons.send),
                        onPressed: () {
                          if (msgtext.text != "") {
                            sendmsg(msgtext.text, recieverid);
                          } else {
                            if (kDebugMode) {
                              print("Enter message");
                            }
                          }
                        },
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class MessageData {
  String msgtext, userid;
  bool isme;
  MessageData({
    required this.msgtext,
    required this.userid,
    required this.isme,
  });
}
