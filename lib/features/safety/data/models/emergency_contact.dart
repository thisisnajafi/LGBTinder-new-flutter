/// Emergency contact model
class EmergencyContact {
  final int id;
  final String name;
  final String phoneNumber;
  final String? relationship;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime? updatedAt;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.relationship,
    this.isPrimary = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (json['id'] == null) {
      throw FormatException('EmergencyContact.fromJson: id is required but was null');
    }
    if (json['name'] == null) {
      throw FormatException('EmergencyContact.fromJson: name is required but was null');
    }
    if (json['phone_number'] == null) {
      throw FormatException('EmergencyContact.fromJson: phone_number is required but was null');
    }
    
    return EmergencyContact(
      id: (json['id'] is int) ? json['id'] as int : int.parse(json['id'].toString()),
      name: json['name'].toString(),
      phoneNumber: json['phone_number'].toString(),
      relationship: json['relationship']?.toString(),
      isPrimary: json['is_primary'] == true || json['is_primary'] == 1,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      if (relationship != null) 'relationship': relationship,
      'is_primary': isPrimary,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

/// Add emergency contact request
class AddEmergencyContactRequest {
  final String name;
  final String phoneNumber;
  final String? relationship;
  final bool isPrimary;

  AddEmergencyContactRequest({
    required this.name,
    required this.phoneNumber,
    this.relationship,
    this.isPrimary = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      if (relationship != null && relationship!.isNotEmpty) 'relationship': relationship,
      'is_primary': isPrimary,
    };
  }
}

/// Update emergency contact request
class UpdateEmergencyContactRequest {
  final int contactId;
  final String? name;
  final String? phoneNumber;
  final String? relationship;
  final bool? isPrimary;

  UpdateEmergencyContactRequest({
    required this.contactId,
    this.name,
    this.phoneNumber,
    this.relationship,
    this.isPrimary,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null && name!.isNotEmpty) json['name'] = name;
    if (phoneNumber != null && phoneNumber!.isNotEmpty) json['phone_number'] = phoneNumber;
    if (relationship != null) json['relationship'] = relationship;
    if (isPrimary != null) json['is_primary'] = isPrimary;
    return json;
  }
}

/// Emergency alert model (for sending alerts to emergency contacts)
class EmergencyAlert {
  final int id;
  final String message;
  final String location;
  final DateTime sentAt;
  final List<EmergencyContact> notifiedContacts;

  EmergencyAlert({
    required this.id,
    required this.message,
    required this.location,
    required this.sentAt,
    required this.notifiedContacts,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (json['id'] == null) {
      throw FormatException('EmergencyAlert.fromJson: id is required but was null');
    }
    if (json['message'] == null) {
      throw FormatException('EmergencyAlert.fromJson: message is required but was null');
    }
    if (json['location'] == null) {
      throw FormatException('EmergencyAlert.fromJson: location is required but was null');
    }
    
    return EmergencyAlert(
      id: (json['id'] is int) ? json['id'] as int : int.parse(json['id'].toString()),
      message: json['message'].toString(),
      location: json['location'].toString(),
      sentAt: json['sent_at'] != null
          ? (DateTime.tryParse(json['sent_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      notifiedContacts: json['notified_contacts'] != null && json['notified_contacts'] is List
          ? (json['notified_contacts'] as List)
              .map((contact) => EmergencyContact.fromJson(Map<String, dynamic>.from(contact as Map)))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'location': location,
      'sent_at': sentAt.toIso8601String(),
      'notified_contacts': notifiedContacts.map((contact) => contact.toJson()).toList(),
    };
  }
}

/// Send emergency alert request
class SendEmergencyAlertRequest {
  final String message;
  final String? customLocation;

  SendEmergencyAlertRequest({
    required this.message,
    this.customLocation,
  });

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      if (customLocation != null && customLocation!.isNotEmpty) 'custom_location': customLocation,
    };
  }
}
