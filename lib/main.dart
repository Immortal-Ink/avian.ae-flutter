import 'dart:async';

import 'package:avian_terminal/archive_manager.dart';
import 'package:avian_terminal/command.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:padded/padded.dart';
import 'package:rxdart/rxdart.dart';
import 'package:toxic/toxic.dart';
import 'package:typewritertext/typewritertext.dart';

ArchiveManager archiveManager =
    ArchiveManager(asset: "assets/assets.zip", password: null);

BehaviorSubject<String> historyPipe = BehaviorSubject();
BehaviorSubject<String> dirStream = BehaviorSubject();

void main() => runApp(Terminal());
String lastUser = "guest";

class Terminal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark()
          .copyWith(
              colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.cyan,
          ))
          .copyWith(
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: "Font"),
          ),
      home: Screen(),
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
        Container(
          height: 50,
        ),
        Expanded(
          child: Row(
            children: [
              Container(
                width: 80,
              ),
              Expanded(child: TerminalView())
            ],
          ),
        ),
        Gap(50),
        Container(
          height: 21,
          color: Colors.cyan.withOpacity(0.5),
          child: Row(children: [
            Gap(14),
            dirStream.build((dir) => Text(dir.isEmpty ? "/" : dir)),
            Spacer(),
            Text(lastUser),
            Gap(14)
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
      body: Column(
        children: [
          Expanded(
              child: PaddingAll(
            padding: 0,
            child: ListView(
              children: [
                ...history.map((e) => TerminalText(text: e, user: widget.user)),
                Gap(kIsWeb ? 3 : 4),
                if (ready)
                  TextField(
                    autofocus: true,
                    controller: controller,
                    focusNode: f,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.cyan),
                    decoration: InputDecoration(
                        isDense: true,
                        prefix: Text("${widget.user} \u00BB "),
                        prefixStyle: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.cyan),
                        contentPadding: EdgeInsets.only(bottom: 4),
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
                      history.add("${widget.user} \u00BB ${s.trim()}");

                      controller.clear();
                      history.addAll(execute(s.trim()));
                    }),
                  )
              ],
            ),
          )),
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
            color: text.startsWith("${user} \u00BB")
                ? Colors.cyan
                : Colors.blueGrey));
    if (!text.startsWith("${user} \u00BB") && !false) {
      return TypeWriterText(text: w, maintainSize: false, duration: 16.ms);
    }
    return w;
  }
}
