import 'dart:async';

import 'package:avian_terminal/archive_manager.dart';
import 'package:avian_terminal/command.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:rxdart/rxdart.dart';
import 'package:toxic/toxic.dart';
import 'package:typewritertext/typewritertext.dart';

ArchiveManager archiveManager =
    ArchiveManager(asset: "assets/assets.zip", password: null);

BehaviorSubject<String> historyPipe = BehaviorSubject();
// BehaviorSubject<String> dirStream = BehaviorSubject();
BehaviorSubject<String> dirStream = BehaviorSubject();
// String formatDirStream(String path) {
//   // Prepend the Unicode character to the string if it doesn't already start with it
//   if (!path.startsWith('\u2302 home')) {
//     path = '\u2302 home' + ' > ' + path;
//   }
//
//   // Replace all occurrences of '/'
//   path = path.replaceAll('/', ' > ');
//
//   return path;
// }

void main() => runApp(const Terminal());
String lastUser = "guest";

class Terminal extends StatelessWidget {
  const Terminal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark()
          .copyWith(
              colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.cyanAccent, // cursor color
          ))
          .copyWith(
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: "Font"),
          ),
      home: const Screen(),
    );
  }
}

class Screen extends StatelessWidget {
  const Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        // Top Bar
        Container(
          // color: Colors.red,
          height: 70,
        ),
        Expanded(
          child: Row(
            children: [
              // Left Bar
              Container(
                // color: Colors.blue,
                width: 70,
              ),
              const Expanded(child: TerminalView()),
              // Right Bar
              Container(
                // color: Colors.red,
                width: 70,
              )
            ],
          ),
        ),
        const Gap(50),
        // Bottom Bar
        Container(
          height: 28,
          color: Colors.cyan.withOpacity(0.5),
          child: Row(children: [
            const Gap(14),
            SvgPicture.asset(
              'assets/viper.svg',
              color: Colors.white, // Set the color of the SVG
              height: 16, // Set the height of the SVG
            ),
            const Gap(7),
            dirStream.build((dir) => Text(dir.isEmpty ? "/" : dir)),
            const Spacer(),
            Text(lastUser),
            const Gap(14)
          ]),
        )
      ],
    ));
  }
}

class TerminalView extends StatefulWidget {
  final String user;
  const TerminalView({super.key, this.user = "guest"});

  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView> {
  TextEditingController controller = TextEditingController();
  List<String> commandHistory = [];
  FocusNode f = FocusNode();
  bool ready = false;
  List<String> history = [];
  late StreamSubscription<String> sub;

  @override
  void initState() {
    sub = historyPipe.listen((e) {
      setState(() {
        history.add(e);
      });
    });
    // text to print on page load

    Future.delayed(Duration.zero).then((value) async {
      await delayText(
          "Welcome to the Aelorian Virtual Information Access Network. Operated by the Archive of the Ministry of Heritage.",
          960);
      await delayText("Version 0.1.38");
      await delayText("Loading Data...");
      await archiveManager.populatePaths();
      await delayText("System Status [Clear]");
      await delayText("Currently logged in as ${widget.user}");
      await delayText("");
      await delayText("Use `help` to see a list of commands.");
      setState(() {
        ready = true;
      });
    });

    super.initState();
  }

  Future<void> delayText(String text, [int t = 64]) async {
    if (!false) {
      await Future.delayed(t.ms);
    }

    setState(() {
      history.add(text);
    });
    if (!false) {
      await Future.delayed((16 * text.length).ms);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ...history.map((e) => TerminalText(text: e, user: widget.user)),
          const Gap(kIsWeb ? 3 : 4),
          if (ready)
            RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (RawKeyEvent event) {
                if (event is RawKeyUpEvent &&
                    event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  if (commandHistory.isNotEmpty) {
                    controller.text = commandHistory.last;
                  }
                }
              },
              child: TextField(
                autofocus: true,
                controller: controller,
                focusNode: f,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white), // active text color
                decoration: InputDecoration(
                    isDense: true,
                    prefix: Text("${widget.user} \u0024 "),
                    prefixStyle: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.cyanAccent), // user color
                    contentPadding: const EdgeInsets.only(bottom: 4),
                    border: InputBorder.none),
                onSubmitted: (s) => setState(() {
                  lastUser = widget.user;
                  if (s.trim().isEmpty) {
                    f.requestFocus();
                    return;
                  }
                  if (s.trim().toLowerCase() == "cls") {
                    controller.clear();
                    history.clear();
                    return;
                  }
                  history.add("${widget.user} \u0024 ${s.trim()}");
                  commandHistory.add(s
                      .trim()); // Add the command to the commandHistory list for recall

                  controller.clear();
                  history.addAll(execute(s.trim()));
                }),
              ),
            )
        ],
      ),
    );
  }
}

class TerminalText extends StatelessWidget {
  final String text;
  final String user;
  const TerminalText({super.key, required this.text, required this.user});

  @override
  Widget build(BuildContext context) {
    Text w = Text(text,
        style: TextStyle(
            color: text.startsWith("$user \u0024")
                ? Colors.cyan // submitted command color
                : Colors.white.withOpacity(0.7)));
    if (!text.startsWith("$user \u0024") && !kDebugMode) {
      return TypeWriterText(text: w, maintainSize: false, duration: 16.ms);
    }
    return w;
  }
}
