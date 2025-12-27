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
static var tag_regex: RegEx = RegEx.create_from_string("(?m){{(.*?}?)}}")

#TODO: Implement changing delimiters
const TAG_REGEX_BASE: String = "(?s){{(.+?}?)}}"
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
		if pos < 0:
			printerr("ERROR: POS OUT OF RANGE: ", pos)
		var next_tag := tag_re.search(string, pos)
		if next_tag:
			#prints("tag", next_tag.strings)
			var tag_start := next_tag.get_start()
			var tag_end := next_tag.get_end()
			if tag_start >= 0:
				#var check_if_empty: bool = true

				var tag_contents := next_tag.get_string(1).strip_edges()  # I think this returns the matched tag???
				var tag_type := tag_contents[0]
				tag_contents = tag_contents.substr(1)
				tag_contents = tag_contents.strip_edges()
				var new_tag: Dictionary = {"type": TOKEN_TYPE.ERR, "tag": tag_contents}
				
				
				var may_be_standalone: bool = false
				
				var pretag_string := string.substr(pos, tag_start - pos)
				
				if pretag_string.rfind("\n") != -1:
					var padding: String = ""
					padding = pretag_string.substr(pretag_string.rfind("\n"))
					if padding.strip_edges().is_empty() or padding.strip_edges() == "\n":
						may_be_standalone = true
					
				
				match tag_type:
					"#":
						new_tag.type = TOKEN_TYPE.SECTION
						new_tag.contents = []
					"{", "&":
						new_tag.type = TOKEN_TYPE.RAW_VALUE
						may_be_standalone = false
						if tag_type == "{":
							tag_contents = tag_contents.trim_suffix("}").strip_edges()
							new_tag.tag = tag_contents
					"/":
						new_tag.type = TOKEN_TYPE.SECTION_END
					".":
						if tag_contents.is_empty():
							new_tag.type = TOKEN_TYPE.DOT
							may_be_standalone = false
					"^":
						new_tag.type = TOKEN_TYPE.INVERTED_SECTION
						new_tag.contents = []
					">":
						new_tag.type = TOKEN_TYPE.PARTIAL
						may_be_standalone = false
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
						may_be_standalone = false
				
				
				if may_be_standalone:
					if string.find("\n") != -1:
						var posttag_string: String = string.substr(tag_end, string.find("\n", tag_end) - tag_end)
						if posttag_string.strip_edges().is_empty():
							may_be_standalone = true
						else:
							may_be_standalone = false
				
				if may_be_standalone:
					var prev_newline := string.rfind("\n", tag_start)
					var has_return: bool = string[prev_newline - 1] == "\r"
					if prev_newline:
						contents_stack[-1].append(string.substr(
							pos , prev_newline - (1 if has_return else 0) - pos))
					
					if string.find("\n", tag_end) != -1:
						pos = string.find("\n", tag_end)
						if prev_newline == -1:
							if pos < string.length() - 2:
								pos += 1
							if string[pos - 1] == "\r":
								pos -= 1
					else:
						pos = tag_end
					#if pos < string.length() - 1:
						#pos += 1
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
