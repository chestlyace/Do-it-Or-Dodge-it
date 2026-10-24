import 'dart:convert';

import 'fakes.dart';

const validShrink =
    '{"steps":[{"title":"Open the website","estMinutes":1},'
    '{"title":"Find the form","estMinutes":5},'
    '{"title":"Fill in the first section","estMinutes":10}]}';

const validHelp = '{"draft":"Hi Sam, could you resend the invoice? Thanks!"}';

const validNudge =
    '{"gentle":"Ready to open the website?",'
    '"firm":"Open the website now.",'
    '"lastCall":"Last chance today: open the website."}';

String excuseJson(String text, [String? short]) =>
    jsonEncode({'excuse': text, 'short': short ?? 'Busy.'});

/// A responder that answers each job with a valid reply.
String Function(ModelCall) validResponder() {
  var excuses = 0;
  return (call) {
    final system = call.systemInstruction ?? '';
    if (system.contains('tiny steps')) return validShrink;
    if (system.contains('ready-to-use draft')) return validHelp;
    if (system.contains('notification messages')) return validNudge;
    excuses++;
    return excuseJson('My week got away from me, number $excuses.');
  };
}

/// A responder that returns [replies] in order, repeating the last one.
String Function(ModelCall) scripted(List<String> replies) {
  var i = 0;
  return (call) => replies[i < replies.length ? i++ : replies.length - 1];
}
