package policy.tags

required_tags := ["Environment", "Service", "Component"]

deny[msg] {
  input.resource_change.resource.mode == "managed"
  tag := required_tags[_]
  tags := object.get(input.resource_change.change.after, "tags", {})
  not has_tag(tags, tag)
  msg := sprintf("%s missing required tag %s", [input.resource_change.resource.type, tag])
}

has_tag(tags, tag) {
  tags[tag]
}
