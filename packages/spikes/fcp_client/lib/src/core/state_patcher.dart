// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'fcp_state.dart';

/// A service that applies state updates to the [FcpState].
class StatePatcher {
  /// Applies a [StateUpdate] payload to the given [state].
  ///
  /// The operations are applied sequentially. If any operation fails, the
  /// state is not updated.
  void apply(FcpState state, StateUpdate update) {
    final Map<String, Object?> currentState = Map<String, Object?>.from(
      state.state,
    );
    for (final StateOperation operation in update.operations) {
      switch (operation) {
        case PatchOperation():
          _handlePatch(currentState, operation);
          break;
        case ListAppendOperation():
          _handleListAppend(currentState, operation);
          break;
        case ListRemoveOperation():
          _handleListRemove(currentState, operation);
          break;
        case ListUpdateOperation():
          _handleListUpdate(currentState, operation);
          break;
      }
    }
    state.state = currentState;
  }

  /// Resolves a path and returns the parent container and the final segment
  /// key.
  ///
  /// For example, for a path `/user/details/points`, this would return the
  /// `details` map as the container and the string "points" as the segment.
  ({Object? container, String segment}) _resolvePath(
    Map<String, Object?> root,
    String path,
  ) {
    final List<String> parts = path
        .split('/')
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return (container: null, segment: '');
    }

    Object? currentLevel = root;
    for (int i = 0; i < parts.length - 1; i++) {
      final String part = parts[i];
      if (currentLevel == null) {
        break;
      }

      if (currentLevel is Map<String, Object?>) {
        currentLevel = currentLevel[part];
      } else if (currentLevel is List && part.contains(':')) {
        final List<String> kv = part.split(':');
        final String key = kv[0];
        final String value = kv[1];
        currentLevel = currentLevel.firstWhere(
          (Object? item) => item is Map && item[key] == value,
          orElse: () => null,
        );
      } else {
        currentLevel = null;
        break;
      }
    }
    return (container: currentLevel, segment: parts.last);
  }

  void _handlePatch(Map<String, Object?> state, PatchOperation operation) {
    final PatchObject patch = operation.patch;
    final ({Object? container, String segment}) result = _resolvePath(
      state,
      patch.path,
    );

    final Object? container = result.container;
    if (container is! Map<String, Object?>) {
      debugPrint(
        'FCP Warning: Could not find container for path ${patch.path}',
      );
      return;
    }

    final String key = result.segment;
    switch (patch.op) {
      case 'add':
      case 'replace':
        container[key] = patch.value;
        break;
      case 'remove':
        container.remove(key);
        break;
    }
  }

  void _handleListAppend(
    Map<String, Object?> state,
    ListAppendOperation operation,
  ) {
    final ({Object? container, String segment}) result = _resolvePath(
      state,
      operation.path,
    );
    final Object? container = result.container;
    if (container is! Map<String, Object?> && container is! List) {
      debugPrint(
        'FCP Warning: Could not find container for path ${operation.path}',
      );
      return;
    }

    if (container is List) {
      (container as List<Object?>).addAll(operation.items);
      return;
    }

    final Object? list = (container as Map<String, Object?>)[result.segment];
    if (list is! List) {
      debugPrint(
        'FCP Warning: Target for listAppend at path ${operation.path} is not '
        'a list',
      );
      return;
    }
    if (list is List<String>) {
      list.addAll(operation.items.map((i) => i['value'] as String));
    } else {
      (list as List<Object?>).addAll(operation.items.toList());
    }
  }

  void _handleListRemove(
    Map<String, Object?> state,
    ListRemoveOperation operation,
  ) {
    final ({Object? container, String segment}) result = _resolvePath(
      state,
      operation.path,
    );
    final Object? container = result.container;
    if (container is! Map<String, Object?> && container is! List) {
      debugPrint(
        'FCP Warning: Could not find container for path ${operation.path}',
      );
      return;
    }

    if (container is List) {
      container.removeWhere(
        (Object? item) =>
            item is Map && operation.keys.contains(item[operation.itemKey]),
      );
      return;
    }

    final Object? list = (container as Map<String, Object?>)[result.segment];
    if (list is! List) {
      debugPrint(
        'FCP Warning: Target for listRemove at path ${operation.path} is not '
        'a list',
      );
      return;
    }

    list.removeWhere(
      (Object? item) =>
          item is Map && operation.keys.contains(item[operation.itemKey]),
    );
  }

  void _handleListUpdate(
    Map<String, Object?> state,
    ListUpdateOperation operation,
  ) {
    final ({Object? container, String segment}) result = _resolvePath(
      state,
      operation.path,
    );
    final Object? container = result.container;
    if (container is! Map<String, Object?> && container is! List) {
      debugPrint(
        'FCP Warning: Could not find container for path ${operation.path}',
      );
      return;
    }

    if (container is List) {
      for (final Map<String, Object?> item in operation.items) {
        final int index = container.indexWhere(
          (Object? element) =>
              element is Map &&
              element[operation.itemKey] == item[operation.itemKey],
        );
        if (index != -1) {
          (container as List<Object?>)[index] = item;
        }
      }
      return;
    }

    final Object? list = (container as Map<String, Object?>)[result.segment];
    if (list is! List) {
      debugPrint(
        'FCP Warning: Target for listUpdate at path ${operation.path} is not '
        'a list',
      );
      return;
    }

    for (final Map<String, Object?> item in operation.items) {
      final int index = list.indexWhere(
        (Object? element) =>
            element is Map &&
            element[operation.itemKey] == item[operation.itemKey],
      );
      if (index != -1) {
        list.removeAt(index);
        list.insert(index, Map<String, Object>.from(item));
      }
    }
  }
}
