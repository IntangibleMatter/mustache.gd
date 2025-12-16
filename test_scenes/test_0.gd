extends Node2D

var string := """This is a {{test}}, right?? A {{{test}}}?
Let's try a block: {{#block}}
	Wow! {{.}}
{{/block}}
Cool!
"""

var res : MustacheTemplate
var mus : Mustache

func _ready() -> void:
	var lam= str_to_var("func(test): return 'wow'")
	prints(lam)
	
	return
	prints("start", Time.get_ticks_msec())
	res = MustacheTemplate.new()
	res.parse_string(string)
	print("")
	print(res.contents)
	print("")
	for cont in res.contents:
		print(cont)
		
	mus = Mustache.new()
	mus.add_to_context({
		"test": "totally awesome test & shit",
		"block": ["1", "2", "3"]
	})
	print(mus.render(res))
	prints("end", Time.get_ticks_msec())
