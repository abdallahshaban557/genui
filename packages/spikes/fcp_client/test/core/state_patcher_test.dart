// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fcp_client/src/core/data_type_validator.dart';
import 'package:fcp_client/src/core/fcp_state.dart';
import 'package:fcp_client/src/core/state_patcher.dart';
import 'package:fcp_client/src/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StatePatcher', () {
    late FcpState state;
    late StatePatcher patcher;

    setUp(() {
      state = FcpState(
        <String, Object?>{
          'user': <String, Object>{
            'name': 'Alice',
            'email': 'alice@example.com',
            'details': <String, int>{'level': 5, 'points': 100},
          },
          'tags': <String>['a', 'b'],
          'products': <Map<String, Object>>[
            <String, Object>{'sku': 'abc-123', 'name': 'Gadget', 'price': 30.0},
            <String, Object>{'sku': 'def-456', 'name': 'Widget', 'price': 40.0},
          ],
          'config': <String, String>{'setting': 'value'},
        },
        validator: DataTypeValidator(),
        catalog: WidgetCatalog.fromMap(<String, Object?>{
          'catalogVersion': '1.0.0',
          'items': <String, Object?>{},
          'dataTypes': <String, Object?>{},
        }),
      );
      patcher = StatePatcher();
    });

    test('applies a "replace" operation correctly', () {
      final StateUpdate update = StateUpdate(
        operations: <StateOperation>[
          PatchOperation(
            patch: PatchObject(op: 'replace', path: '/user/name', value: 'Bob'),
          ),
        ],
      );

      patcher.apply(state, update);

      expect(state.getValue('user.name'), 'Bob');
    });

    test('applies an "add" operation to a map', () {
      final StateUpdate update = StateUpdate(
        operations: <StateOperation>[
          PatchOperation(
            patch: PatchObject(op: 'add', path: '/user/age', value: 30),
          ),
        ],
      );

      patcher.apply(state, update);

      expect(state.getValue('user.age'), 30);
    });

    test('applies a "remove" operation from a map', () {
      final StateUpdate update = StateUpdate(
        operations: <StateOperation>[
          PatchOperation(
            patch: PatchObject(op: 'remove', path: '/user/email'),
          ),
        ],
      );

      patcher.apply(state, update);

      expect(state.getValue('user.email'), isNull);
    });

    test('applies a "listAppend" operation', () {
      final StateUpdate update = StateUpdate(
        operations: <StateOperation>[
          const ListAppendOperation(
            path: '/tags',
            items: <Map<String, Object?>>[
              <String, Object?>{'value': 'c'},
              <String, Object?>{'value': 'd'},
            ],
          ),
        ],
      );
      patcher.apply(state, update);
      expect(state.getValue('tags'), <Object>[
        'a',
        'b',
        'c',
        'd',
      ]);
    });

    test('applies a "listRemove" operation', () {
      final StateUpdate update = StateUpdate(
        operations: <StateOperation>[
          const ListRemoveOperation(
            path: '/products',
            itemKey: 'sku',
            keys: <Object?>['abc-123'],
          ),
        ],
      );
      patcher.apply(state, update);
      final List<Object?> products =
          state.getValue('products') as List<Object?>;
      expect(products.length, 1);
      expect((products[0] as Map<String, Object?>)['sku'], 'def-456');
    });

    test('applies a "listUpdate" operation', () {
      final StateUpdate update = StateUpdate(
        operations: <StateOperation>[
          const ListUpdateOperation(
            path: '/products',
            itemKey: 'sku',
            items: <Map<String, Object?>>[
              <String, Object?>{
                'sku': 'abc-123',
                'name': 'Updated Gadget',
                'price': 35.0,
              },
            ],
          ),
        ],
      );
      patcher.apply(state, update);
      final List<Object?> products =
          state.getValue('products') as List<Object?>;
      final Map<String, Object?> item =
          products.firstWhere(
                (Object? p) => (p as Map<String, Object?>)['sku'] == 'abc-123',
              )
              as Map<String, Object?>;
      expect(item['name'], 'Updated Gadget');
      expect(item['price'], 35.0);
    });

    test('applies patch to a deeply nested property', () {
      final StateUpdate update = StateUpdate(
        operations: <StateOperation>[
          PatchOperation(
            patch: PatchObject(
              op: 'replace',
              path: '/user/details/points',
              value: 150,
            ),
          ),
        ],
      );
      patcher.apply(state, update);
      expect(state.getValue('user.details.points'), 150);
    });

    test('applies multiple operations', () {
      final StateUpdate update = StateUpdate(
        operations: <StateOperation>[
          PatchOperation(
            patch: PatchObject(
              op: 'replace',
              path: '/user/email',
              value: 'new@example.com',
            ),
          ),
          PatchOperation(
            patch: PatchObject(op: 'add', path: '/user/age', value: 30),
          ),
        ],
      );

      patcher.apply(state, update);

      final Map<String, Object?> user =
          state.getValue('user') as Map<String, Object?>;
      expect(user['email'], 'new@example.com');
      expect(user['age'], 30);
    });

    test('notifies listeners after applying patch', () {
      bool notified = false;
      state.addListener(() {
        notified = true;
      });

      final StateUpdate update = StateUpdate(
        operations: <StateOperation>[
          PatchOperation(
            patch: PatchObject(
              op: 'replace',
              path: '/user/name',
              value: 'Charlie',
            ),
          ),
        ],
      );

      patcher.apply(state, update);

      expect(notified, isTrue);
    });
  });
}
