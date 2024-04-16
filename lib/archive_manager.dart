import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:fast_log/fast_log.dart';
import 'package:flutter/services.dart';
import 'package:precision_stopwatch/precision_stopwatch.dart';

class ArchiveManager {
  final String? password;
  final String asset;
  late Archive archive;

  ArchiveManager({required this.asset, this.password});

  Iterable<String> lsDirLocal(String path) {
    path = path.startsWith("/") ? path.substring(1) : path;

    if (path == "*") {
      return paths;
    }

    return (path.trim().isNotEmpty
            ? paths.where((e) => e.startsWith(path) && e.length > path.length)
            : paths.where((e) => !e.contains("/")))
        .map((e) => e.substring(path.length))
        .map((e) => e.startsWith("/") ? e.substring(1) : e)
        .where((e) => !e.contains("/") && !e.startsWith("."));
  }

  bool hasDir(String path) {
    if (path.isEmpty) {
      return true;
    }

    path = path.trim() == "/" ? "" : path;
    path = path.endsWith("/") ? path.substring(0, path.length - 1) : path;
    path = path.startsWith("/") ? path.substring(1) : path;
    path = path.trim();
    path = path.split("/").where((e) => e.trim().isNotEmpty).join("/");

    return paths.any((e) => e.startsWith(path));
  }

  List<String> get paths => pathGroups.map((e) => e.join("/")).map((e) {
        if (e.endsWith("/")) {
          return e.substring(0, e.length - 1);
        }

        return e;
      }).toList();

  List<List<String>> get pathGroups =>
      archive.files.map((e) => e.name.split("/")).toList();

  Future<void> populatePaths() async {
    PrecisionStopwatch p = PrecisionStopwatch.start();
    ByteData bytes = await rootBundle.load('assets/assets.zip');
    archive = ZipDecoder()
        .decodeBytes(bytes.buffer.asUint8List(), password: password);
    verbose("Loaded in ${p.getMilliseconds()}ms");
  }

  Future<String?> readText(String path) async {
    Uint8List? s = await read(path);

    if (s != null) {
      return utf8.decode(s);
    }

    return null;
  }

  Future<Uint8List?> read(String path) async {
    ArchiveFile? f =
        archive.files.where((element) => element.name == path).firstOrNull;

    if (f != null) {
      OutputStream out = OutputStream();
      f.writeContent(out);
      return Uint8List.fromList(out.getBytes());
    }

    return null;
  }
}
