/// Shared Firestore/Timestamp → DateTime converters for domain models.
DateTime readFirestoreDate(Object? value) {
  return readNullableFirestoreDate(value) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? readNullableFirestoreDate(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value == null) {
    return null;
  }

  // Firestore Timestamp exposes toDate(); keep typed without importing Firebase
  // into domain models.
  try {
    final dynamic dynamicValue = value;
    final Object? date = dynamicValue.toDate();
    return date is DateTime ? date : null;
  } on NoSuchMethodError {
    return null;
  }
}
