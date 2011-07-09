require 'redis'
module QueryServer
	class InvalidDatasetBlockError < ArgumentError; end
	class UnresolvableInstrumentError < ArgumentError; end
end

class DatasetSignature
	attr_reader :actual_signature
	attr_reader :block_str
	attr_reader :is_db_set
	attr_reader :block_is_valid
	attr_reader :insts
	
	
	def initialize signature
		@actual_signature = signature
		if db_set?
			@is_db_set = true
			@block_str = nil
			@block_is_valid = false 
		elsif valid_signature_block?
			@is_db_set = false
			@block_str = @actual_signature[1]
			@block_is_valid = true
		else
			raise QueryServer::InvalidDatasetBlockError
		end
		set_insts
	end

	private	
	def db_set?
		#db_set? == true iff there is a single instrument and no block;
		#   the single instrument can be in an array or not
		#   e.g. ["F.SP.CLOSE"] or "F.SP.CLOSE"
		sig_is_array = @actual_signature.kind_of?(Array)
		result = false
		if sig_is_array && @actual_signature.length == 1
			true
		elsif !sig_is_array
			true
		else
			false
		end
	end
	
	def valid_signature_block?
		if @actual_signature.length > 1
			sig_proc_str = @actual_signature[1]
			valid_block?(sig_proc_str)
		else
			false
		end
	end

	def valid_block?(block_str)
		begin
			eval("Proc.new " + block_str).arity > 0
		rescue
			false
		end
	end
	
	def set_insts
		@insts = []
		if @actual_signature.kind_of?(Array)
			if @actual_signature[0].kind_of?(Array)
				@actual_signature[0].each {|s| @insts << s}
			else
				@insts = [@actual_signature[0]]
			end
		else
			@insts = [@actual_signature]
		end
	end
	
end

class Dataset
#TODO:
# 0. clean up the query syntax.  Perhaps now would be a good time to work on the DSL
# 0.1 change initialize so it takes an array=>:DONE
# 1. handle nested functions=>:DONE(!!!)
#	 e.g. AverageTrueRange, which is the average of the TrueRange, which itself is the diff between the TrueHigh and TrueLow,
#    which themselves are derived from Close(-1), High, and Low; SO, we need to be able to 
#    1: identify sub elements as sub-datasets and
#    2: create those sub-datasets from the (sub)signature supplied in the (super)dataset signature
#
# 2. update class so ds_sig (the dataset part of the signature) can indicate if a dataset in the ds_sig array
#    is an instrument (perhaps prefix with "INST:") or a derived value ("DRVD:");
#    this way the code can know whether it should attempt to create the value if it's not already in the db
#    ==> "INST:" cannot be created, it's either in the db or not; "DRVD:" may be created
#    NO.  The code will know if it can't create the subdataset, and if that's the case, it will raise an error =>:DONE
# 3. Storing Dataset objects: do we want to change the Redis structure to hash (it's currently 2 arrays per dataset,
#    a value array and a date array -- and a hash that points the value array at the date array)
#    why do we currently use arrays?  what would be gained by using hashes?
# 4. premade functions -- "Friendly Names" -- (pct_move, move, average, etc), so we don't have to spell it all out every time
# 5. tried persisting derived ds's to the redis db -- what a dog!  both reading AND writing.  not gonna do THAT again
#    -- in fact, I might not even use Redis anymore!
# 6. Multi-subdataset queries might go a lot quicker if we "merge" (not ruby hash merge) the subdataset arrays into a single array
#    so that instead of 3 subdataset date_value_hsh's, we have a single one, except the "value" is now itself an array, e.g., [v1,v2,v3]
	attr_reader :signature
	attr_reader :values
	attr_reader :dates
	attr_reader :sub_datasets
	attr_reader :date_value_hsh
	attr_reader :sig_proc_str
	attr_reader :insts
	
# 4 cases
# 1. [ds1, ds2, ...] {non-empty block}
#	use the datasets in the block to create new values
# 2. [ds1, ds2, ...] {empty block}
#	:DONE=>TODO: should either default to ds1 or raise error
# 3. [ds1] {non-empty block}
#	(i.e., array of one element) values are block applied to ds
# 4. [ds1] {empty block}
#	just the ds
# BUT, each ds (e.g., ds1) can be a [ds1a, ds1b] {non-empty block} sig itself
	def initialize(ds_sig)
		@signature = DatasetSignature.new(ds_sig)
		@db = Redis.new
		@values = []	
		@dates = []
#		puts "top: ds_sig: #{ds_sig}"
		if @signature.is_db_set
#			puts "in if @signature.is_db_set, @signature.is_db_set = #{@signature.is_db_set}" 
			@inst = @signature.insts[0]
#			puts "@inst: #{@inst}"
			if @db.exists(@inst)
#				puts "db.exists"
				date_source = @db.hget("dates_hash", @inst)
				@values = load_data(@inst, ".to_f")
				@dates = load_data(date_source)
				@date_value_hsh = make_dv_hash(@dates, @values)
				@ds0 = self
				#make_ds_meth "@ds0", 0
			else
				raise QueryServer::UnresolvableInstrumentError
			end
		elsif @signature.block_is_valid
			# it must have a block
			@sig_proc =  eval("Proc.new " + @signature.block_str)
			@sub_datasets = get_sub_datasets(@signature)
#			puts "@sub_datasets.size: #{@sub_datasets.size}"
			reconcile
			make_values &@sig_proc
		else
			raise QueryServer::InvalidDatasetBlockError
		end
	end # def

	def is_db_set
		@signature.is_db_set
	end
	
	def [](x)
		@values[x]
	end

	private

	def get_sub_datasets(ds_sig)
#	puts "in get_sub_datasets"
		sub_datasets = {}
		@signature.insts.each_with_index do |sds,i|
			sub_datasets[sds] = Dataset.new(sds)
			ds_str = "@ds" + i.to_s
			# next line creates instance variables for each dataset, @ds0, @ds1, etc
			eval(ds_str + " = sub_datasets[sds]")
#			puts "after 1st eval"
#			puts "@ds0.values[44]: #{@ds0.values[44]}"
			#make_ds_meth ds_str, i
		end
#		puts "ds0(44..48): #{ds0(44..48)}"
		sub_datasets
	end

	def make_ds_meth ds_str, i
		block_str = "{|x| " + ds_str + ".values[x]}" # {@ds1.values[x]}
		self.class.send(:define_method, ("ds"+i.to_s).to_sym, instance_eval("Proc.new #{block_str}"))
	end
	
	def load_data(list_to_load, format="")
		result = []
		(@db.lrange list_to_load, 0, -1).each do |v| 
			result << eval("v" + format)
		end
		result
	end
	
	def make_dv_hash(dates_ary, values_ary)
		result = {}
		dates_ary.each_with_index do |d,i| 
			result[d] = values_ary[i]
		end
		result
	end

	def make_values(&sig)
#		puts "@signature.actual_signature: #{@signature.actual_signature}"
#		puts "@ds0.values.size: #{@ds0.values.size}"
		i = -1
		@date_value_hsh.merge!(@date_value_hsh) do |k,ov|
			i += 1
#			if i == 44 then puts "@ds0.dates[i]: #{@ds0.dates[i]}"; end
#			if i == 44 then puts "@ds0.values[i]: #{@ds0.values[i]}"; end
#			if i == 44 then puts "@date_value_hsh[19820624]: #{@date_value_hsh[19820624]}"; end
#			if i == 44 then puts "@date_value_hsh.size: #{@date_value_hsh.size}"; end
			
			begin
				if sig.arity > 0 
					yield k,ov,i
				else
					ov
				end
			rescue Exception => e
				if i == 44
#	 				puts "e.message: #{e.message}"
##					puts "e.backtrace.inspect: #{e.backtrace.inspect}"
					raise
				end
				"N/A"
			end
		end
		@values = Array.new(@date_value_hsh.values)
	end

	def reconcile
	# makes sure that, when this (super)dataset contains multiple (sub)datasets,
	#  all (sub)datasets start at the same date
		if @sub_datasets.size == 1
		# then just set the this (super)dataset's dates and values to the one sub_dataset 
			@dates = @ds0.dates
			@values = @ds0.values
			@date_value_hsh = make_dv_hash(@dates, @values)
		else
			latest_first_date = 0
			latest_ds_index = -1
			i = -1
			@sub_datasets.each_value do |sub_ds|
				#find the most recent date in the first entries of each dataset
				i += 1
				if sub_ds.date_value_hsh.keys.first.to_i > latest_first_date
					latest_first_date = sub_ds.date_value_hsh.keys.first.to_i
					latest_ds_index = i
				end
			end
			@sub_datasets.each_value do |sub_ds|
				# remove any k,v pairs where k < (i.e., before) latest_first_date
				sub_ds.date_value_hsh.reject! {|k,v| k.to_i < latest_first_date}
			end
			@date_value_hsh = {}
			#below says, "get the first dataset in datasets_hsh, and then iterate thru each of the latter's
			#  k,v pairs, and set @date_values_hsh(k,v) to k,0; this is just a way of initializing @date_values_hsh
			@sub_datasets[@sub_datasets.keys[i]].date_value_hsh.each_key {|k| @date_value_hsh[k] = 0}
			@dates = @sub_datasets[@sub_datasets.keys[i]].date_value_hsh.keys
		end
	end

end # class


