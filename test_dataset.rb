require 'test/unit'
require './dataset.rb'

class TestDataset < Test::Unit::TestCase

	def setup
	end
	
	def teardown
	end
=begin
=end

	def test_initialize_one_inst_in_array_empty_proc
		ds = Dataset.new(["F.SP.CLOSE"])
		assert_not_nil(ds)
		assert_equal(110.20, ds[44].round(2))
	end

	def test_signature_as_arg
		ds1 = Dataset.new(["F.SP.CLOSE"])
#		puts "ds1.signature: #{ds1.signature.actual_signature}"
		ds2 = Dataset.new([ds1.signature.actual_signature])
		assert_not_nil(ds2)
		assert_equal(ds1.values.size, ds2.values.size)
		assert_equal(110.20, ds1[44].round(2))
	end

	def test_initialize_one_inst_no_array_empty_proc
		ds = Dataset.new("F.SP.CLOSE")
		assert_not_nil(ds)
		assert_equal(true, ds.is_db_set)
		assert_equal(110.20, ds[44].round(2))
	end

	def test_initialize_two_inst_in_array_empty_proc
		assert_raise(QueryServer::InvalidDatasetBlockError) {
			ds = Dataset.new(["F.SP.CLOSE","F.SP.OPEN"])
		}		
	end
	
	def test_initialize_two_inst_no_array_empty_proc
		assert_raise(ArgumentError) {
			ds = Dataset.new("F.SP.CLOSE","F.SP.OPEN")
		}		
	end
	def test_initialize_one_inst_nonempty_proc_arity_1
		blk_str = "{|d,v,i| @ds0[i] * @ds0[i]}"
		ds = Dataset.new([["F.SP.CLOSE"], blk_str]) 
		assert_not_nil(ds)
		assert_equal(false, ds.is_db_set)
		assert_equal([["F.SP.CLOSE"], "{|d,v,i| @ds0[i] * @ds0[i]}"], ds.signature.actual_signature)
		assert_equal(12144.04, ds[44])
	end
	def test_initialize_one_inst_nonempty_proc_arity_1_ds_syntax
		blk_str = "{|d,v,i| @ds0[i] * @ds0[i]}"
		ds = Dataset.new([["F.SP.CLOSE"], blk_str]) 
		assert_not_nil(ds)
		assert_equal(false, ds.signature.is_db_set)
		assert_equal(12144.04, ds[44])
	end
	def test_multi_inst_function
#		blk_str = "{|d,v,i|@ds0[i]-@ds1[i]}"
		blk_str = "{|d,v,i|ds0(i)-ds1(i)}"
		ds = Dataset.new([["F.SP.CLOSE","F.SP.OPEN"], blk_str]) 	
		assert_equal(-1.90, ds[44].round(2))
	end
	def test_ranged_function_avg
		blk_str = "{|d,v,i| @ds0[i-3..i+1].inject(0.0) { |sum, v| sum + v.to_f } /5}"
		ds = Dataset.new([["F.SP.CLOSE"], blk_str]) 		
		assert_equal(109.66, ds[44].round(2))
	end

	def test_ranged_function_pct_move
		blk_str = "{|d,v,i| 100 * (@ds0[i+1] - @ds0[i-3]) / @ds0[i-3]}"
		ds = Dataset.new([["F.SP.CLOSE"], blk_str]) 		
		assert_equal(3.62, ds[44].round(2))
	end

	def test_multi_inst_function
		blk_str = "{|d,v,i|@ds0[i]-@ds1[i]}"
		ds = Dataset.new([["F.SP.CLOSE","F.SP.OPEN"], blk_str]) 	
		assert_equal(-1.90, ds[44].round(2))
	end

	def test_true_high_function
		blk_str = "{|d,v,i| if @ds0[i-1]>@ds1[i] then @ds0[i-1] else @ds1[i] end}"
		ds = Dataset.new([["F.SP.CLOSE","F.SP.HIGH"], blk_str]) 	
		assert_equal(112.60, ds[44].round(2))
	end

	def test_true_low_function
		blk_str = "{|d,v,i| if @ds0[i-1]<@ds1[i] then @ds0[i-1] else @ds1[i] end}"
		ds = Dataset.new([["F.SP.CLOSE","F.SP.LOW"], blk_str]) 	
		assert_equal(109.75, ds[44].round(2))
	end
	def test_true_range_function
		blk_str_th = "{|d,v,i| if @ds0[i-1]>@ds1[i] then @ds0[i-1] else @ds1[i] end}"
		blk_str_tl = "{|d,v,i| if @ds0[i-1]<@ds1[i] then @ds0[i-1] else @ds1[i] end}"
		blk_str_tr = "{|d,v,i|@ds0[i]-@ds1[i]}"
		ds_insts_th = [["F.SP.CLOSE","F.SP.HIGH"], blk_str_th]
		ds_insts_tl = [["F.SP.CLOSE","F.SP.LOW"], blk_str_tl]
		ds = Dataset.new([[ds_insts_th,ds_insts_tl], blk_str_tr])
		assert_equal(2.85, ds[44].round(2))
	end


	def test_average_true_range_function
		blk_str_th = "{|d,v,i| if @ds0[i-1]>@ds1[i] then @ds0[i-1] else @ds1[i] end}"
		blk_str_tl = "{|d,v,i| if @ds0[i-1]<@ds1[i] then @ds0[i-1] else @ds1[i] end}"
		blk_str_tr = "{|d,v,i|@ds0[i]-@ds1[i]}"
		blk_str_atr = "{|d,v,i|@ds0[i-13..i].inject(0.0) { |sum, v| sum + v.to_f } /14}"
		ds_insts_th = [["F.SP.CLOSE","F.SP.HIGH"], blk_str_th]
		ds_insts_tl = [["F.SP.CLOSE","F.SP.LOW"], blk_str_tl]
		ds_insts_tr = [[ds_insts_th,ds_insts_tl], blk_str_tr]
		ds = Dataset.new([[ds_insts_tr], blk_str_atr])
		assert_equal(2.65, ds[44].round(2))
	end

	def test_ago
	# we're gonna test it on true_low, 4 values ago
		blk_str_tl = "{|d,v,i| if @ds0[i-1]<@ds1[i] then @ds0[i-1] else @ds1[i] end}"
		ds_insts_tl = [["F.SP.CLOSE","F.SP.LOW"], blk_str_tl]
		blk_str_ago = "{|d,v,i|@ds0[i-4]}"
		ds = Dataset.new([[ds_insts_tl], blk_str_ago]) 	
		assert_equal(104.35, ds[44].round(2))
	end

	def test_later
	# we're gonna test it on true_low, 7 values later
		blk_str_tl = "{|d,v,i| if @ds0[i-1]<@ds1[i] then @ds0[i-1] else @ds1[i] end}"
		ds_insts_tl = [["F.SP.CLOSE","F.SP.LOW"], blk_str_tl]
		blk_str_ago = "{|d,v,i|@ds0[i+7]}"
		ds = Dataset.new([[ds_insts_tl], blk_str_ago]) 	
		assert_equal(106.40, ds[44].round(2))
	end
=begin
=end	

=begin
=end
end

