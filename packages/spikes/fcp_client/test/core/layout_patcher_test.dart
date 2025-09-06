// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fcp_client/src/core/layout_patcher.dart';
import 'package:fcp_client/src/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LayoutPatcher', () {
    late LayoutPatcher patcher;
    late Map<String, LayoutNode> nodeMap;

    setUp(() {
      patcher = LayoutPatcher();
      nodeMap = <String, LayoutNode>{
        'root': LayoutNode.fromMap(<String, Object?>{
          'id': 'root',
          'type': 'Container',
          'properties': <String, String>{'child': 'child1'},
        }),
        'child1': LayoutNode.fromMap(<String, Object?>{
          'id': 'child1',
          'type': 'Text',
          'properties': <String, String>{'text': 'Hello'},
        }),
        'child2': LayoutNode.fromMap(<String, Object?>{
          'id': 'child2',
          'type': 'Text',
          'properties': <String, String>{'text': 'World'},
        }),
      };
    });

    test('handles "add" operation', () {
      final LayoutUpdate add = LayoutUpdate.fromMap(<String, Object?>{
        'operations': <Map<String, Object>>[
          <String, Object>{
            'op': 'add',
            'nodes': <Map<String, String>>[
              <String, String>{'id': 'child3', 'type': 'Button'},
            ],
          },
        ],
      });

      patcher.apply(nodeMap, add);

      expect(nodeMap.containsKey('child3'), isTrue);
      expect(nodeMap['child3']!.type, 'Button');
    });

    test('handles "remove" operation', () {
      final LayoutUpdate remove = LayoutUpdate.fromMap(<String, Object?>{
        'operations': <Map<String, Object>>[
          <String, Object>{
            'op': 'remove',
            'nodeIds': <String>['child1', 'child2'],
          },
        ],
      });

      patcher.apply(nodeMap, remove);

      expect(nodeMap.containsKey('child1'), isFalse);
      expect(nodeMap.containsKey('child2'), isFalse);
      expect(nodeMap.containsKey('root'), isTrue);
    });

    test('handles "replace" operation', () {
      final LayoutUpdate replace = LayoutUpdate.fromMap(<String, Object?>{
        'operations': <Map<String, Object>>[
          <String, Object>{
            'op': 'replace',
            'nodes': <Map<String, Object>>[
              <String, Object>{
                'id': 'child1',
                'type': 'Text',
                'properties': <String, String>{'text': 'Goodbye'},
              },
            ],
          },
        ],
      });

      patcher.apply(nodeMap, replace);

      expect(nodeMap['child1']!.properties!['text'], 'Goodbye');
    });

    test('handles multiple operations in sequence', () {
      final LayoutUpdate update = LayoutUpdate.fromMap(<String, Object?>{
        'operations': <Map<String, Object>>[
          <String, Object>{
            'op': 'remove',
            'nodeIds': <String>['child2'],
          },
          <String, Object>{
            'op': 'replace',
            'nodes': <Map<String, Object>>[
              <String, Object>{
                'id': 'child1',
                'type': 'Text',
                'properties': <String, String>{'text': 'Updated'},
              },
            ],
          },
          <String, Object>{
            'op': 'add',
            'nodes': <Map<String, String>>[
              <String, String>{'id': 'new_child', 'type': 'Icon'},
            ],
          },
        ],
      });

      patcher.apply(nodeMap, update);

      expect(nodeMap.containsKey('child2'), isFalse);
      expect(nodeMap['child1']!.properties!['text'], 'Updated');
      expect(nodeMap.containsKey('new_child'), isTrue);
    });

    test('ignores unknown operations gracefully', () {
      final LayoutUpdate update = LayoutUpdate.fromMap(<String, Object?>{
        'operations': <Map<String, String>>[
          <String, String>{'op': 'unknown_op'},
        ],
      });

      // Should not throw
      patcher.apply(nodeMap, update);
      expect(nodeMap.length, 3);
    });

    test('does not fail on empty or null node/id lists', () {
      final LayoutUpdate update = LayoutUpdate.fromMap(<String, Object?>{
        'operations': <Map<String, Object?>>[
          <String, Object>{'op': 'add', 'nodes': <Map<String, Object?>>[]},
          <String, String?>{'op': 'remove', 'nodeIds': null},
          <String, String?>{'op': 'replace', 'nodes': null},
        ],
      });

      // Should not throw
      patcher.apply(nodeMap, update);
      expect(nodeMap.length, 3);
    });
    test('does not throw when updating a non-existent node', () {
      final LayoutUpdate replace = LayoutUpdate.fromMap(<String, Object?>{
        'operations': <Map<String, Object>>[
          <String, Object>{
            'op': 'replace',
            'nodes': <Map<String, String>>[
              <String, String>{'id': 'non_existent', 'type': 'Text'},
            ],
          },
        ],
      });

      // Should not throw and should not add the node
      patcher.apply(nodeMap, replace);
      expect(nodeMap.containsKey('non_existent'), isFalse);
      expect(nodeMap.length, 3);
    });
  });
}
