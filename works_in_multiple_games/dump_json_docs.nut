// Dumps script documentation in a simple JSON format that can be consumed by various tools
// Called by sv_script_dump_docs and cl_script_dump_docs

// This code is extremely ugly, beware!!!
// Original script from Strata Source, modified for ~~Titanfall~~ All Source Engine games equipped with VScript

// "replace_all" function by Respawn Entertainment for Titanfall
// Helper function to replace all occurrences of 'find' with 'replace' in 'original'
function replace_all(original, find, replace)
{
    local result = "";
    local pos = 0;
    local find_len = find.len();

    // Validate that 'find' is not an empty string to prevent infinite loops
    if (find_len == 0)
    {
        return original; // Return original string unchanged
    }


    while (true)
    {
        local index = original.find(find, pos);

        // If 'find' is not found, 'index' will be null
        if (index == null)
        {
            // Append the remaining part of the string
            local remaining = original.slice(pos, original.len());
            result += remaining;
            break;
        }

        // Append the substring before the found occurrence and the replacement
        local before = original.slice(pos, index);
        result += before + replace;

        // Move the position forward to continue searching
        pos = index + find_len;
    }

    return result;
}


function ExtractClassName(sig) {
	if (sig.slice(0,1) == " ")
		sig = "filler" + sig

	if(sig.find("::") != null)
		return split(sig, ": ")[1]

	return null; 
}

// cls is string name of class; returns the name of the base class
function FindBaseClass(cls) {
	try {
		local c = getroottable().rawget(cls)
		foreach (n, e in getroottable()) {
			if (c.parent == e)
				return n;
		}
		return "";
	}
	catch (e) {
		return "";
	}
}

// Prints documentation in a nice markdown format
function GenerateDocs() {
	local matches = []
	local classes = {}
	
	foreach(name, doc in Documentation.functions) {
		matches.append(name)
	}
	matches.sort();

	local ret = "";

	print("{\n \"globals\": [")
	
	for (local i = 0; i < matches.len(); ++i) {
		local name = matches[i];
		local documentation = Documentation.functions[name];

		local signature = "";
		if ( documentation[0] != "#" ) {
			signature = documentation[0];
		}
		else {
			if (GetFunctionSignature( this[name], name ) != null) {
				signature = GetFunctionSignature( this[name], name )
			}
		}
		// Check for :: class separator
			if(signature.find("::") != null) {
				if (signature.slice(0,1) == " ")
					signature = "filler" + signature

				local s = split(signature, ": ");
				try {
					classes[s[1]].append([signature,name]);
				}
				catch(id) {
					classes[s[1]] <- [[signature,name]];
				}
				continue;
			}
		print("  {\"method\": \"" + name + "\", \"signature\": \"" + replace_all(signature, "\"", "\\\"") + "\", \"doc\": \"" + replace_all(documentation[1], "\"", "\\\"") + "\" }")
		if (i != matches.len() - 1)
			print(",\n")
		else
			print("\n")
	}

	print(" ],\n \"classes\": [")
	
	local ci = 0;
	foreach(cls in classes) {
		local cn = ExtractClassName(cls[0][0]);
		print("  {\n   \"class\": \"" + cn + "\",\n   \"extends\": \"" + FindBaseClass(cn) +  "\",\n   \"methods\": [")
		local m = 0;
		foreach(func in cls) {
			local doc = Documentation.functions[func[1]];
			print("    { \"method\": \"" + func[1] + "\", \"signature\": \"" + replace_all(doc[0], "\"", "\\\"") + "\", \"doc\": \"" + replace_all(doc[1], "\"", "\\\"") + "\" }")
			if (m == cls.len()-1)
				print("\n")
			else
				print(",\n")
			m++;
		}

		print("   ]\n  }")
		if (ci == classes.len()-1)
			("\n")
		else
			print(",\n")
		ci++;
	}

	print(" ]\n}")
	return ret;
}
GenerateDocs()
