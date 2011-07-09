require 'benchmark'
require './dataset'

# this limited test shows that threads DO improve performance, 
#  in this context, at least
##################
#  results for version that uses datasets_hsh in blocks
#moving avg:   					0.870000   0.190000   1.060000 (  1.677090)
#pct move:   					0.400000   0.140000   0.540000 (  1.161736)
#close - open:   				0.840000   0.210000   1.050000 (  2.081506)
#all of them, threaded:   		2.340000   0.630000   2.970000 (  5.093075)
#all of them, NOT threaded:   	2.250000   0.710000   2.960000 (  5.985473)

time1 = Benchmark.measure do
	blk_str = "{|d,v,i| values[i-199..i].inject(0.0) { |sum, v| sum + v.to_f } /5}"
	ds = Dataset.new([["F.SP.CLOSE"], blk_str]) 		
end
puts "moving avg1: #{time1}"

time1a = Benchmark.measure do
	blk_str = "{|d,v,i| values[i-3..i+1].inject(0.0) { |sum, v| sum + v.to_f } /5}"
	ds = Dataset.new([["F.SP.CLOSE"], blk_str]) 		
end
puts "moving avg1a: #{time1a}"

time2 = Benchmark.measure do
	blk_str = "{|d,v,i| 100 * (values[i+1] - values[i-3]) / values[i-3]}"
	ds = Dataset.new([["F.SP.CLOSE"], blk_str]) 		
end
puts "pct move: #{time2}"

time3 = Benchmark.measure do
	blk_str = "{|d,v,i|@ds0.values[i]-@ds1.values[i]}"
	ds = Dataset.new([["F.SP.CLOSE","F.SP.OPEN"], blk_str]) 	
end
puts "close - open: #{time3}"


time_ATR = Benchmark.measure do
		blk_str_th = "{|d,v,i| if @ds0[i-1]>@ds1[i] then @ds0[i-1] else @ds1[i] end}"
		blk_str_tl = "{|d,v,i| if @ds0[i-1]<@ds1[i] then @ds0[i-1] else @ds1[i] end}"
		blk_str_tr = "{|d,v,i|@ds0[i]-@ds1[i]}"
		blk_str_atr = "{|d,v,i|@ds0[i-13..i].inject(0.0) { |sum, v| sum + v.to_f } /14}"
		ds_insts_th = [["F.SP.CLOSE","F.SP.HIGH"], blk_str_th]
		ds_insts_tl = [["F.SP.CLOSE","F.SP.LOW"], blk_str_tl]
		ds_insts_tr = [[ds_insts_th,ds_insts_tl], blk_str_tr]
		ds = Dataset.new([[ds_insts_tr], blk_str_atr])
end
puts "ATR: #{time_ATR}"

time4 = Benchmark.measure do
	threads = []
	threads << Thread.new do
		blk_str = "{|d,v,i| values[i-199..i].inject(0.0) { |sum, v| sum + v.to_f } /5}"
		ds = Dataset.new([["F.SP.CLOSE"], blk_str]) 		
	end
	threads << Thread.new do
		blk_str = "{|d,v,i| values[i-3..i+1].inject(0.0) { |sum, v| sum + v.to_f } /5}"
		ds = Dataset.new([["F.SP.CLOSE"], blk_str]) 		
	end
	threads << Thread.new do
		blk_str = "{|d,v,i| 100 * (values[i+1] - values[i-3]) / values[i-3]}"
		ds = Dataset.new([["F.SP.CLOSE"], blk_str]) 		
	end
	threads << Thread.new do
		blk_str = "{|d,v,i|@ds0.values[i]-@ds1.values[i]}"
		ds = Dataset.new([["F.SP.CLOSE","F.SP.OPEN"], blk_str]) 	
	end
	threads << Thread.new do
		blk_str_th = "{|d,v,i| if @ds0[i-1]>@ds1[i] then @ds0[i-1] else @ds1[i] end}"
		blk_str_tl = "{|d,v,i| if @ds0[i-1]<@ds1[i] then @ds0[i-1] else @ds1[i] end}"
		blk_str_tr = "{|d,v,i|@ds0[i]-@ds1[i]}"
		blk_str_atr = "{|d,v,i|@ds0[i-13..i].inject(0.0) { |sum, v| sum + v.to_f } /14}"
		ds_insts_th = [["F.SP.CLOSE","F.SP.HIGH"], blk_str_th]
		ds_insts_tl = [["F.SP.CLOSE","F.SP.LOW"], blk_str_tl]
		ds_insts_tr = [[ds_insts_th,ds_insts_tl], blk_str_tr]
		ds = Dataset.new([[ds_insts_tr], blk_str_atr])
	end
	threads.each {|t| t.join}
end

puts "all of them, threaded: #{time4}"

time4 = Benchmark.measure do
	blk_str = "{|d,v,i| values[i-3..i+1].inject(0.0) { |sum, v| sum + v.to_f } /5}"
	ds = Dataset.new([["F.SP.CLOSE"], blk_str]) 		
	blk_str = "{|d,v,i| values[i-199..i].inject(0.0) { |sum, v| sum + v.to_f } /5}"
	ds = Dataset.new([["F.SP.CLOSE"], blk_str]) 		
	blk_str = "{|d,v,i| 100 * (values[i+1] - values[i-3]) / values[i-3]}"
	ds = Dataset.new([["F.SP.CLOSE"], blk_str]) 		
	blk_str = "{|d,v,i|@ds0.values[i]-@ds1.values[i]}"
	ds = Dataset.new([["F.SP.CLOSE","F.SP.OPEN"], blk_str]) 	
	blk_str_th = "{|d,v,i| if @ds0[i-1]>@ds1[i] then @ds0[i-1] else @ds1[i] end}"
	blk_str_tl = "{|d,v,i| if @ds0[i-1]<@ds1[i] then @ds0[i-1] else @ds1[i] end}"
	blk_str_tr = "{|d,v,i|@ds0[i]-@ds1[i]}"
	blk_str_atr = "{|d,v,i|@ds0[i-13..i].inject(0.0) { |sum, v| sum + v.to_f } /14}"
	ds_insts_th = [["F.SP.CLOSE","F.SP.HIGH"], blk_str_th]
	ds_insts_tl = [["F.SP.CLOSE","F.SP.LOW"], blk_str_tl]
	ds_insts_tr = [[ds_insts_th,ds_insts_tl], blk_str_tr]
	ds = Dataset.new([[ds_insts_tr], blk_str_atr])
end

puts "all of them, NOT threaded: #{time4}"


