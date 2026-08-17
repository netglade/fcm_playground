/// An empty collection means the field is absent, not that it is empty.
///
/// The typed message classes compare their collections with `ListEquality` and
/// `MapEquality`, so `[]` and `{}` are not equal to null. Handing an emptied row
/// editor's collection straight to the model would send `"headers": {}` — asking
/// FCM for an empty value rather than its default — and would stop `toModel()`
/// returning null for an otherwise untouched block.
///
/// Dart has no overloading, so each shape needs its own name.
library;

Map<String, String>? absentIfEmptyText(Map<String, String>? value) =>
    (value == null || value.isEmpty) ? null : value;

Map<String, Object?>? absentIfEmptyObject(Map<String, Object?>? value) =>
    (value == null || value.isEmpty) ? null : value;

List<String>? absentIfEmptyList(List<String>? value) =>
    (value == null || value.isEmpty) ? null : value;
