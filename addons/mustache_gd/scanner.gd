class_name MustacheScanner
extends RefCounted

static var tag_regex: RegEx = RegEx.create_from_string("{{(.*?}?)}}")
