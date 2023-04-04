import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher_string.dart';
import 'package:uuid/uuid.dart';

import 'invite.dart';

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    required this.invites,
  });

  static const routeName = '/';

  final List<Invite> invites;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  UserCredential? _userCredential;
  final db = FirebaseFirestore.instance;
  Future<QuerySnapshot<Map<String, dynamic>>>? _invitesFuture;

  @override
  void initState() {
    _invitesFuture = _fetchInvites();
    super.initState();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchInvites() async {
    return await db.collection('invites').get();
  }

  @override
  void dispose() {
    FirebaseAuth.instance.signOut();
    _userCredential = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text("Let'sDoFunnyStuff"),
        actions: [
          TextButton(
            onPressed: () async {
              GoogleAuthProvider googleProvider = GoogleAuthProvider();

              googleProvider.addScope(
                  'https://www.googleapis.com/auth/contacts.readonly');
              googleProvider
                  .setCustomParameters({'login_hint': 'user@example.com'});

              _userCredential =
                  await FirebaseAuth.instance.signInWithPopup(googleProvider);
            },
            child: const Text('Sign In With Google'),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: LayoutBuilder(builder: (context, constrains) {
            return SizedBox(
              width: math.min(constrains.maxWidth, 600),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: 'Search...',
                              suffixIcon: IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.search,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder(
                        future: _invitesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final invites =
                                snapshot.data!.docs.map<Invite>((e) {
                              return Invite.fromMap(e.data());
                            }).toList();

                            if (invites.isEmpty) {
                              return const Center(
                                child: Text('No invites yet. Be first!'),
                              );
                            }

                            return ListView.builder(
                              restorationId: 'invites',
                              itemCount: invites.length,
                              itemBuilder: (BuildContext context, int index) {
                                final item = invites[index];

                                return InviteView(
                                  invite: item,
                                );
                              },
                            );
                          } else if (snapshot.hasError) {
                            debugPrint(snapshot.error.toString());
                            return Center(
                              child: Text('Error! ${snapshot.error}'),
                            );
                          } else {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                        }),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_userCredential == null) {
            final messenger = ScaffoldMessenger.of(context);
            messenger.removeCurrentSnackBar();
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Please sign in first'),
              ),
            );
            return;
          }

          // show dialog to create invite
          showDialog(
            context: context,
            builder: (context) {
              return CreateInviteDialog(
                author: _userCredential!.user?.displayName ?? 'Anonymous',
                onDone: (invite) {
                  setState(() {
                    widget.invites.add(invite);
                    db.collection('invites').add(invite.toMap());
                    _invitesFuture = _fetchInvites();
                  });
                },
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class InviteView extends StatelessWidget {
  const InviteView({
    super.key,
    required this.invite,
  });

  final Invite invite;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              invite.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                children: [
                  Text(
                    invite.author,
                  ),
                  const VerticalDivider(
                    thickness: 1.5,
                  ),
                  Text(
                    invite.publicationDate.toString(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              invite.content,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Contact Link: '),
                TextButton(
                  onPressed: () {
                    launchUrlString(invite.contactLink);
                  },
                  child: Text(invite.contactLink),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CreateInviteDialog extends StatefulWidget {
  const CreateInviteDialog({
    super.key,
    required this.onDone,
    required this.author,
  });

  final String author;
  final void Function(Invite invite) onDone;

  @override
  State<CreateInviteDialog> createState() => _CreateInviteDialogState();
}

class _CreateInviteDialogState extends State<CreateInviteDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _contactLinkController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).dialogBackgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'New Invite',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 21,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Title',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Content',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contactLinkController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Contact link (like https://t.me/mishkovdd)',
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        final messenger = ScaffoldMessenger.of(context);

                        if (_titleController.text.isEmpty) {
                          messenger.removeCurrentSnackBar();
                          messenger.showSnackBar(const SnackBar(
                            content: Text('Please enter title'),
                          ));

                          return;
                        }

                        if (_contentController.text.isEmpty) {
                          messenger.removeCurrentSnackBar();
                          messenger.showSnackBar(const SnackBar(
                            content: Text('Please enter content'),
                          ));

                          return;
                        }

                        if (_contactLinkController.text.isEmpty) {
                          messenger.removeCurrentSnackBar();
                          messenger.showSnackBar(const SnackBar(
                            content: Text('Please enter contact link'),
                          ));

                          return;
                        }

                        final invite = Invite(
                          id: const Uuid().v1(),
                          title: _titleController.text,
                          author: widget.author,
                          publicationDate: DateTime.now(),
                          content: _contentController.text,
                          contactLink: _contactLinkController.text,
                        );

                        widget.onDone(invite);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Create'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
