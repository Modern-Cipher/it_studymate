import 'package:flutter/foundation.dart';

import '../models/resource.dart';
import '../services/resource_service.dart';

class ResourceProvider extends ChangeNotifier {
  ResourceProvider({ResourceService? service})
    : _service = service ?? ResourceService.instance;

  final ResourceService _service;

  List<Resource> _items = <Resource>[];
  int? _userId;
  bool _loading = false;

  List<Resource> get items => List<Resource>.unmodifiable(_items);
  bool get loading => _loading;

  Future<void> load(int userId) async {
    _userId = userId;
    _loading = true;
    notifyListeners();
    _items = await _service.forUser(userId);
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    final int? id = _userId;
    if (id == null) return;
    _items = await _service.forUser(id);
    notifyListeners();
  }

  Future<void> add(Resource resource) async {
    await _service.insert(resource);
    await refresh();
  }

  Future<void> remove(Resource resource) async {
    await _service.delete(resource);
    await refresh();
  }
}
