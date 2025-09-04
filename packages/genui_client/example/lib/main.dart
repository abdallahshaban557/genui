// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:genui_client/genui_client.dart';
import 'package:genui_client/genui_client_core.dart';
import 'package:logging/logging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureGenUiLogging(level: Level.ALL);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Chat',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final UiAgent _uiAgent;
  late final UiEventManager _eventManager;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _uiAgent = UiAgent();
    _eventManager = UiEventManager(
      callback: (surfaceId, events) {
        _uiAgent.sendUiEvents(events);
      },
    );
    _init();
  }

  Future<void> _init() async {
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat with GenUI')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _isInitialized
              ? GenUiChat(
                  agent: _uiAgent,
                  onEvent: (event) {
                    _eventManager.add(event);
                  },
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _uiAgent.dispose();
    _eventManager.dispose();
    super.dispose();
  }
}
