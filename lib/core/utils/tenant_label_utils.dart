/// Utility functions for tenant-type-dependent labels.
///
/// Tenant types: 'choir', 'orchestra', or default ('general'/empty).

/// Returns the singular label for groups based on tenant type.
/// choir → Stimme, orchestra → Instrument, default → Gruppe
String groupLabel(String? tenantType) {
  return switch (tenantType) {
    'choir' => 'Stimme',
    'orchestra' => 'Instrument',
    _ => 'Gruppe',
  };
}

/// Returns the plural label for groups based on tenant type.
/// choir → Stimmen, orchestra → Instrumente, default → Gruppen
String groupLabelPlural(String? tenantType) {
  return switch (tenantType) {
    'choir' => 'Stimmen',
    'orchestra' => 'Instrumente',
    _ => 'Gruppen',
  };
}
