require 'csv'
require 'redis'
require 'benchmark'

#spfile = CSV.open("./SP.OHLC.csv")
spfile = CSV.open("./SP.OHLC.061311.csv")
db = Redis.new

# load data as lists
spfile.rewind
spfile.each_with_index do |r,i|
  begin	
	  date_parts = r[0].split("/")
	  date_parts.map! { |p| p.size == 1 ? "0" + p : p }
	  
	  db.rpush "F.SP.DATE", date_parts[2] + date_parts[0] + date_parts[1] 
	  db.rpush "F.SP.DOWK", r[1]
	  db.rpush "F.SP.OPEN", r[2]
	  db.rpush "F.SP.HIGH", r[3]
	  db.rpush "F.SP.LOW", r[4]
	  db.rpush "F.SP.CLOSE", r[5]
  rescue
  end
end
# now populate dates_hash with the key being the data set, and the value being the name of the date sorted set
db.hset "dates_hash", "F.SP.DOWK", "F.SP.DATE"
db.hset "dates_hash", "F.SP.OPEN", "F.SP.DATE"
db.hset "dates_hash", "F.SP.HIGH", "F.SP.DATE"
db.hset "dates_hash", "F.SP.LOW", "F.SP.DATE"
db.hset "dates_hash", "F.SP.CLOSE", "F.SP.DATE"


