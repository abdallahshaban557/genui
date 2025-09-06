// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fcp_client/src/core/binding_processor.dart';
import 'package:fcp_client/src/core/data_type_validator.dart';
import 'package:fcp_client/src/core/fcp_state.dart';
import 'package:fcp_client/src/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BindingProcessor', () {
    late FcpState state;
    late BindingProcessor processor;

    setUp(() {
      state = FcpState(
        <String, Object?>{
          'user': <String, Object>{'name': 'Alice', 'isPremium': true},
          'status': 'active',
          'count': 42,
        },
        validator: DataTypeValidator(),
        catalog: WidgetCatalog.fromMap(<String, Object?>{
          'catalogVersion': '1.0.0',
          'dataTypes': <String, Object?>{},
          'items': <String, Map<String, Map<String, Map<String, String>>>>{
            'Text': <String, Map<String, Map<String, String>>>{
              'properties': <String, Map<String, String>>{
                'text': <String, String>{'type': 'string'},
                'value': <String, String>{'type': 'int'},
                'age': <String, String>{'type': 'int'},
              },
            },
          },
        }),
      );
      processor = BindingProcessor(state);
    });

    test('resolves simple path binding', () {
      final Binding binding = Binding.fromMap(<String, Object?>{'path': 'user.name'});
      final Map<String, Object?> result = processor.process(
        LayoutNode.fromMap(<String, Object?>{
          'id': 'w1',
          'type': 'Text',
          'bindings': <String, Map<String, Object?>>{'text': binding.toJson()},
        }),
      );
      expect(result['text'], 'Alice');
    });

    test('handles format transformer', () {
      final Binding binding = Binding.fromMap(<String, Object?>{
        'path': 'user.name',
        'format': 'Welcome, {}!',
      });
      final Map<String, Object?> result = processor.process(
        LayoutNode.fromMap(<String, Object?>{
          'id': 'w1',
          'type': 'Text',
          'bindings': <String, Map<String, Object?>>{'text': binding.toJson()},
        }),
      );
      expect(result['text'], 'Welcome, Alice!');
    });

    test('handles condition transformer (true case)', () {
      final Binding binding = Binding.fromMap(<String, Object?>{
        'path': 'user.isPremium',
        'condition': <String, String>{'ifValue': 'Premium User', 'elseValue': 'Standard User'},
      });
      final Map<String, Object?> result = processor.process(
        LayoutNode.fromMap(<String, Object?>{
          'id': 'w1',
          'type': 'Text',
          'bindings': <String, Map<String, Object?>>{'text': binding.toJson()},
        }),
      );
      expect(result['text'], 'Premium User');
    });

    test('handles condition transformer (false case)', () {
      state.state = <String, Object?>{
        'user': <String, bool>{'isPremium': false},
      };
      final Binding binding = Binding.fromMap(<String, Object?>{
        'path': 'user.isPremium',
        'condition': <String, String>{'ifValue': 'Premium User', 'elseValue': 'Standard User'},
      });
      final Map<String, Object?> result = processor.process(
        LayoutNode.fromMap(<String, Object?>{
          'id': 'w1',
          'type': 'Text',
          'bindings': <String, Map<String, Object?>>{'text': binding.toJson()},
        }),
      );
      expect(result['text'], 'Standard User');
    });

    test('handles map transformer (found case)', () {
      final Binding binding = Binding.fromMap(<String, Object?>{
        'path': 'status',
        'map': <String, Object>{
          'mapping': <String, String>{'active': 'Online', 'inactive': 'Offline'},
          'fallback': 'Unknown',
        },
      });
      final Map<String, Object?> result = processor.process(
        LayoutNode.fromMap(<String, Object?>{
          'id': 'w1',
          'type': 'Text',
          'bindings': <String, Map<String, Object?>>{'text': binding.toJson()},
        }),
      );
      expect(result['text'], 'Online');
    });

    test('handles map transformer (fallback case)', () {
      state.state = <String, Object?>{'status': 'away'};
      final Binding binding = Binding.fromMap(<String, Object?>{
        'path': 'status',
        'map': <String, Object>{
          'mapping': <String, String>{'active': 'Online', 'inactive': 'Offline'},
          'fallback': 'Unknown',
        },
      });
      final Map<String, Object?> result = processor.process(
        LayoutNode.fromMap(<String, Object?>{
          'id': 'w1',
          'type': 'Text',
          'bindings': <String, Map<String, Object?>>{'text': binding.toJson()},
        }),
      );
      expect(result['text'], 'Unknown');
    });

    test('handles map transformer with no fallback (miss case)', () {
      state.state = <String, Object?>{'status': 'away'};
      final Binding binding = Binding.fromMap(<String, Object?>{
        'path': 'status',
        'map': <String, Map<String, String>>{
          'mapping': <String, String>{'active': 'Online', 'inactive': 'Offline'},
        },
      });
      final Map<String, Object?> result = processor.process(
        LayoutNode.fromMap(<String, Object?>{
          'id': 'w1',
          'type': 'Text',
          'bindings': <String, Map<String, Object?>>{'text': binding.toJson()},
        }),
      );
      expect(result['text'], isNull);
    });

    test('returns raw value when no transformer is present', () {
      final Binding binding = Binding.fromMap(<String, Object?>{'path': 'count'});
      final Map<String, Object?> result = processor.process(
        LayoutNode.fromMap(<String, Object?>{
          'id': 'w1',
          'type': 'Text',
          'bindings': <String, Map<String, Object?>>{'value': binding.toJson()},
        }),
      );
      expect(result['value'], 42);
    });

    test('returns empty map for empty bindings', () {
      final Map<String, Object?> result = processor.process(
        LayoutNode.fromMap(<String, Object?>{
          'id': 'w1',
          'type': 'Text',
          'bindings': <String, Object?>{},
        }),
      );
      expect(result, isEmpty);
    });

    test('returns empty map for null bindings', () {
      final Map<String, Object?> result = processor.process(
        LayoutNode.fromMap(<String, Object?>{'id': 'w1', 'type': 'Text'}),
      );
      expect(result, isEmpty);
    });

    test(
      'returns default value for a path that does not exist in the state',
      () {
        final Binding binding = Binding.fromMap(<String, Object?>{'path': 'user.age'});
        final Map<String, Object?> result = processor.process(
          LayoutNode.fromMap(<String, Object?>{
            'id': 'w1',
            'type': 'Text',
            'bindings': <String, Map<String, Object?>>{'age': binding.toJson()},
          }),
        );
        expect(result['age'], isNull);
      },
    );

    group('Scoped Bindings', () {
      final Map<String, Object> scopedData = <String, Object>{'title': 'Scoped Title', 'value': 100};

      test('resolves item path from scoped data', () {
        final Binding binding = Binding.fromMap(<String, Object?>{'path': 'item.title'});
        final Map<String, Object?> result = processor.processScoped(
          LayoutNode.fromMap(<String, Object?>{
            'id': 'w1',
            'type': 'Text',
            'bindings': <String, Map<String, Object?>>{'text': binding.toJson()},
          }),
          scopedData,
        );
        expect(result['text'], 'Scoped Title');
      });

      test('resolves global path even when scoped data is present', () {
        final Binding binding = Binding.fromMap(<String, Object?>{'path': 'user.name'});
        final Map<String, Object?> result = processor.processScoped(
          LayoutNode.fromMap(<String, Object?>{
            'id': 'w1',
            'type': 'Text',
            'bindings': <String, Map<String, Object?>>{'text': binding.toJson()},
          }),
          scopedData,
        );
        expect(result['text'], 'Alice');
      });

      test('applies transformer to scoped data', () {
        final Binding binding = Binding.fromMap(<String, Object?>{
          'path': 'item.value',
          'format': 'Value: {}',
        });
        final Map<String, Object?> result = processor.processScoped(
          LayoutNode.fromMap(<String, Object?>{
            'id': 'w1',
            'type': 'Text',
            'bindings': <String, Map<String, Object?>>{'text': binding.toJson()},
          }),
          scopedData,
        );
        expect(result['text'], 'Value: 100');
      });

      test('returns default value for item path when scoped data is empty', () {
        final Binding binding = Binding.fromMap(<String, Object?>{'path': 'item.title'});
        final Map<String, Object?> result = processor.processScoped(
          LayoutNode.fromMap(<String, Object?>{
            'id': 'w1',
            'type': 'Text',
            'bindings': <String, Map<String, Object?>>{'text': binding.toJson()},
          }),
          <String, Object?>{},
        );
        expect(result['text'], isNull);
      });
    });
  });
}
