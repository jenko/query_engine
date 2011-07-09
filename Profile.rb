class Profile
	attr_reader :id

	def initialize(id, mail)
		if ((id == "") || (id == nil))
			raise ArgumentError
		end
		@id = id
		if ((mail == "") || (mail == nil))
			raise ArgumentError
		end
		@validated_mail = MailAddress.new(mail)
	end
	def mail
		@validated_mail.to_s
	end
end

require 'test/unit'

class ProfileTest < Test::Unit::TestCase
	def test_initialize
		p = Profile.new("root", "root@localhost")
		assert_not_nil(p)
		assert_equal("root", p.id)
		assert_equal("root@localhost", p.mail)
	end
	
	def test_empty_id
		assert_raise(ArgumentError) {
			p = Profile.new("", "root@localhost")
		}		
	end
			
	def test_nil_id
		assert_raise(ArgumentError) {
			p = Profile.new(nil, "root@localhost")
		}		
	end
			
	def test_empty_mail
		assert_raise(ArgumentError) {
			p = Profile.new("root", "")
		}		
	end
			
	def test_nil_mail
		assert_raise(ArgumentError) {
			p = Profile.new("root", nil)
		}		
	end
	
end

class MailAddress
	attr_reader :email
	def initialize email
		if (email == "")
			raise ArgumentError
		end
		@email = email
	end
	def to_s
		@email
	end
end

class MailAddressTest < Test::Unit::TestCase
	def test_initialize
		m = MailAddress.new("root@localhost")
		assert_not_nil(m)
		assert_equal("root@localhost", m.email)
	end
	def test_empty_email
		assert_raise(ArgumentError) {
			m = MailAddress.new("")
		}
	end
	
	def test_to_s
		m = MailAddress.new("root@localhost")
		assert_equal("root@localhost", m.to_s)
	end
end	
	
