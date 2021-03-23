import 'dart:io';
import 'package:perfcli/perfcli.dart' as perfcli;
import 'package:args/args.dart';
import 'package:perfcli/perfcli.dart';
import 'package:perfcli/test_model.dart';
import 'stdout_color_extension.dart';

/// Perfcli is aimed to test your backend performance 
/// 
/// 

const help = 'help';
const url = 'url';
const nbThread = 'nbThread';
const tokenOption = 'token';
const repeatOption = 'repeat';
const randomDelayedOption = 'randomDelayed';

ArgResults argResults;

void main(List<String> arguments) async {
  exitCode = 0;
  final argParser = ArgParser()
    ..addOption(url, abbr: 'u', callback: (r) => r, help: 'url to test')
    ..addOption(tokenOption, callback: (r) => r, help: 'header Authentication: Bearer XXX')
    ..addOption(randomDelayedOption, defaultsTo: 'false', callback: (r) => r, help: 'Delayed randomly on one second')
    ..addOption(repeatOption, defaultsTo: '1', callback: (r) => r, help: 'Repeat for X seconds')
    ..addOption(nbThread, abbr: 't', defaultsTo: '5', callback: (t) => t, help: 'nb Thread to run simultaneously')
    ..addFlag(help, negatable: false, abbr: 'h', help: 'show help');
  argResults = argParser.parse(arguments);
  var nbRepeats = int.parse(argResults[repeatOption]);
  //---------
  if (argResults.wasParsed(help)) {
    stdout.writeln('Perfcli help: ');
    stdout.writeln(argParser.usage);
    return;
  }
  if(argResults.wasParsed(url) && nbRepeats==1) {
    await _sendOneBatch(
      argResults[url],
      int.parse(argResults[nbThread]),
      argResults[tokenOption],
      argResults[randomDelayedOption] == 'true'
    );
    return;
  }
  if(nbRepeats>1) {
    await _sendRepeatedBatch(
      argResults[url],
      int.parse(argResults[nbThread]),
      argResults[tokenOption],
      nbRepeats
    );
    return;
  }
}

Future _sendRepeatedBatch(String urlOption, int nbThreadOption, String token, int nbRepeat) async {
  OnEachBatchStart onEachStart = (batchNumber) 
    => showProgress(batchNumber + 1, nbRepeat, length: 10, prefix: '[sending]', suffix: '');
  var res = await perfcli.stressTestUrlResponseTime(
    nbThreadOption, urlOption, nbRepeat, 
    onEachStart: onEachStart,
    token: token
  );
  stdout.writeln('- $nbRepeat total seconds');
  stdout.writeln('- ${res.averageMs.toStringAsFixed(2)}ms average');
  stdout.writeln('- ${res.min.inMilliseconds}ms min');
  stdout.writeln('- ${res.max.inMilliseconds}ms max');
}

Future _sendOneBatch(String urlOption, int nbThreadOption, String token, bool randomDelay) async {
  var progression = 0;
  var onEachRes = (res) async {
    progression++;
    showProgress(
      progression, 
      nbThreadOption, 
      length: 10,
      prefix: '[sending]', 
      suffix: ''
    );
  };
  var batchRes = await perfcli.testUrlResponseTime(
    nbThreadOption, urlOption, 
    onEachRes: onEachRes,
    token: token,
    randomDelayed: randomDelay
  );
  stdout.writeln('- ${batchRes.results.length} results');
  stdout.writeln('- ${batchRes.min.inMilliseconds}ms min');
  stdout.writeln('- ${batchRes.max.inMilliseconds}ms max');
  stdout.writeln('- ${batchRes.averageMs}ms average');
  stdout.writeln('- ${batchRes.nbSuccess} success');
  stdout.writeln('- ${batchRes.nbErrors} errors');
}

void showProgress(int current, int total, {String prefix, String suffix, int length = 100}) {
  var fill = '█';
  var percent = 100 * (current / total);
  var filledLength = length * current ~/ total;
  var bar = fill * filledLength + '-' * (length - filledLength);
  stdout.writeColored(
    '\r$prefix |$bar| ${percent.toStringAsFixed(0)}% ${suffix ?? '-'}',
    StdoutColor.green
  );
}
