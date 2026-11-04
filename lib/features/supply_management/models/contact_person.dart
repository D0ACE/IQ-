class ContactPerson {
  final String name;
  final String designation;
  final String phone;

  ContactPerson({
    required this.name,
    required this.designation,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'designation': designation, 'phone': phone};
  }

  factory ContactPerson.fromJson(Map<String, dynamic> json) {
    return ContactPerson(
      name: json['name'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }

  ContactPerson copyWith({String? name, String? designation, String? phone}) {
    return ContactPerson(
      name: name ?? this.name,
      designation: designation ?? this.designation,
      phone: phone ?? this.phone,
    );
  }
}
