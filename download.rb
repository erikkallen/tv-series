require 'yaml'
require 'simple-rss'
require 'yaml'
require 'open-uri'
require 'to_name'
require 'tvdbr'
require 'colorize'
require './try'
require 'titleize'
require 'xml-object'
require 'transmission-client'

config = YAML.load( open("download.yaml") )

# Find locally available series

torrents_to_download = []

local_series = Dir["#{config['series_dir']}/{#{config['series'].join(',')}}/*/*.{avi,mkv,mp4}"].collect { |a| File.basename(a) }
series = {}
# Locally available
puts "Localy available:"
local_series.each do |item|
  info = ToName.to_name(item)
  ((series[info.name.downcase] ||= {})[info.series] ||= []) << info.episode
  #puts "#{info.name.try(:colorize,:blue)} Series: #{info.series.to_s.try(:colorize,:yellow)} Episode: #{info.episode.to_s.try(:colorize,:light_yellow)}"
end

# Requested series
puts "Requested series: "
series.each do |name,item|
  #puts "#{name} #{item}"
  last_season = item.max_by{|k,v| k.to_i }.first
  #puts last_season.inspect
  last_episode = item[last_season].max
  puts "#{name.titleize} latest episode: s#{last_season}e#{last_episode}"
  
  puts "Checking online for new episodes"

  # Remote availale
  remote_series = {}
  #puts rss.channel.title # => "Slashdot"
  #puts rss.channel.link # => "http://slashdot.org/"
  SimpleRSS.item_tags << "torrent"
  rss = SimpleRSS.parse open("https://www.ezrss.it/search/index.php?show_name=#{URI::encode(name)}&mode=rss")
  rss.items.each do |item|
    info = ToName.to_name(item.link)
    unless info.series.nil? or info.episode.nil?
      #info_torrent = {}
      #item.torrent.scan(/<([^>]+)>([^<]+)<\/[^>]+>/) do |m|
      #  info_torrent[m[0]] = m[1]
      #end
      ((remote_series[info.name.downcase] ||= {})[info.series] ||= {})[info.episode] = {torrent_url:item.link}
      
      #puts "Item #{info.name} #{info.series} #{info.episode} #{info_torrent['magnetURI']}"
    end
  end
  
  remote_series.each do |name,item|
    #puts "#{name} #{item}"
    last_remote_season = item.max_by{|k,v| k.to_i }.first
    #puts last_season.inspect
    last_remote_episode = item[last_season].max_by{|k,v| k }.first
    puts "Remote #{name.titleize} latest episode: s#{last_season}e#{last_episode}"
    if (last_remote_season > last_season or (last_remote_season == last_season && last_remote_episode > last_episode))
      puts "New episode found downloading #{item[last_season][last_remote_episode][:torrent_url]}"
      torrents_to_download << {torrent:item[last_season][last_remote_episode][:torrent_url],download_dir:"#{config['series_dir']}/#{name.titleize}/Season #{last_remote_season}/"}
    else
      puts "No new episodes found"
    end
  end
  
end


EventMachine.run do
  t = Transmission::Client.new
  
  torrents_to_download.each do |torr|
    
    f = open(torr[:torrent].sub("[", "%5B").sub("]", "%5D"))
        # Create download directory
	FileUtils.mkdir_p torr[:download_dir]
	t.add_torrent('metainfo' => Base64.strict_encode64(f.read), 'download-dir' => torr[:download_dir] ) do |torrent|
        puts torrent.inspect
    	#torrent.downloadDir =
	t.get_torrent(torrent.values[0]["id"]) do |t2|
        	#puts t2.inspect
		torrent_info = ToName.to_name(t2.name) 
		puts "Added #{t2.name}"
		#new_dir = "#{config['series_dir']}/#{torrent_info.name.titleize}/Season #{torrent_info.series}/"
		#puts "Moving to #{new_dir}"
		#t2.location = new_dir
	end
  end
    #t.add_torrent('metainfo' => torr)
  end
  EM.add_periodic_timer(5) do
    EventMachine.stop
  end
end
