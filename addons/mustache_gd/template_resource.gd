class_name MustacheTemplate
extends Resource
## A resource which stores all the data needed for a Mustache Template.

enum TOKEN_TYPE {
	ERR = -1,
	NONE = 0,
	VALUE,
	RAW_VALUE,
	DOT,
	SECTION,
	 #SECTION_START,
	 SECTION_END,
	INVERTED_SECTION,
	 #INVERTED_SECTION_START,
	 #INVERTED_SECTION_END,
	PARTIAL,
	DYNAMIC,
	BLOCK,
	 #BLOCK_START,
	 #BLOCK_END,
	PARENT,
	 #PARENT_START,
	 #PARENT_END,
	SET_DELIMITER,
	COMMENT,
}
static var tag_regex: RegEx = RegEx.create_from_string("{{(.*?}?)}}")

#TODO: Implement changing delimiters
const TAG_REGEX_BASE: String = "{{(.+?}?)}}"
const TAG_REGEX_REPLACED: String = ""

## The contents of the template, as an array of tokens
var contents: Array


## Parses a string and uses its data to set up this [code]MustacheTemplate[/code].
func parse_string(string: String) -> Error:
	# The current location of contents, the base value should be the whole contents array.
	var contents_stack: Array[Array] = [contents]

	var tag_re := RegEx.create_from_string(TAG_REGEX_BASE)
	var pos: int = 0

	while pos < string.length():
		var next_tag := tag_re.search(string, pos)
		if next_tag:
			#prints("tag", next_tag.strings)
			var tag_start := next_tag.get_start()
			if tag_start >= 0:
				contents_stack[-1].append(string.substr(pos, tag_start - pos))

				var tag_contents := next_tag.get_string(1).strip_edges()  # I think this returns the matched tag???
				var tag_type := tag_contents[0]
				tag_contents = tag_contents.substr(1)
				tag_contents = tag_contents.strip_edges()
				var new_tag: Dictionary = {"type": TOKEN_TYPE.ERR, "tag": tag_contents}
				
				match tag_type:
					"#":
						new_tag.type = TOKEN_TYPE.SECTION
						new_tag.contents = []
					"{", "&":
						new_tag.type = TOKEN_TYPE.RAW_VALUE
						if tag_type == "{":
							tag_contents = tag_contents.trim_suffix("}").strip_edges()
							new_tag.tag = tag_contents
					"/":
						new_tag.type = TOKEN_TYPE.SECTION_END
					".":
						if tag_contents.is_empty():
							new_tag.type = TOKEN_TYPE.DOT
					"^":
						new_tag.type = TOKEN_TYPE.INVERTED_SECTION
						new_tag.contents = []
					">":
						new_tag.type = TOKEN_TYPE.PARTIAL
					"<":
						new_tag.type = TOKEN_TYPE.PARENT
					"$":
						new_tag.type = TOKEN_TYPE.BLOCK
						new_tag.contents = []
					"!":
						new_tag.type = TOKEN_TYPE.COMMENT
					"=":
						new_tag.type = TOKEN_TYPE.SET_DELIMITER
					_: # may need to improve error handling???
						new_tag.type = TOKEN_TYPE.VALUE 
				
				if new_tag.type != TOKEN_TYPE.ERR and new_tag.type != TOKEN_TYPE.COMMENT:
					if new_tag.type == TOKEN_TYPE.VALUE:
						new_tag.tag = tag_type + tag_contents
					
					if new_tag.type == TOKEN_TYPE.SECTION_END:
						if contents_stack[-2][-1].tag == new_tag.tag:
							prints("section end matcch")
							prints("popping back of contents stack")
							contents_stack.pop_back()
						else:
							printerr("SECTIONS DON'T MATCH")
							return ERR_INVALID_DATA

						
					if not new_tag.type == TOKEN_TYPE.SECTION_END:
						contents_stack[-1].append(new_tag)
					if new_tag.has("contents"):
						contents_stack.append(new_tag.contents)
					
				pos = next_tag.get_end()
		else:
			contents_stack[-1].append(string.substr(pos))
			#prints("bbb", contents_stack)
			return OK

		#prints("aaaaa", contents_stack)
		# return
		pass

	return OK


## Create a new [code]MustacheTemplate[/code] from a String.
static func create_from_string(string: String) -> MustacheTemplate:
	var template := MustacheTemplate.new()
	template.parse_string(string)

	return template
