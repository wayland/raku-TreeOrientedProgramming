=begin pod

=NAME

TreeOrientedProgramming - A module for manipulating trees

=TITLE

TreeOrientedProgramming

=SUBTITLE

A module for manipulating trees.  

=head1 PURPOSE

The purpose of this module is to make it easy and simple to select data out of 
a tree structure -- Tree-Oriented Programming, if you will.  This is part of 
"make the easy things easy, and the hard things possible".  On the Tree front,
we already have the "hard things possible" part, but this is the "easy things
easy part"

Since most structured data is a tree or a table of some sort, it's important 
that we be able to manipulate trees.  

It will provide some XPath-like operators that will 
allow you to select data out of your Raku data structures.  These data 
operators should work on anything that "does Positional" and "does 
Associative".  These will descend into Positional children (ie. XML child 
nodes), but not into Associative (ie. XML Attribute nodes).  

=end pod

# Next steps:
# -	Get descendent/child/self/attribute working with the XML module
#	-	May need to get Associative working on Element/Document as well
# -	Start work on parent/ancestor/root
# -	Then do preceding/following sibling
# -	Finally, do the preceding/following ones
# -	Test out the sort/map/reduce operators
# -	Parser operator (for eg. JSON, CSV, XML)
# -	Connection/Source operator (for eg. filesystems, commands, web connections, etc)


# Comparison table of operators
# +--------+-----------+--------------+-------+-------------------------+
# | Raku   | SQL       | MapReduce    | XPath | TreeOrientedProgramming |
# +--------+-----------+--------------+-------+-------------------------+
# | grep   | WHERE     | filter (map) | Basic | XPath-like              |
# | map    | FUNCTION? | map          | XSLT  | XSLT-like?              |
# | reduce | GROUP BY  | reduce       | ???   | ???                     |
# | sort   | ORDER BY  | sort (map)   | ???   | ???                     |
# +--------+-----------+--------------+-------+-------------------------+

#- should be able to do something like a location path, but instead of a node name, we use the default attribute
#- have a parser operator; right side is an object on which to call .parse() (or whatever we call on grammars). If it's a string, try instantiating it as an object
#	-	Maybe not just a parser; we want fetchers/connections as well (eg. filesystem, websocket)
#-	Use .collate() instead of sort

# Data model differences from XML:
# +-----------+-----------------------------+
# | XML       | TreeOrientedProgramming     |
# +-----------+-----------------------------+
# | Document  | Root                        |
# | Node      | -                           |
# | Element   | Node                        |
# | Attribute | Just an Assoc array element |
# | Text      | Just a string               |
# | Others    | -                           |
# +-----------+-----------------------------+

##### Operators that do what XPath does
# The basic XPath operators are equivalent to grep/WHERE/filter

#- should work on anything that does Node
#- Some axes (eg child) should work on anything that does Positional
#- children should be positional, attributes should be associative
sub	WalkTreeMatch(@axes, $matcher, @inputs) {
	my (@retvals);

	for @axes -> $axis {
		given $axis {
			when 'self' { @inputs.grep(&$matcher) ==> @retvals; }
			when 'child' {
				for @inputs -> $input {
					$input ~~ Positional or next;
					$input ~~ Iterable or warn "Warning: does Positional but not Iterable: " ~ $input.raku.substr(0..100);
					my @iarr := $input;
					for @iarr -> $child {
						if &$matcher($child) {
							@retvals.push($child);
						}
					}
				}
			}
			when 'descendent' {
				for @inputs -> $input {
					$input ~~ Positional or next;
					$input ~~ Iterable or warn "Warning: does Positional but not Iterable: " ~ $input.raku.substr(0..100);
					my @iarr := $input;
					for @iarr -> $child {
						if ($child ~~ Positional) {
							WalkTreeMatch([<descendent self>], $matcher, $child) ==> @retvals;
						} else {
							WalkTreeMatch([<self>], $matcher, [$child]) ==> @retvals;
						}
					}
				}
			}
			when 'attribute' {
				for @inputs -> $input {
					if ($input ~~ Associative) {
#say "assoc: " ~ $input.raku;
						for $input.kv -> $key, $value {
							if &$matcher($key) {
								@retvals.push($value);
							}
						}
					}
				}
			}

			when 'parent' {}
			when 'ancestor' {}
			when 'root' {}

			when 'following-sibling' {}
			when 'preceding-sibling' {}
			when 'following' {}
			when 'preceding' {}

			default { die "Error: Unknown axis '$axis'"; }
		}
	}
	return @retvals;
}

### Up-down relationships

# U+2AAA - Child
sub infix:<⪪>(@inputs, $matcher)	is export {	WalkTreeMatch(['child'], $matcher,	@inputs);	}
#sub postfix:<⪪>(@inputs)		is export {	WalkTreeMatch(['child'], {return True},	@inputs);	}
# U+2AAB - Parent
sub infix:<⪫>(@inputs, $matcher)	is export {	WalkTreeMatch(['parent'], $matcher,	@inputs);	}
#sub postfix:<⪫>(@inputs)		is export {	WalkTreeMatch(['parent'], {return True},@inputs);	}
# U+2AAA x2 - Descendent
sub infix:<⪪⪪>(@inputs, $matcher)	is export {	WalkTreeMatch(['descendent'], $matcher,	@inputs);	}
#sub postfix:<⪪⪪>(@inputs)		is export {	WalkTreeMatch(['descendent'], {return True}, @inputs);	}
# U+2AAD x2 - Ancestor
sub infix:<⪫⪫>(@inputs, $matcher)	is export {	WalkTreeMatch(['ancestor'], $matcher, @inputs);	}
#sub postfix:<⪫⪫>(@inputs)		is export {	WalkTreeMatch(['ancestor'], {return True}, @inputs);	}

### Before-after relationships
# Mathematically, the symbol we call "Following" is "Precedes", because inputs 
# precede outputs, but XPath terminology wants us to say "outputs are 
# following inputs".  This same reversal applies to the other terms too
# Also, some of these are difficult to visually distinguish from greater than/
# less than, so we may need to do something about the fonts

# U+227A - Following-sibling
sub infix:<≺>(@inputs, $matcher)	is export {	WalkTreeMatch(['following-sibling'], $matcher, @inputs);	}
# U+227B - Preceding-sibling
sub infix:<≻>(@inputs, $matcher)	is export {	WalkTreeMatch(['preceding-sibling'], $matcher, @inputs);	}
# U+227C - Following
sub infix:<≼>(@inputs, $matcher)	is export {	WalkTreeMatch(['following'], $matcher, @inputs);	}
# U+227D - Preceding
sub infix:<≽>(@inputs, $matcher)	is export {	WalkTreeMatch(['preceding'], $matcher, @inputs);	}


### Other Tree Relations
# self, root, attribute

# U+25C1 - Root
sub infix:<◁>(@inputs, $matcher)	is export {	WalkTreeMatch(['root'], $matcher, @inputs);	}
# U+27D0 - Self
sub infix:<⟐>(@inputs, $matcher)	is export { say "self";	WalkTreeMatch(['self'], $matcher, @inputs);	}
# U+2be9 - Attribute
sub infix:<⯩>(@inputs, $matcher)	is export {	WalkTreeMatch(['attribute'], $matcher, @inputs);	}


##### Other Operators; the goal is to do the other things you can do in an SQL SELECT statement; these should be moved to TOP

### Sort
# U+21C5 - Sort
sub infix:<⇅>(@inputs, $matcher)	is export { @inputs.sort($matcher); }

### Map
# The Hyper operator (below, core Raku) is equivalent to a map call, but with a few advantages
# ».

# Reduce
# There will be 2 types of reduction operators:
# -	Core Raku reduction operators; they only allow an operator as the codeblock, but would be handy
# -	The generic reduction operator, below
# U+233F - Reduce
sub infix:<⌿>(@inputs, $matcher)	is export { @inputs.reduce($matcher); }

### NOTE: methodop .+ and methodop .* appear to walk all multis, which will be very useful for the predicates/laws thingy

=begin pod

=AUTHOR Tim Nelson <wayland@wayland.id.au>

=VERSION

=end pod

class	TreeOrientedProgramming {}
