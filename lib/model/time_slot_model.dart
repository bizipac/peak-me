class Timeslot {
  final String timeslot;

  Timeslot({required this.timeslot});

  factory Timeslot.fromJson(Map<String, dynamic> json) {
    return Timeslot(timeslot: json['timeslot']);
  }
}
