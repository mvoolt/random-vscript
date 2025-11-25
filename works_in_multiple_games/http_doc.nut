::mvhttp <- {
    name = "Nuclear Dawn",
    contentType = "application/json"
}

function stub(wowie) {
    SendToConsole("alias " + wowie + "\"\"")
}

function main() {
    SendToConsole("alias GET \"script ProcessGET()\"")
    stub("Accept")
    stub("Connection")
    stub("Sec-Fetch-Site")
    stub("Sec-Fetch-Mode")
    stub("Sec-Fetch-Dest")
    stub("Sec-Fetch-User")
    stub("Accept-Encoding")
    stub("Accept-Language")
    stub("Cache-Control")
    stub("Upgrade-Insecure-Requests")
    stub("Host")
    stub("User-Agent")
    stub("Referer")
    stub("Linux")
    stub("v=b3")
    stub("q=0.7")
    stub("q=0.8")
    stub("q=0.9")
}

::ProcessGET <- function() {
    local str = GenerateDocs()
    printl("HTTP/1.1 200 OK")
    printl("Server: " + mvhttp.name + "/mvhttp")
    printl("Content-Type: " + mvhttp.contentType) 
    printl("Content-Length: " + (str.len() + split(str, "\n").len()))
    printl("")
    for (local i = 0; i < str.len(); i += 127) {
        print(str.slice(i));
    }
    // for good measure
    printl("")
    printl("")
}

main()

// Dumps script documentation in a simple JSON format that can be consumed by various tools
// Called by sv_script_dump_docs and cl_script_dump_docs

// This code is extremely ugly, beware!!!
// Original script from Strata Source, modified for ~~Titanfall~~ All L4D2 branch games

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

	ret += "{\n \"globals\": ["
	
	for (local i = 0; i < matches.len(); ++i) {
		local name = matches[i];
		local documentation = Documentation.functions[name];

        if (name.find(":") == null && !(name in getroottable()))
            continue;

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
		ret += "  {\"method\": \"" + name + "\", \"signature\": \"" + replace_all(signature, "\"", "\\\"") + "\", \"doc\": \"" + replace_all(documentation[1], "\"", "\\\"") + "\" }"
		if (i != matches.len() - 1)
			ret += ",\n"
		else
			ret += "\n"
	}

	ret += " ],\n \"classes\": ["
	
	local ci = 0;
	foreach(cls in classes) {
		local cn = ExtractClassName(cls[0][0]);
		ret += "  {\n   \"class\": \"" + cn + "\",\n   \"extends\": \"" + FindBaseClass(cn) +  "\",\n   \"methods\": ["
		local m = 0;
		foreach(func in cls) {
			local doc = Documentation.functions[func[1]];
			ret += "    { \"method\": \"" + func[1] + "\", \"signature\": \"" + replace_all(doc[0], "\"", "\\\"") + "\", \"doc\": \"" + replace_all(doc[1], "\"", "\\\"") + "\" }"
			if (m == cls.len()-1)
				ret += "\n"
			else
				ret += ",\n"
			m++;
		}

		ret += "   ]\n  }"
		if (ci == classes.len()-1)
			ret += "\n"
		else
			ret += ",\n"
		ci++;
	}

	ret += " ]\n}"
	return ret;
}
