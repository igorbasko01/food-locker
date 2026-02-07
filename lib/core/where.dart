extension IterableWhereExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) predicate) {
    for (final element in this) {
      if (predicate(element)) {
        return element;
      }
    }
    return null;
  }

  T? lastWhereOrNull(bool Function(T element) predicate) {
    T? result;
    for (final element in this) {
      if (predicate(element)) {
        result = element;
      }
    }
    return result;
  }
}
