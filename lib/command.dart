// registry
import 'package:avian_terminal/main.dart';
import 'package:sprintf/sprintf.dart';

String dir = "";

List<Command> commands = [
  HelpCommand(),
  EchoCommand(),
  WhoAmICommand(),
  CdCommand(),
  LsCommand(),
  OpenCommand(),
];
Iterable<String> execute(String l) sync* {
  List<String> a =
      l.split(" ").where((element) => element.trim().isNotEmpty).toList();
  String cmd = a.removeAt(0);
  for (Command c in commands) {
    if (c.matches(cmd)) {
      for (var map in c.onCommand(a)) {
        yield map['text'];
      }
      return;
    }
  }
  yield "${cmd.split(' ')[0]} is an unrecognized command, use `help` for a list of available commands.";
}

// command start
class EchoCommand extends Command {
  EchoCommand() : super("echo", "Repeats the input back to you");

  @override
  Iterable<Map<String, dynamic>> onCommand(List<String> a) sync* {
    yield {'text': a.join(" ")};
  }
}
//command end

// Help command
class HelpCommand extends Command {
  HelpCommand()
      : super("help", "Shows a list of all commands and their descriptions",
            aliases: ["?", "howto"]);

  @override
  Iterable<Map<String, dynamic>> onCommand(List<String> a) sync* {
    for (Command c in commands) {
      yield {
        'text': sprintf(
            "%-15s %-15s %-30s", [c.name, c.aliases.join(', '), c.description]),
      };
    }
  }
}

// cd command
class CdCommand extends Command {
  CdCommand() : super("cd", "Change directory");

  @override
  Iterable<Map<String, dynamic>> onCommand(List<String> a) sync* {
    String np = "$dir/${a[0]}";

    if (a[0] == "..") {
      if (dir.contains("/")) {
        List<String> g = dir.split("/").reversed.toList();
        g.removeAt(0);
        dir = g.reversed.join("/");
        dirStream.add(dir);
        yield {'text': "In $dir"};
      } else {
        yield {'text': "Can't go up."};
      }

      return;
    } else if (a[0].startsWith("/")) {
      if (archiveManager.hasDir(a[0].substring(1))) {
        dir = a[0].substring(1);
        dirStream.add(dir);
        yield {'text': "In $dir"};
      } else {
        yield {"text": "$np not a directory"};
      }
      return;
    } else if (archiveManager.hasDir(np)) {
      dir = np;
      dirStream.add(dir);
      yield {'text': "In $dir"};
    } else {
      yield {"text": "$np not a directory"};
    }
  }
}

// ls command
class LsCommand extends Command {
  LsCommand() : super("ls", "List directory contents");

  @override
  Iterable<Map<String, dynamic>> onCommand(List<String> a) sync* {
    yield {
      'text': archiveManager
          .lsDirLocal(a.isNotEmpty && a[0] == "*" ? "*" : dir)
          .join("\n")
    };
  }
}

// open command
class OpenCommand extends Command {
  OpenCommand() : super("open", "Display file contents");

  @override
  Iterable<Map<String, dynamic>> onCommand(List<String> a) sync* {
    String f = a[0];

    f = f.startsWith("/") ? f : "$dir/$f";
    f = f.startsWith("/") ? f.substring(1) : f;
    yield {'text': "READING '$f'"};
    archiveManager.readText(f.substring(0)).then((value) {
      if (value != null) {
        for (String i in value.split("\n")) {
          historyPipe.add(i);
        }
      } else {
        historyPipe.add("Couldn't read file");
      }
    });
  }
}

// whoami command
class WhoAmICommand extends Command {
  WhoAmICommand() : super("whoami", "Shows the current user");

  @override
  Iterable<Map<String, dynamic>> onCommand(List<String> a) sync* {
    yield {'text': "you are currently logged in as $lastUser"};
  }
}

abstract class Command {
  final String name;
  final String description;
  final List<String> aliases;
  Command(this.name, this.description, {this.aliases = const []});
  bool matches(String q) =>
      name.toLowerCase() == q.toLowerCase() ||
      aliases.any((element) => element.toLowerCase() == q.toLowerCase());
  Iterable<Map<String, dynamic>> onCommand(List<String> a);
}
