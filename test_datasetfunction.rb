require 'test/unit'
require './dataset.rb'
require './datasetfunction.rb'

class TestDataset < Test::Unit::TestCase

	def test_pct_move_2_insts
		ds_sig = Datasetfunction.make_signature("PCT_MOVE", "F.SP.CLOSE", "F.SP.CLOSE", "-3", "1")
		assert_equal([["F.SP.CLOSE","F.SP.CLOSE"], "{|d,v,i|100*(@ds1[i+1]-@ds0[i+-3])/@ds0[i+-3]}"], ds_sig)
		ds = Dataset.new(ds_sig)
		assert_equal(3.62, ds[44].round(2))
	end
	
	def test_pct_move_of_true_high
		ds_sig = Datasetfunction.make_signature("PCT_MOVE", "TRUE_HIGH(F.SP)", "-3", "1")
		assert_equal([[[["F.SP.CLOSE","F.SP.HIGH"],"{|d,v,i| if @ds0[i-1]>@ds1[i] then @ds0[i-1] else @ds1[i] end}"]] ,"{|d,v,i|100*(@ds0[i+1]-@ds0[i+-3])/@ds0[i+-3]}"], ds_sig)
		ds = Dataset.new(ds_sig)
		assert_equal(3.17, ds[44].round(2))
	end
	
	def test_pct_move_1_insts
		ds_sig = Datasetfunction.make_signature("PCT_MOVE", "F.SP.CLOSE", "-3", "1")
		assert_equal([["F.SP.CLOSE"], "{|d,v,i|100*(@ds0[i+1]-@ds0[i+-3])/@ds0[i+-3]}"], ds_sig)
	end

	def test_average_default_attr
		ds_sig = Datasetfunction.make_signature("AVERAGE", "F.SP", "-3", "1")
		assert_equal([["F.SP.CLOSE"], "{|d,v,i| @ds0[i+-3..i+1].inject(0.0) { |sum, v| sum + v.to_f } /5}"], ds_sig)
		ds = Dataset.new(ds_sig)
		assert_equal(109.66, ds[44].round(2))
	end

	def test_average_specified_attr
		ds_sig = Datasetfunction.make_signature("AVERAGE", "F.SP.HIGH", "-3", "1")
		assert_equal([["F.SP.HIGH"], "{|d,v,i| @ds0[i+-3..i+1].inject(0.0) { |sum, v| sum + v.to_f } /5}"], ds_sig)
	end

	def test_true_high
		ds_sig = Datasetfunction.make_signature("TRUE_HIGH","F.SP")
		assert_equal([["F.SP.CLOSE","F.SP.HIGH"],"{|d,v,i| if @ds0[i-1]>@ds1[i] then @ds0[i-1] else @ds1[i] end}"], ds_sig)
	end

	def test_true_low
		ds_sig = Datasetfunction.make_signature("TRUE_LOW","F.SP")
		assert_equal([["F.SP.CLOSE","F.SP.LOW"],"{|d,v,i| if @ds0[i-1]<@ds1[i] then @ds0[i-1] else @ds1[i] end}"], ds_sig)
	end
	
	def test_true_range
		ds_sig = Datasetfunction.make_signature("TRUE_RANGE","F.SP")
		th_sig = Datasetfunction.make_signature("TRUE_HIGH","F.SP")
		tl_sig = Datasetfunction.make_signature("TRUE_LOW","F.SP")
		assert_equal([[th_sig,tl_sig],"{|d,v,i|@ds0[i]-@ds1[i]}"], ds_sig)
	end
	
	def test_true_ATR_as_Average_of_TR
	# user call: ATR("F.SP")
	# DOES call make_average
		ds_sig = Datasetfunction.make_signature("AVERAGE","TRUE_RANGE(F.SP)","-13","0")
		ds = Dataset.new(ds_sig)
		assert_equal(2.65, ds[44].round(2))
	end

	def test_true_ATR_as_ATR_func
	# does NOT call make_average, constructs the average itself
		ds_sig = Datasetfunction.make_signature("AVERAGE_TRUE_RANGE","F.SP","14")
		ds = Dataset.new(ds_sig)
		assert_equal(2.65, ds[44].round(2))
	end
	
	
	#ATR
		#assert_equal([[th_sig,tl_sig],"{|d,v,i|@ds0[i-(14-1)..i].inject(0.0) { |sum, v| sum + v.to_f } /14}"], ds_sig)
=begin
	
=end	
		# make_signature(:dsfunction=>"TRUE_HIGH",:insts=>["F.SP"],:from=>-13,:to=>0)
	#   => [["F.SP.CLOSE","F.SP.HIGH"],"{|d,v,i| if @ds0[i-1]>@ds1[i] then @ds0[i-1] else @ds1[i] end}"]

	
end
