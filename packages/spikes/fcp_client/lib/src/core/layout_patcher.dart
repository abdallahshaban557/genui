// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// A service that applies layout updates to a map of [LayoutNode]s.
class LayoutPatcher {
  /// Applies a [LayoutUpdate] payload to the given [nodeMap].
  ///
  /// The operations (`add`, `remove`, `replace`) are applied sequentially.
  void apply(Map<String, LayoutNode> nodeMap, LayoutUpdate update) {
    for (final LayoutOperation operation in update.operations) {
      switch (operation.op) {
        case 'add':
          _handleAdd(nodeMap, operation);
          break;
        case 'remove':
          _handleRemove(nodeMap, operation);
          break;
        case 'replace':
          _handleReplace(nodeMap, operation);
          break;
        default:
          // In a real-world scenario, you might want to log this.
          debugPrint(
            'FCP Warning: Ignoring unknown layout operation "${operation.op}".',
          );
          break;
      }
    }
  }

  void _handleAdd(Map<String, LayoutNode> nodeMap, LayoutOperation operation) {
    final List<LayoutNode>? nodes = operation.nodes;
    if (nodes == null || nodes.isEmpty) {
      return;
    }

    for (final LayoutNode node in nodes) {
      nodeMap[node.id] = node;
    }

    final String? targetNodeId = operation.targetNodeId;
    final String? targetProperty = operation.targetProperty;

    if (targetNodeId == null || targetProperty == null) {
      return;
    }

    final LayoutNode? targetNode = nodeMap[targetNodeId];
    if (targetNode == null) {
      debugPrint(
        'FCP Warning: Target node "$targetNodeId" not found for "add" '
        'operation.',
      );
      return;
    }

    final List<String> newNodeIds = nodes.map((LayoutNode n) => n.id).toList();
    final Map<String, Object?> currentProperties = Map<String, Object?>.from(
      targetNode.properties ?? <dynamic, dynamic>{},
    );
    final Object? currentChildren = currentProperties[targetProperty];

    final List<String> newChildrenIds;
    if (currentChildren is List) {
      newChildrenIds = <String>[...currentChildren.cast<String>(), ...newNodeIds];
    } else if (currentChildren is String) {
      newChildrenIds = <String>[currentChildren, ...newNodeIds];
    } else {
      newChildrenIds = newNodeIds;
    }

    currentProperties[targetProperty] = newChildrenIds;

    final LayoutNode newTargetNode = LayoutNode(
      id: targetNode.id,
      type: targetNode.type,
      properties: currentProperties,
      bindings: targetNode.bindings,
      itemTemplate: targetNode.itemTemplate,
    );

    nodeMap[targetNodeId] = newTargetNode;
  }

  void _handleRemove(
    Map<String, LayoutNode> nodeMap,
    LayoutOperation operation,
  ) {
    final List<String>? ids = operation.nodeIds;
    if (ids == null || ids.isEmpty) {
      return;
    }

    for (final String id in ids) {
      nodeMap.remove(id);
    }
  }

  void _handleReplace(
    Map<String, LayoutNode> nodeMap,
    LayoutOperation operation,
  ) {
    final List<LayoutNode>? nodes = operation.nodes;
    if (nodes == null || nodes.isEmpty) {
      return;
    }

    for (final LayoutNode node in nodes) {
      if (nodeMap.containsKey(node.id)) {
        nodeMap[node.id] = node;
      }
    }
  }
}
