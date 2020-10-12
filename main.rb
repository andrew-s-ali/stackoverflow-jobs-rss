require "rss"
require "open-uri"
require "yaml"

config = YAML.load_file('config.yml')

OUTFILE="#{File.dirname(__FILE__)}/jobs-category-count-#{Time.now.strftime("%Y%m%d")}.txt"
if File.exist? OUTFILE
	File.delete OUTFILE
end

OUTFILE_YESTERDAY="#{File.dirname(__FILE__)}/jobs-category-count-#{(Time.now-60*60*24).strftime("%Y%m%d")}.txt"

techs = {}
interested_techs = {}

url = "http://stackoverflow.com/jobs/feed"
open(url) do |rss|
	feed = RSS::Parser.parse(rss)
	#puts "Title: #{feed.channel.title}"
	feed.items.each do |item|
		item.categories.each do |category|
			if techs[category.content]
				techs[category.content] += 1
			else
				techs[category.content] = 1
			end
		end
	end
end

techs = techs.sort_by(&:last).to_h

File.open OUTFILE, "w" do |file|
	techs.each do |k, v|
		if config["interested_in"].include? k
			interested_techs[k] = v.to_i
			file << k
			file << ": "
			file << interested_techs[k]
			file << "\n"
		end
	end

	techs_yesterday = {}
	file << "\n# Difference from yesterday\n"

	File.open OUTFILE_YESTERDAY, "r" do |file_yesterday|
		file_yesterday.readlines.each do |line|
			break if line[0].eql? "\n"
			tech = line[0, line.index(":")]
			count = line[line.index(" ")+1, line.length].to_i
			techs_yesterday[tech] = count
		end
	end

	pp interested_techs
	
	techs_yesterday.each do |k, v|
		if interested_techs[k]
			file << k
			file << ": "
			count_diff = techs[k] - v
			count_diff = count_diff > 0 ? "+#{count_diff}" : count_diff 
			file << count_diff
			file << "\n"
		end
	end
end