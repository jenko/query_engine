require 'redis'

class Datasetfunction

	def self.make_signature(func_name, *args)
		func_sym = ("make_" + func_name.downcase).to_sym
		Datasetfunction.send func_sym, args	
		
	end
	
	def self.create_datasetfunction
	# we're getting ahead of ourselves, but at some point we'll want to be able to have
	#   a(n elegant) mechanism for putting these things into the db
	#
	# but for right now, we're just going to write the code that'll put the function into the db
		db = Redis.new
		
	end
	
	def self.get_insts_sigs insts
	# takes args_hash[:insts]
	# makes sig for each one
	# returns array of sigs
	end
	
	def self.sub_func inst
		func = inst.split("(")[0]
		args = inst.split("(")[1].split(")")[0]
		[func, args]
	end
	
	def self.is_func?(inst)
		inst.include?("(")
	end
	
	def self.get_for_range_func(args)
	# returns from, to, resolved array of inst sigs, and second ds var string
		from = args[(args.size-2)]
		to = args[(args.size-1)]
		insts = args[0..args.size-3]
		insts_sig = []
		insts.each do |inst|
			if is_func?(inst)
				inst_func = sub_func(inst)
#				puts "inst_func: #{inst_func}"
				insts_sig << make_signature(inst_func[0], inst_func[1])
			else
				inst_parts = inst.split('.')
				if inst_parts.size == 2
					insts_sig << inst + ".CLOSE"
				else
					insts_sig << inst
				end
			end				
		end	
		if insts.size == 2
			second_ds = "@ds1"
		else
			second_ds = "@ds0"
		end
		[from, to, insts_sig, second_ds]	
	end
	
	def self.make_pct_move(args)
	# for pct_move, there may be 3 or 4 args
	# if 3, then it's pctmove on the same dataset
	# if 4, then it's pctmove on 2 different datasets
		rng_func_params = get_for_range_func(args)
		from = rng_func_params[0]
		to = rng_func_params[1]
		insts_sig = rng_func_params[2]
		second_ds = rng_func_params[3]
		block_str = "{|d,v,i|100*(" + second_ds + "[i+" +to+ "]-@ds0[i+"+from+"])/@ds0[i+"+from+"]}"
		[insts_sig,block_str]
	end
	
	def self.make_average(args)
		rng_func_params = get_for_range_func(args)
		from = rng_func_params[0]
		to = rng_func_params[1]
		insts_sig = rng_func_params[2]
		second_ds = rng_func_params[3]
		total = (to.to_i - from.to_i + 1).to_s
		block_str = "{|d,v,i| @ds0[i+" +from+ "..i+" +to+ "].inject(0.0) { |sum, v| sum + v.to_f } /" +total+ "}"
		[insts_sig, block_str]
	end
	
	def self.make_true_high(args)
		ds0 = args[0] + ".CLOSE"
		ds1 = args[0] + ".HIGH"
		block_str = "{|d,v,i| if @ds0[i-1]>@ds1[i] then @ds0[i-1] else @ds1[i] end}"
		[[ds0,ds1],block_str]
	end
	
	def self.make_true_low(args)
		ds0 = args[0] + ".CLOSE"
		ds1 = args[0] + ".LOW"
		block_str = "{|d,v,i| if @ds0[i-1]<@ds1[i] then @ds0[i-1] else @ds1[i] end}"
		[[ds0,ds1],block_str]
	end

	def self.make_true_range(args)
		ds0 = make_true_high(args)
		ds1 = make_true_low(args)
		block_str = "{|d,v,i|@ds0[i]-@ds1[i]}"
		[[ds0,ds1],block_str]
	end
	
	def self.make_average_true_range(args)
		make_average(["TRUE_RANGE(" + args[0] + ")", (1-args[1].to_i).to_s ,"0"])
	end
end















