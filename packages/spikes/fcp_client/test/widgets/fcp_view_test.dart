// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:fcp_client/fcp_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FcpView', () {
    testWidgets('renders a simple static UI', (WidgetTester tester) async {
      final WidgetCatalogRegistry registry = WidgetCatalogRegistry()
        ..register(
          CatalogItem(
            name: 'Text',
            builder:
                (
                  BuildContext context,
                  LayoutNode node,
                  Map<String, Object?> properties,
                  Map<String, List<Widget>> children,
                ) {
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

      final WidgetCatalog catalog = registry.buildCatalog(
        catalogVersion: '1.0.0',
      );

      final DynamicUIPacket packet = DynamicUIPacket.fromMap(<String, Object?>{
        'formatVersion': '1.0.0',
        'layout': <String, Object>{
          'root': 'hello',
          'nodes': <Map<String, Object>>[
            <String, Object>{
              'id': 'hello',
              'type': 'Text',
              'properties': <String, String>{'data': 'Hello, FCP!'},
            },
          ],
        },
        'state': <String, Object?>{},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(packet: packet, catalog: catalog, registry: registry),
        ),
      );

      expect(find.text('Hello, FCP!'), findsOneWidget);
    });

    testWidgets('renders a nested UI', (WidgetTester tester) async {
      final WidgetCatalogRegistry registry = WidgetCatalogRegistry()
        ..register(
          CatalogItem(
            name: 'Text',
            builder:
                (
                  BuildContext context,
                  LayoutNode node,
                  Map<String, Object?> properties,
                  Map<String, List<Widget>> children,
                ) {
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
        )
        ..register(
          CatalogItem(
            name: 'Column',
            builder:
                (
                  BuildContext context,
                  LayoutNode node,
                  Map<String, Object?> properties,
                  Map<String, List<Widget>> children,
                ) {
                  return Column(children: children['children'] ?? <Widget>[]);
                },
            definition: WidgetDefinition.fromMap(<String, Object?>{
              'properties': <String, Map<String, String>>{
                'children': <String, String>{'type': 'ListOfWidgetIds'},
              },
            }),
          ),
        );

      final WidgetCatalog catalog = registry.buildCatalog(
        catalogVersion: '1.0.0',
      );

      final DynamicUIPacket packet = DynamicUIPacket.fromMap(<String, Object?>{
        'formatVersion': '1.0.0',
        'layout': <String, Object>{
          'root': 'col',
          'nodes': <Map<String, Object>>[
            <String, Object>{
              'id': 'col',
              'type': 'Column',
              'properties': <String, List<String>>{
                'children': <String>['text1', 'text2'],
              },
            },
            <String, Object>{
              'id': 'text1',
              'type': 'Text',
              'properties': <String, String>{'data': 'Line 1'},
            },
            <String, Object>{
              'id': 'text2',
              'type': 'Text',
              'properties': <String, String>{'data': 'Line 2'},
            },
          ],
        },
        'state': <String, Object?>{},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(packet: packet, catalog: catalog, registry: registry),
        ),
      );

      expect(find.text('Line 1'), findsOneWidget);
      expect(find.text('Line 2'), findsOneWidget);
    });

    testWidgets('displays an error for an unknown widget type', (
      WidgetTester tester,
    ) async {
      final WidgetCatalogRegistry registry = WidgetCatalogRegistry();
      final WidgetCatalog catalog = registry.buildCatalog(
        catalogVersion: '1.0.0',
      );
      final DynamicUIPacket packet = DynamicUIPacket.fromMap(<String, Object?>{
        'formatVersion': '1.0.0',
        'layout': <String, Object>{
          'root': 'unknown',
          'nodes': <Map<String, String>>[
            <String, String>{'id': 'unknown', 'type': 'MyBogusWidget'},
          ],
        },
        'state': <String, Object?>{},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(packet: packet, catalog: catalog, registry: registry),
        ),
      );

      expect(find.textContaining('No builder registered'), findsOneWidget);
    });

    testWidgets('rebuilds when a new packet is provided', (
      WidgetTester tester,
    ) async {
      final WidgetCatalogRegistry registry = WidgetCatalogRegistry()
        ..register(
          CatalogItem(
            name: 'Text',
            builder:
                (
                  BuildContext context,
                  LayoutNode node,
                  Map<String, Object?> properties,
                  Map<String, List<Widget>> children,
                ) {
                  return Text(
                    properties['data'] as String? ?? '',
                    textDirection: TextDirection.ltr,
                  );
                },
            definition: WidgetDefinition(
              properties: ObjectSchema(
                properties: <String, Schema>{'data': Schema.string()},
              ),
              events: ObjectSchema(
                properties: <String, Schema>{
                  'onChanged': Schema.object(
                    properties: <String, Schema>{'data': Schema.boolean()},
                  ),
                },
              ),
            ),
          ),
        );
      final WidgetCatalog catalog = registry.buildCatalog(
        catalogVersion: '1.0.0',
      );

      final DynamicUIPacket initialPacket = DynamicUIPacket.fromMap(
        <String, Object?>{
          'formatVersion': '1.0.0',
          'layout': <String, Object>{
            'root': 'text',
            'nodes': <Map<String, Object>>[
              <String, Object>{
                'id': 'text',
                'type': 'Text',
                'properties': <String, String>{'data': 'Initial'},
              },
            ],
          },
          'state': <String, Object?>{},
        },
      );

      final DynamicUIPacket newPacket = DynamicUIPacket.fromMap(
        <String, Object?>{
          'formatVersion': '1.0.0',
          'layout': <String, Object>{
            'root': 'text',
            'nodes': <Map<String, Object>>[
              <String, Object>{
                'id': 'text',
                'type': 'Text',
                'properties': <String, String>{'data': 'Updated'},
              },
            ],
          },
          'state': <String, Object?>{},
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: initialPacket,
            catalog: catalog,
            registry: registry,
          ),
        ),
      );
      expect(find.text('Initial'), findsOneWidget);
      expect(find.text('Updated'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: newPacket,
            catalog: catalog,
            registry: registry,
          ),
        ),
      );
      expect(find.text('Initial'), findsNothing);
      expect(find.text('Updated'), findsOneWidget);
    });
  });

  group('FcpView State and Bindings', () {
    testWidgets('renders UI with bound state', (WidgetTester tester) async {
      final WidgetCatalogRegistry registry = WidgetCatalogRegistry()
        ..register(
          CatalogItem(
            name: 'Text',
            builder:
                (
                  BuildContext context,
                  LayoutNode node,
                  Map<String, Object?> properties,
                  Map<String, List<Widget>> children,
                ) {
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
      final WidgetCatalog catalog = registry.buildCatalog(
        catalogVersion: '1.0.0',
      );

      final DynamicUIPacket packet = DynamicUIPacket.fromMap(<String, Object?>{
        'formatVersion': '1.0.0',
        'layout': <String, Object>{
          'root': 'text',
          'nodes': <Map<String, Object>>[
            <String, Object>{
              'id': 'text',
              'type': 'Text',
              'bindings': <String, Map<String, String>>{
                'data': <String, String>{'path': 'message'},
              },
            },
          ],
        },
        'state': <String, Object?>{'message': 'Hello from state!'},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(packet: packet, catalog: catalog, registry: registry),
        ),
      );

      expect(find.text('Hello from state!'), findsOneWidget);
    });

    testWidgets('UI updates when state changes via controller', (
      WidgetTester tester,
    ) async {
      final WidgetCatalogRegistry registry = WidgetCatalogRegistry()
        ..register(
          CatalogItem(
            name: 'Text',
            builder:
                (
                  BuildContext context,
                  LayoutNode node,
                  Map<String, Object?> properties,
                  Map<String, List<Widget>> children,
                ) {
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
      final WidgetCatalog catalog = registry.buildCatalog(
        catalogVersion: '1.0.0',
      );
      final FcpViewController controller = FcpViewController();

      final DynamicUIPacket packet = DynamicUIPacket.fromMap(<String, Object?>{
        'formatVersion': '1.0.0',
        'layout': <String, Object>{
          'root': 'text',
          'nodes': <Map<String, Object>>[
            <String, Object>{
              'id': 'text',
              'type': 'Text',
              'bindings': <String, Map<String, String>>{
                'data': <String, String>{'path': 'message'},
              },
            },
          ],
        },
        'state': <String, Object?>{'message': 'Initial'},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: packet,
            catalog: catalog,
            registry: registry,
            controller: controller,
          ),
        ),
      );

      expect(find.text('Initial'), findsOneWidget);

      // Act
      controller.patchState(
        StateUpdate.fromMap(<String, Object?>{
          'patches': <Map<String, String>>[
            <String, String>{
              'op': 'replace',
              'path': '/message',
              'value': 'Updated',
            },
          ],
        }),
      );
      await tester.pump();

      // Assert
      expect(find.text('Initial'), findsNothing);
      expect(find.text('Updated'), findsOneWidget);
    });
  });

  group('FcpView Events', () {
    testWidgets('fires onEvent callback with correct payload', (
      WidgetTester tester,
    ) async {
      EventPayload? capturedPayload;

      final WidgetCatalogRegistry registry = WidgetCatalogRegistry()
        ..register(
          CatalogItem(
            name: 'EventButton',
            builder:
                (
                  BuildContext context,
                  LayoutNode node,
                  Map<String, Object?> properties,
                  Map<String, List<Widget>> children,
                ) {
                  return ElevatedButton(
                    onPressed: () {
                      FcpProvider.of(context)?.onEvent?.call(
                        EventPayload.fromMap(<String, Object?>{
                          'sourceNodeId': node.id,
                          'eventName': 'onPressed',
                          'arguments': <String, Object?>{'test': 'data'},
                        }),
                      );
                    },
                    child: const Text('Tap Me'),
                  );
                },
            definition: WidgetDefinition.fromMap(<String, Object?>{
              'properties': <String, Object?>{},
              'events': <String, Map<String, Object>>{
                'onPressed': <String, Object>{
                  'type': 'object',
                  'properties': <String, Map<String, String>>{
                    'test': <String, String>{'type': 'String'},
                  },
                },
              },
            }),
          ),
        );
      final WidgetCatalog catalog = registry.buildCatalog(
        catalogVersion: '1.0.0',
      );

      final DynamicUIPacket packet = DynamicUIPacket.fromMap(<String, Object?>{
        'formatVersion': '1.0.0',
        'layout': <String, Object>{
          'root': 'button',
          'nodes': <Map<String, String>>[
            <String, String>{'id': 'button', 'type': 'EventButton'},
          ],
        },
        'state': <String, Object?>{},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: packet,
            catalog: catalog,
            registry: registry,
            onEvent: (EventPayload payload) {
              capturedPayload = payload;
            },
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(capturedPayload, isNotNull);
      expect(capturedPayload!.sourceNodeId, 'button');
      expect(capturedPayload!.eventName, 'onPressed');
      expect(capturedPayload!.arguments, <String, String>{'test': 'data'});
    });
  });

  group('FcpView Layout Updates', () {
    testWidgets('adds a widget with LayoutUpdate', (WidgetTester tester) async {
      final FcpViewController controller = FcpViewController();
      final WidgetCatalogRegistry registry = WidgetCatalogRegistry()
        ..register(
          CatalogItem(
            name: 'Column',
            builder:
                (
                  BuildContext context,
                  LayoutNode node,
                  Map<String, Object?> properties,
                  Map<String, List<Widget>> children,
                ) {
                  return Column(children: children['children'] ?? <Widget>[]);
                },
            definition: WidgetDefinition.fromMap(<String, Object?>{
              'properties': <String, Map<String, String>>{
                'children': <String, String>{'type': 'ListOfWidgetIds'},
              },
            }),
          ),
        )
        ..register(
          CatalogItem(
            name: 'Text',
            builder:
                (
                  BuildContext context,
                  LayoutNode node,
                  Map<String, Object?> properties,
                  Map<String, List<Widget>> children,
                ) {
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
      final WidgetCatalog catalog = registry.buildCatalog(
        catalogVersion: '1.0.0',
      );

      final DynamicUIPacket packet = DynamicUIPacket.fromMap(<String, Object?>{
        'formatVersion': '1.0.0',
        'layout': <String, Object>{
          'root': 'col',
          'nodes': <Map<String, Object>>[
            <String, Object>{
              'id': 'col',
              'type': 'Column',
              'properties': <String, List<String>>{
                'children': <String>['text1'],
              },
            },
            <String, Object>{
              'id': 'text1',
              'type': 'Text',
              'properties': <String, String>{'data': 'First'},
            },
          ],
        },
        'state': <String, Object?>{},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: packet,
            catalog: catalog,
            registry: registry,
            controller: controller,
          ),
        ),
      );

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsNothing);

      // Act
      controller.patchLayout(
        LayoutUpdate.fromMap(<String, Object?>{
          'operations': <Map<String, Object>>[
            <String, Object>{
              'op': 'add',
              'nodes': <Map<String, Object>>[
                <String, Object>{
                  'id': 'text2',
                  'type': 'Text',
                  'properties': <String, String>{'data': 'Second'},
                },
              ],
            },
            <String, Object>{
              'op': 'replace',
              'nodes': <Map<String, Object>>[
                <String, Object>{
                  'id': 'col',
                  'type': 'Column',
                  'properties': <String, List<String>>{
                    'children': <String>['text1', 'text2'],
                  },
                },
              ],
            },
          ],
        }),
      );
      await tester.pump();

      // Assert
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
    });

    testWidgets('removes a widget with LayoutUpdate', (
      WidgetTester tester,
    ) async {
      final FcpViewController controller = FcpViewController();
      final WidgetCatalogRegistry registry = WidgetCatalogRegistry()
        ..register(
          CatalogItem(
            name: 'Column',
            builder:
                (
                  BuildContext context,
                  LayoutNode node,
                  Map<String, Object?> properties,
                  Map<String, List<Widget>> children,
                ) {
                  return Column(children: children['children'] ?? <Widget>[]);
                },
            definition: WidgetDefinition.fromMap(<String, Object?>{
              'properties': <String, Map<String, String>>{
                'children': <String, String>{'type': 'ListOfWidgetIds'},
              },
            }),
          ),
        )
        ..register(
          CatalogItem(
            name: 'Text',
            builder:
                (
                  BuildContext context,
                  LayoutNode node,
                  Map<String, Object?> properties,
                  Map<String, List<Widget>> children,
                ) {
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
      final WidgetCatalog catalog = registry.buildCatalog(
        catalogVersion: '1.0.0',
      );

      final DynamicUIPacket packet = DynamicUIPacket.fromMap(<String, Object?>{
        'formatVersion': '1.0.0',
        'layout': <String, Object>{
          'root': 'col',
          'nodes': <Map<String, Object>>[
            <String, Object>{
              'id': 'col',
              'type': 'Column',
              'properties': <String, List<String>>{
                'children': <String>['text1', 'text2'],
              },
            },
            <String, Object>{
              'id': 'text1',
              'type': 'Text',
              'properties': <String, String>{'data': 'First'},
            },
            <String, Object>{
              'id': 'text2',
              'type': 'Text',
              'properties': <String, String>{'data': 'Second'},
            },
          ],
        },
        'state': <String, Object?>{},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: packet,
            catalog: catalog,
            registry: registry,
            controller: controller,
          ),
        ),
      );

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);

      // Act
      controller.patchLayout(
        LayoutUpdate.fromMap(<String, Object?>{
          'operations': <Map<String, Object>>[
            <String, Object>{
              'op': 'remove',
              'nodeIds': <String>['text2'],
            },
            <String, Object>{
              'op': 'replace',
              'nodes': <Map<String, Object>>[
                <String, Object>{
                  'id': 'col',
                  'type': 'Column',
                  'properties': <String, List<String>>{
                    'children': <String>['text1'],
                  },
                },
              ],
            },
          ],
        }),
      );
      await tester.pump();

      // Assert
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsNothing);
    });

    testWidgets('updates a widget with LayoutUpdate', (
      WidgetTester tester,
    ) async {
      final FcpViewController controller = FcpViewController();
      final WidgetCatalogRegistry registry = WidgetCatalogRegistry()
        ..register(
          CatalogItem(
            name: 'Text',
            builder:
                (
                  BuildContext context,
                  LayoutNode node,
                  Map<String, Object?> properties,
                  Map<String, List<Widget>> children,
                ) {
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
      final WidgetCatalog catalog = registry.buildCatalog(
        catalogVersion: '1.0.0',
      );

      final DynamicUIPacket packet = DynamicUIPacket.fromMap(<String, Object?>{
        'formatVersion': '1.0.0',
        'layout': <String, Object>{
          'root': 'text1',
          'nodes': <Map<String, Object>>[
            <String, Object>{
              'id': 'text1',
              'type': 'Text',
              'properties': <String, String>{'data': 'Before'},
            },
          ],
        },
        'state': <String, Object?>{},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FcpView(
            packet: packet,
            catalog: catalog,
            registry: registry,
            controller: controller,
          ),
        ),
      );

      expect(find.text('Before'), findsOneWidget);
      expect(find.text('After'), findsNothing);

      // Act
      controller.patchLayout(
        LayoutUpdate.fromMap(<String, Object?>{
          'operations': <Map<String, Object>>[
            <String, Object>{
              'op': 'replace',
              'nodes': <Map<String, Object>>[
                <String, Object>{
                  'id': 'text1',
                  'type': 'Text',
                  'properties': <String, String>{'data': 'After'},
                },
              ],
            },
          ],
        }),
      );
      await tester.pump();

      // Assert
      expect(find.text('Before'), findsNothing);
      expect(find.text('After'), findsOneWidget);
    });
  });
}
