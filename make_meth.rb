class Dave

	def make_meth(name, string)
		self.class.send(:define_method, name.to_sym, instance_eval("Proc.new #{string}"))
	end

	def make_lots(num_to_make)
		num_to_make.times do |i|
			block_str = "{|x| puts \"x is \#{x}\"}" # {@ds1.values(x)}
			self.class.send(:define_method, ("ds"+i.to_s).to_sym, instance_eval("Proc.new #{block_str}"))
		end
	end

end





=begin

block_str = "{|x| puts \"inner string plus x: \#{x}\" } "

I want to be able to create methods ds1, ds2, etc
which look like
  def ds1(x)
  	@ds1.values(x)
  end
  
  
=end
