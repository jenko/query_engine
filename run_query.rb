require 'treetop'

Treetop.load 'query_grammar'

=begin

	What do we want our queries to look like?  I guess we could start with making them look exactly like they look now:

let inst_var = f.sp
show
  Op: 100 * (inst_var.open 1 value later - inst_var) / inst_var
  ROD: 100 * (inst_var - inst_var.open) / inst_var.open
  1d: % move from 0 values ago to 1 value later of inst_var
  2d: % move from 0 values ago to 2 value later of inst_var
  3d: % move from 0 values ago to 3 value later of inst_var
  4d: % move from 0 values ago to 4 value later of inst_var
  5d: % move from 0 values ago to 5 value later of inst_var
when
  % move from 1 value ago to 0 values ago of inst_var > 3
and
   date is after 12/3/2005

In the current Finquery.exe program, we parse things in chunks; specifically:

1. the "let" statement does not get parsed with a proper parser (we write the logic ourselves)
2. everything between "show" and "when" is assumed to be either a comment (if the first non-whitespace char is "#")
   or an output line; each output line is parsed with the actual parser
3. everything after "when" is considered the "when" clause, whic is also parsed with the actual parser

the current process involves "pre-parsing" the query, i.e., determining the members of the "let", "show", and "when" chunks
and then parsing those "chunks" in turn

"execution" of a query:
ruby '/run_query.rb' 'queryfilename.qry'
   
=end
