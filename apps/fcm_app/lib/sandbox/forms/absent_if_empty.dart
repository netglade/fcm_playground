/// An empty collection means the field is absent, not that it is empty.
///
/// The typed message classes compare their collections with `ListEquality` and
/// `MapEquality`, so `[]` and `{}` are **not** equal to null. Two things go wrong
/// if an emptied row editor hands its collection straight to the model: the
/// payload carries `"headers": {}` — which asks FCM for an empty value rather
/// than for its default — and `toModel()` stops returning null for an otherwise
/// untouched block, so the whole enclosing object is sent as well.
///
/// This is `emptyMeansAbsent` from `fcm_notification_form.dart`, one type family
/// over. Dart has no overloading, so each shape needs its own name; they live
/// together here rather than in whichever form happened to need one first,
/// because every form from `android` to the message root needs some of them and
/// none of them belongs to a particular platform.
library;

/// An empty string map is absent.
Map<String, String>? absentIfEmptyText(Map<String, String>? value) =>
    (value == null || value.isEmpty) ? null : value;

/// An empty free-form map is absent.
///
/// Separate from [absentIfEmptyText] because these maps hold arbitrary JSON
/// values rather than strings.
Map<String, Object?>? absentIfEmptyObject(Map<String, Object?>? value) =>
    (value == null || value.isEmpty) ? null : value;

/// An empty string list is absent.
List<String>? absentIfEmptyList(List<String>? value) =>
    (value == null || value.isEmpty) ? null : value;
