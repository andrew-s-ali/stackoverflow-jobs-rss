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
URI.open(url) do |rss|
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
	file << "Subject: Technology category differences for #{Time.now.strftime("%m/%d/%Y")}\n\n"

	techs.each do |k, v|
		if config["interested_in"].include? k
			interested_techs[k] = v.to_i
			file << k
			file << ": "
			file << interested_techs[k]
			file << "\n"
		end
	end

	if File.exist? OUTFILE_YESTERDAY
		techs_yesterday = {}
		file << "\n# Difference from yesterday\n"

		File.open OUTFILE_YESTERDAY, "r" do |file_yesterday|
			file_yesterday.readlines.each do |line|
				if line.eql? "\n"
					next
				elsif line[0].eql? "#"
					break
				end
				tech = line[0, line.index(":")]
				count = line[line.index(" ")+1, line.length].to_i
				techs_yesterday[tech] = count
			end
		end

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
end

# mail it to given address

email = ARGV[0]

# raspberry pi users should use msmtp

system("msmtp #{email} < #{OUTFILE}")