enum Role {
  admin,
  client,
  ptCoach,
  nutrizionista,
  dietista,
  biologo,
  medico,
}

extension RoleX on Role {
  bool get isProfessional => this != Role.admin && this != Role.client;

  String get apiValue {
    switch (this) {
      case Role.admin:
        return 'ADMIN';
      case Role.client:
        return 'CLIENT';
      case Role.ptCoach:
        return 'PT_COACH';
      case Role.nutrizionista:
        return 'NUTRIZIONISTA';
      case Role.dietista:
        return 'DIETISTA';
      case Role.biologo:
        return 'BIOLOGO';
      case Role.medico:
        return 'MEDICO';
    }
  }

}

Role roleFromApi(String raw) {
  switch (raw.toUpperCase()) {
    case 'ADMIN':
      return Role.admin;
    case 'CLIENT':
      return Role.client;
    case 'PT_COACH':
      return Role.ptCoach;
    case 'NUTRIZIONISTA':
      return Role.nutrizionista;
    case 'DIETISTA':
      return Role.dietista;
    case 'BIOLOGO':
      return Role.biologo;
    case 'MEDICO':
      return Role.medico;
    default:
      return Role.client;
  }
}
