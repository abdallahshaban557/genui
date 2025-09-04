// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_client/genui_client.dart';

void main() {
  group('Catalog', () {
    final testCatalogItem = CatalogItem(
      name: 'TestWidget',
      dataSchema: S.object(properties: {'text': S.string()}),
      widgetBuilder:
          ({
            required data,
            required id,
            required buildChild,
            required dispatchEvent,
            required context,
            required values,
          }) {
            final text = (data as Map<String, dynamic>)['text'] as String;
            return Text(text, textDirection: TextDirection.ltr);
          },
    );

    final catalog = Catalog([testCatalogItem]);

    test('schema generates correctly', () {
      final schema = catalog.schema;

      expect(schema, isA<ObjectSchema>());
      final properties = (schema as ObjectSchema).properties!;
      expect(properties.containsKey('root'), isTrue);
      expect(properties.containsKey('widgets'), isTrue);

      final widgetsSchema = properties['widgets']! as ListSchema;
      final widgetSchema = widgetsSchema.items! as ObjectSchema;
      final widgetProperties = widgetSchema.properties!;
      expect(widgetProperties.containsKey('id'), isTrue);
      expect(widgetProperties.containsKey('widget'), isTrue);

      final widgetPropertySchema = widgetProperties['widget']!;
      expect(widgetPropertySchema.anyOf, isNotNull);
      expect(widgetPropertySchema.anyOf!.length, 1);

      final testWidgetSchema = widgetPropertySchema.anyOf![0];
      expect(
        (testWidgetSchema as ObjectSchema).properties?.containsKey(
          'TestWidget',
        ),
        isTrue,
      );
    });

    testWidgets('buildWidget builds a known widget', (
      WidgetTester tester,
    ) async {
      final data = {
        'id': 'widget1',
        'widget': {
          'TestWidget': {'text': 'Hello'},
        },
      };

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            final widget = catalog.buildWidget(
              data,
              (id) => const SizedBox(),
              (event) {},
              context,
              {},
            );
            expect(widget, isA<Text>());
            expect((widget as Text).data, 'Hello');
            return widget;
          },
        ),
      );
    });

    testWidgets('buildWidget handles unknown widget', (
      WidgetTester tester,
    ) async {
      final data = {
        'id': 'widget1',
        'widget': {
          'UnknownWidget': {'text': 'Hello'},
        },
      };

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            final widget = catalog.buildWidget(
              data,
              (id) => const SizedBox(),
              (event) {},
              context,
              {},
            );
            expect(widget, isA<Container>());
            return widget;
          },
        ),
      );
    });
  });
}
