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
			var tag_end := next_tag.get_end()
			if tag_start >= 0:
				var check_if_empty: bool = true
				

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
						check_if_empty = false
						if tag_type == "{":
							tag_contents = tag_contents.trim_suffix("}").strip_edges()
							new_tag.tag = tag_contents
					"/":
						new_tag.type = TOKEN_TYPE.SECTION_END
					".":
						if tag_contents.is_empty():
							new_tag.type = TOKEN_TYPE.DOT
							check_if_empty = false
					"^":
						new_tag.type = TOKEN_TYPE.INVERTED_SECTION
						new_tag.contents = []
					">":
						new_tag.type = TOKEN_TYPE.PARTIAL
						check_if_empty = false
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
						check_if_empty = false
				
				
				var is_standalone := false
				
				if check_if_empty:
					var prev_newline := string.rfind("\n", tag_start)
					var next_newline := string.find("\n", tag_end)
					var endpos := -1
					var prev_newline_offset := 0
					if prev_newline > 0 and string[prev_newline - 1] == "\r":
						prev_newline -= 1
						prev_newline_offset = 1
						
					if prev_newline >= 0 and next_newline >= 0 and prev_newline > pos:
						var newline_substring := string.substr(prev_newline, next_newline - prev_newline).replace(
							next_tag.strings[0], ""
						)
						
						prints("newline_substring", newline_substring, newline_substring.strip_edges().is_empty())
						if newline_substring.strip_edges().is_empty():
							is_standalone = true
							contents_stack[-1].append(string.substr(pos, prev_newline + prev_newline_offset - pos))
							pos = next_newline 
							
					elif next_newline >= 0:
						var newline_substring := string.substr(0, next_newline).replace(
							next_tag.strings[0], ""
						)
						prints("newline_substring next", newline_substring, newline_substring.strip_edges().is_empty())
						if newline_substring.strip_edges().is_empty():
							is_standalone = true
							pos = next_newline + 1

							#contents_stack[-1].append(string.substr(0, tag_start))
							
					elif prev_newline >= 0 and prev_newline > pos:
						var newline_substring := string.substr(prev_newline).replace(
							next_tag.strings[0], ""
						)
						prints("newline_substring prev", newline_substring, newline_substring.strip_edges().is_empty())
						if newline_substring.strip_edges().is_empty():
							is_standalone = true
							string = string.substr(0, prev_newline + prev_newline_offset + 1)
							endpos = prev_newline + prev_newline_offset + 1
					if is_standalone:
						if endpos == 0:
							pass
						elif endpos > -1:
							contents_stack[-1].append(string.substr(pos, endpos - pos))
						pos = max(pos, tag_end)
						
						#pass
						#contents_stack[-1].append(string.substr(pos, prev_newline - pos))
					else:
						contents_stack[-1].append(string.substr(pos, tag_start - pos))
						pos = next_tag.get_end()
						
						
				else:
					contents_stack[-1].append(string.substr(pos, tag_start - pos))
					pos = next_tag.get_end()
					
				
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
