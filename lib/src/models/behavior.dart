class TaggedFieldBehavior {
  final bool allowDuplicatedKeys;
  final bool excludeTagsFromSubmitQuery;
  final bool excludeQueryFromSubmitTags;

  const TaggedFieldBehavior({
    this.allowDuplicatedKeys = false,
    this.excludeTagsFromSubmitQuery = true,
    this.excludeQueryFromSubmitTags = true,
  });
}
