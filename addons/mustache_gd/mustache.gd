class_name Mustache
extends RefCounted

var context_stack: Array
var partials: Dictionary[String, MustacheTemplate]

#region context

## Finds a given key in the current context. Returns [code]null[/code] if the
## given key can't be found.
func get_context_value(key: String) -> Variant:
	#prints("getting", key)
	if key.strip_edges() == ".":
		if context_stack.size() > 0:
			# If the key is just a period we just return the top of the stack
			return context_stack[-1]
	elif key.contains("."):
		return get_split_context_value(key)
	
	for i in range(context_stack.size() - 1, -1, -1):
		var curr: Variant = context_stack[i]
		if curr is Object or curr is Dictionary:
			if key in curr:
				return curr.get(key)
	
	return null


func get_split_context_value(key: String) -> Variant:
	var key_parts := Array(key.split("."))
	var base := key_parts.pop_front()
	
	var searchable: Variant
	
	for i in range(context_stack.size() - 1, -1, -1):
		var curr: Variant = context_stack[i]
		if curr is Object or curr is Dictionary:
			if base in curr:
				searchable = curr.get(base)
				break
	
	if searchable:
		for part in key_parts:
			if part in searchable:
				searchable = searchable.get(part)
			else:
				return null
		
		return searchable

	return null


func add_to_context(to_add: Variant) -> void:
	context_stack.append(to_add)


func clear_context() -> void:
	context_stack.clear()

func add_partial(partial_name: String, partial: MustacheTemplate) -> void:
	partials.set(partial_name, partial)
#endregion

#region render

func render(template: MustacheTemplate, partial_indent_string := "") -> String:
	if not template:
		printerr("TEMPLATE IS NULL:", template)
		return ""
	var out: String
	
	out = render_section(template.contents, partial_indent_string)
	
	return out


func render_section(section: Array, partial_indent_string := "") -> String:
	var out := ""
	
	for sect_idx in section.size():
			#out += partial_indent_string
			
		var sect: Variant = section[sect_idx]
		if sect is String:
			#if not partial_indent_string.is_empty():
				#for line in sect.split("\n"):
					#out += partial_indent_string + line + "\n"
			#else:
			out += sect
		elif sect is Dictionary:
			if "contents" in sect:
				var context: Variant = get_context_value(sect.tag)
				#prints("got context", context)
				if sect.type == MustacheTemplate.TOKEN_TYPE.SECTION and context:
					context_stack.push_back(context)
					#prints("stack", context_stack)
					if context is Array:
						for item in context:
							context_stack.push_back(item)
							out += render_section(sect.contents)
							context_stack.pop_back()
					else:
						out += render_section(sect.contents)
					context_stack.pop_back()
				elif sect.type == MustacheTemplate.TOKEN_TYPE.INVERTED_SECTION and not context:
					out += render_section(sect.contents)
			else:
				match sect.type:
					MustacheTemplate.TOKEN_TYPE.DOT:
						var item: Variant = context_stack[-1]
						if item == null:
							item = ""
						out += str(item).xml_escape(true)
					MustacheTemplate.TOKEN_TYPE.VALUE:
						var item: Variant = get_context_value(sect.tag)
						if item == null:
							item = ""
						out += str(item).xml_escape(true)
					MustacheTemplate.TOKEN_TYPE.RAW_VALUE:
						var item: Variant = get_context_value(sect.tag)
						prints(context_stack)
						if item == null:
							item = ""
						out += str(item)
					MustacheTemplate.TOKEN_TYPE.PARTIAL:
						# handle the indentation thing
						var is_indented: bool = false
						var indent_string: String = ""
						if sect_idx > 0:
							if section[sect_idx - 1] is String:
								var sect_string: String = section[sect_idx - 1]
								var prev_newline := sect_string.rfind("\n")
								if prev_newline >= 0:
									var split_string:= sect_string.substr(prev_newline)
									if split_string.strip_edges().is_empty():
										is_indented = true
										indent_string =sect_string.substr(prev_newline + 1)
									
						#if not is_indented:
						out += render(partials.get(sect.tag), indent_string)
						#else:
							#var rendered_string := render(partials.get(sect.tag)).split("\n")
							#for line in rendered_string.size():
								#out += (
									#(indent_string if line > 0 else "") + 
									#rendered_string[line] + 
									#("\n" if line < rendered_string.size() - 1 else "")
									#)
				pass
	
	return out

#endregion render
