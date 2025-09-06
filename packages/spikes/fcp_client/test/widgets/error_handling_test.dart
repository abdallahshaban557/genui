// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fcp_client/fcp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FcpView Error Handling', () {
    testWidgets('displays error for cyclical layout', (WidgetTester tester) async {
      final DynamicUIPacket packet = DynamicUIPacket.fromMap(<String, Object?>{
        'formatVersion': '1.0.0',
        'layout': <String, Object>{
          'root': 'node_a',
          'nodes': <Map<String, Object>>[
            <String, Object>{
              'id': 'node_a',
              'type': 'Container', // This type is not in the test catalog
              'properties': <String, String>{'child': 'node_b'},
            },
            <String, Object>{
              'id': 'node_b',
              'type': 'Container',
              'properties': <String, String>{'child': 'node_a'},
            },
          ],
        },
        'state': <String, Object?>{},
      });

      // We need a registry that has Container to test the cycle
      final WidgetCatalogRegistry cycleRegistry = WidgetCatalogRegistry()
        ..register(
          CatalogItem(
            name: 'Container',
            builder: (BuildContext context, LayoutNode node, Map<String, Object?> properties, Map<String, List<Widget>> children) =>
                Container(child: children['child']?.first),
            definition: WidgetDefinition.fromMap(<String, Object?>{
              'properties': <String, Map<String, String>>{
                'child': <String, String>{'type': 'WidgetId'},
              },
            }),
          ),
        );
      final WidgetCatalog cycleCatalog = cycleRegistry.buildCatalog(catalogVersion: '1.0.0');

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: packet,
            registry: cycleRegistry,
            catalog: cycleCatalog,
          ),
        ),
      );

      expect(find.textContaining('Cyclical layout detected'), findsOneWidget);
    });
  });
}
