// figure it out yourself, there's a "wikiparse" variable which contains the useable output
// since i use chromium i just console.log() this wikiparse variable and then click on "Copy output"
// there must be a variable named "dumped" with the JSON dump you just grabbed from dump_json_docs.nut
let wikiparse = ""
wikiparse += `{{toc-right}}
Automatically generated Squirrel functions list for {{srcsdk13mp|4|nt=short|addtext={{nbsp}}(2025)}} ({{tf2}} {{css}} {{dods}} {{hl2dm}} {{hldms}}). This is a generic function list and will work in all SDK 2025 games

== Classes ==
=== :: (Global functions) ===
==== Methods ====
{| class="standard-table" style="width: 100%;"
! Function
! Signature
! Description`
dumped.globals.forEach(func=>{wikiparse += `\n|-
| <code>${func.method}</code>
| <code>${func.signature}</code>
| ${func.doc}`})
wikiparse+=`\n|}`
dumped.classes.forEach(_class=>{wikiparse+=`\n=== ${_class.class} ===

Extends <code>${_class.extends}</code>.

==== Methods ====
{| class="standard-table" style="width: 100%;"
! Function
! Signature
! Description`
_class.methods.forEach(func=>{wikiparse += `\n|-
| <code>${func.method}</code>
| <code>${func.signature}</code>
| ${func.doc}`})
wikiparse+=`\n|}`})
wikiparse+=`

== See also ==
* [[VScript]]
* [[VScript Fundamentals]]
* {{sq}} [[Squirrel]]
* {{srcsdk13mp}} [[Source 2013 MP/Scripting]]
})`
 

