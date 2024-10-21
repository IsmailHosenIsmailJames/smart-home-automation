import 'dart:convert';

class ModeOfElements {
  String? feedback;
  int pin;
  bool request;
  bool state;

  ModeOfElements({
    this.feedback,
    required this.pin,
    required this.request,
    required this.state,
  });

  ModeOfElements copyWith({
    String? feedback,
    int? pin,
    bool? request,
    bool? state,
  }) =>
      ModeOfElements(
        feedback: feedback ?? this.feedback,
        pin: pin ?? this.pin,
        request: request ?? this.request,
        state: state ?? this.state,
      );

  factory ModeOfElements.fromJson(String str) =>
      ModeOfElements.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ModeOfElements.fromMap(Map<String, dynamic> json) => ModeOfElements(
        feedback: json["feedback"],
        pin: json["pin"],
        request: json["request"],
        state: json["state"],
      );

  Map<String, dynamic> toMap() => {
        "feedback": feedback,
        "pin": pin,
        "request": request,
        "state": state,
      };
}
