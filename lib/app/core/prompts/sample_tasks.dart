import '../../data/models/enums.dart';

/// A task used to try the prompt jobs.
class SampleTask {
  const SampleTask({
    required this.title,
    required this.step,
    required this.recipient,
    required this.tone,
    this.note,
    this.dueInDays,
  });

  final String title;
  final String? note;
  final int? dueInDays;

  /// A plausible first step, used for `helpWithStep` and `nudgeWording`.
  final String step;

  /// Who an excuse would go to.
  final String recipient;
  final ExcuseTone tone;
}

/// Fixed set of 20 tasks that every prompt job is run against.
const sampleTasks = <SampleTask>[
  SampleTask(
    title: 'File my tax return',
    note: 'Payslips are in a drawer somewhere.',
    dueInDays: 5,
    step: 'Find last year\'s return',
    recipient: 'accountant',
    tone: ExcuseTone.formal,
  ),
  SampleTask(
    title: 'Reply to Sam about the invoice',
    dueInDays: 1,
    step: 'Open Sam\'s email',
    recipient: 'Sam',
    tone: ExcuseTone.polite,
  ),
  SampleTask(
    title: 'Go for a 20 minute run',
    step: 'Put on running shoes',
    recipient: 'running club',
    tone: ExcuseTone.casual,
  ),
  SampleTask(
    title: 'Do the laundry',
    dueInDays: 2,
    step: 'Carry the basket to the machine',
    recipient: 'flatmate',
    tone: ExcuseTone.funny,
  ),
  SampleTask(
    title: 'Book a dentist appointment',
    step: 'Find the clinic\'s phone number',
    recipient: 'partner',
    tone: ExcuseTone.casual,
  ),
  SampleTask(
    title: 'Write the Q3 report',
    note: 'Needs the sales numbers and two charts.',
    dueInDays: 7,
    step: 'Create an empty document',
    recipient: 'boss',
    tone: ExcuseTone.formal,
  ),
  SampleTask(
    title: 'Clean out the garage',
    step: 'Open the garage door',
    recipient: 'neighbour',
    tone: ExcuseTone.funny,
  ),
  SampleTask(
    title: 'Study for the chemistry exam',
    dueInDays: 10,
    step: 'Open chapter 4',
    recipient: 'study group',
    tone: ExcuseTone.casual,
  ),
  SampleTask(
    title: 'Call mum',
    step: 'Find mum in the contacts',
    recipient: 'mum',
    tone: ExcuseTone.polite,
  ),
  SampleTask(
    title: 'Renew my passport',
    note: 'Needs a photo and the old passport.',
    dueInDays: 30,
    step: 'Look up the application page',
    recipient: 'travel agent',
    tone: ExcuseTone.formal,
  ),
  SampleTask(
    title: 'Plan the team offsite',
    dueInDays: 14,
    step: 'List three possible dates',
    recipient: 'team',
    tone: ExcuseTone.polite,
  ),
  SampleTask(
    title: 'Unsubscribe from newsletters',
    step: 'Search the inbox for "unsubscribe"',
    recipient: 'colleague',
    tone: ExcuseTone.funny,
  ),
  SampleTask(
    title: 'Fix the leaking tap',
    step: 'Find the wrench',
    recipient: 'landlord',
    tone: ExcuseTone.polite,
  ),
  SampleTask(
    title: 'Back up my phone photos',
    step: 'Plug the phone into the charger',
    recipient: 'sister',
    tone: ExcuseTone.casual,
  ),
  SampleTask(
    title: 'Write a thank-you note to Aunt Rosa',
    step: 'Find a pen and paper',
    recipient: 'Aunt Rosa',
    tone: ExcuseTone.polite,
  ),
  SampleTask(
    title: 'Prepare slides for Friday\'s demo',
    note: 'Five slides at most.',
    dueInDays: 3,
    step: 'Open the slide template',
    recipient: 'product manager',
    tone: ExcuseTone.formal,
  ),
  SampleTask(
    title: 'Return the library books',
    dueInDays: 1,
    step: 'Put the books by the door',
    recipient: 'librarian',
    tone: ExcuseTone.polite,
  ),
  SampleTask(
    title: 'Meal prep for the week',
    step: 'Write down three recipes',
    recipient: 'gym buddy',
    tone: ExcuseTone.funny,
  ),
  SampleTask(
    title: 'Update my CV',
    step: 'Open the old CV',
    recipient: 'recruiter',
    tone: ExcuseTone.formal,
  ),
  SampleTask(
    title: 'Water the plants and repot the fern',
    step: 'Fill the watering can',
    recipient: 'housemate',
    tone: ExcuseTone.casual,
  ),
];
