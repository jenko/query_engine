function_hash = {}
function_hash["pct_move(ds0,from,to,offset)"] = "{|d,v,i| 100 * (@ds0[i-o-to]-@ds0[i-o-from])/@ds0[i-o-from]}"  # first form signature, 1 inst
function_hash["pct_move(ds0,ds1,from,to,offset)"] = "{|d,v,i| 100 * (@ds1[i-o-to]-@ds0[i-o-from])/@ds0[i-o-from]}" # second form signature, 2 inst

#how do we use?
