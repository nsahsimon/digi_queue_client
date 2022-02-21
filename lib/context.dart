import 'package:flutter/material.dart';

class _Context {
  BuildContext _context;

  void updateContext(BuildContext newContext) {
    _context = newContext;
  }

  BuildContext get getContext {
    return _context;
  }
}

_Context myContext = _Context();