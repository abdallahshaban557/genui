// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fcp_client/fcp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ListViewBuilder', () {
    testWidgets('builds a list of items from state', (
      WidgetTester tester,
    ) async {
      final WidgetCatalogRegistry registry = WidgetCatalogRegistry()
        ..register(
          CatalogItem(
            name: 'ListViewBuilder',
            builder: (BuildContext context, LayoutNode node, Map<String, Object?> properties, Map<String, List<Widget>> children) =>
                const SizedBox.shrink(),
            definition: WidgetDefinition.fromMap(<String, Object?>{
              'properties': <dynamic, dynamic>{},
              'bindings': <String, Map<String, String>>{
                'data': <String, String>{'path': 'string'},
              },
            }),
          ),
        )
        ..register(
          CatalogItem(
            name: 'Text',
            builder: (BuildContext context, LayoutNode node, Map<String, Object?> properties, Map<String, List<Widget>> children) {
              return Text(
                properties['data'] as String? ?? '',
                textDirection: TextDirection.ltr,
              );
            },
            definition: WidgetDefinition.fromMap(<String, Object?>{
              'properties': <String, Map<String, String>>{
                'data': <String, String>{'type': 'String'},
              },
            }),
          ),
        );
      final WidgetCatalog catalog = registry.buildCatalog(catalogVersion: '1.0.0');

      final DynamicUIPacket packet = DynamicUIPacket.fromMap(<String, Object?>{
        'formatVersion': '1.0.0',
        'layout': <String, Object>{
          'root': 'my_list',
          'nodes': <Map<String, Object>>[
            <String, Object>{
              'id': 'my_list',
              'type': 'ListViewBuilder',
              'bindings': <String, Map<String, String>>{
                'data': <String, String>{'path': 'items'},
              },
              'itemTemplate': <String, Object>{
                'id': 'item_template',
                'type': 'Text',
                'bindings': <String, Map<String, String>>{
                  'data': <String, String>{'path': 'item.name'},
                },
              },
            },
          ],
        },
        'state': <String, List<Map<String, String>>>{
          'items': <Map<String, String>>[
            <String, String>{'name': 'Apple'},
            <String, String>{'name': 'Banana'},
            <String, String>{'name': 'Cherry'},
          ],
        },
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(packet: packet, catalog: catalog, registry: registry),
        ),
      );

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets('itemTemplate bindings are resolved correctly', (
      WidgetTester tester,
    ) async {
      final WidgetCatalogRegistry registry = WidgetCatalogRegistry()
        ..register(
          CatalogItem(
            name: 'ListViewBuilder',
            builder: (BuildContext context, LayoutNode node, Map<String, Object?> properties, Map<String, List<Widget>> children) =>
                const SizedBox.shrink(),
            definition: WidgetDefinition.fromMap(<String, Object?>{
              'properties': <dynamic, dynamic>{},
              'bindings': <String, Map<String, String>>{
                'data': <String, String>{'path': 'string'},
              },
            }),
          ),
        )
        ..register(
          CatalogItem(
            name: 'Text',
            builder: (BuildContext context, LayoutNode node, Map<String, Object?> properties, Map<String, List<Widget>> children) {
              return Text(
                properties['data'] as String? ?? '',
                textDirection: TextDirection.ltr,
              );
            },
            definition: WidgetDefinition.fromMap(<String, Object?>{
              'properties': <String, Map<String, String>>{
                'data': <String, String>{'type': 'String'},
              },
            }),
          ),
        );
      final WidgetCatalog catalog = registry.buildCatalog(catalogVersion: '1.0.0');

      final DynamicUIPacket packet = DynamicUIPacket.fromMap(<String, Object?>{
        'formatVersion': '1.0.0',
        'layout': <String, Object>{
          'root': 'my_list',
          'nodes': <Map<String, Object>>[
            <String, Object>{
              'id': 'my_list',
              'type': 'ListViewBuilder',
              'bindings': <String, Map<String, String>>{
                'data': <String, String>{'path': 'items'},
              },
              'itemTemplate': <String, Object>{
                'id': 'item_template',
                'type': 'Text',
                'bindings': <String, Map<String, String>>{
                  'data': <String, String>{'path': 'item.name', 'format': 'Fruit: {}'},
                },
              },
            },
          ],
        },
        'state': <String, List<Map<String, String>>>{
          'items': <Map<String, String>>[
            <String, String>{'name': 'Apple'},
          ],
        },
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(packet: packet, catalog: catalog, registry: registry),
        ),
      );

      expect(find.text('Fruit: Apple'), findsOneWidget);
    });
  });
}
