/// Controls how the tagged field handles tags and queries during submission.
class TaggedFieldBehavior {
  /// If true, allows the same key to be used multiple times in the field.
  final bool allowDuplicatedKeys;

  /// If true, tags are excluded from the submitted query string.
  final bool excludeTagsFromSubmitQuery;

  /// If true, free text is excluded when submitting tags.
  final bool excludeQueryFromSubmitTags;

  const TaggedFieldBehavior({
    this.allowDuplicatedKeys = false,
    this.excludeTagsFromSubmitQuery = true,
    this.excludeQueryFromSubmitTags = true,
  });
}
