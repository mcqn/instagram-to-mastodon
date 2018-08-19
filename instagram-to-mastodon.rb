#!/usr/bin/ruby
#encoding: utf-8
# instagram-to-mastodon

require 'yaml'
require 'instagram'
require 'nokogiri'
require 'open-uri'
require 'mastodon'
require 'pp'

# Read in config
settings = nil
if ARGV.length == 1
  settings = YAML.load_file(ARGV[0])
else
  puts "No configuration provided."
  exit
end
instagram_settings = settings["instagram"]
mastodon_settings = settings["mastodon"]

#
# Get Instagram weeknotes
#
Instagram.configure do |config|
  config.client_id = instagram_settings["client_id"]
  config.client_secret = instagram_settings["client_secret"]
end
if instagram_settings["auth_code"].nil? || instagram_settings["auth_code"].empty?
  # First time round, go to the URL output below
  puts "You need to authorize this client for your account."
  puts
  puts "Go to "+Instagram.authorize_url(:redirect_uri => "http://mcqn.com")
  puts
  puts "Once authorized, copy the code in the redirected URL into the 'auth_code:' section of your config.yaml file."
  puts "It will have been of the form 'http://mcqn.com/?code=<code is here>'"
  puts
  puts "After you save it into your config.yaml file, run this again"
  exit
end

if instagram_settings["access_token"].nil? || instagram_settings["access_token"].empty?
  # Second time through run this code, to get an access token, and save it for later use
  response = Instagram.get_access_token(instagram_settings["auth_code"], :redirect_uri => "http://mcqn.com")
  puts "This is your 'access_token'.  Copy it into your config.yaml file"
  puts "    "+response.access_token.inspect
  puts
  puts "After you save it into your config.yaml file, running this again will post any new Instagram posts to Mastodon."
  exit
end
 
if mastodon_settings["bearer_token"].nil?
  puts "You need to create an application on Mastodon - e.g. in #{mastodon_settings['server']}/settings/applications and then copy your access token here."
  exit
end

mastodon = Mastodon::REST::Client.new(base_url: mastodon_settings["server"], bearer_token: mastodon_settings["bearer_token"])

puts "Checking Instagram..."
# Then normal usage is just to use the access token we've saved
client = Instagram.client(:access_token => instagram_settings["access_token"])
latest_post = settings["most_recent_post_time"].to_i
for media_item in client.user_recent_media.reverse
# FIXME Need to track the latest post and save that back to the config YAML file
  if media_item.created_time.to_i > settings["most_recent_post_time"].to_i
    #pp media_item
    puts "New post!"
    latest_post = media_item.created_time.to_i if media_item.created_time.to_i > latest_post
    media = []
    more_media = []
    # Download each image and upload it to Mastodon
    # The Instagram API only gives links to 640x640 pixel images, whereas it embeds a link to
    # a 1080x1080 pixel image in the card metadata for the page.  For now, we'll download the main
    # image and provide a link to the Instagram post if there are more, or videos
    post = Nokogiri::HTML(open(media_item.link))
    img = post.at_css("meta[property='og:image']")['content'] #this might only work for single image posts
    img_url = URI.parse(img)
    img_file = File.basename img_url.path
    `wget #{img_url.to_s} -O 'tmp_download/#{img_file}'`
    # Upload it to Mastodon
    # Need to create the right data type for the upload
    hf = HTTP::FormData::File.new(File.open("tmp_download/#{img_file}", "rb"))
    media.push(mastodon.upload_media(hf).id)
    unless media_item.carousel_media.nil?
      more_media.push("more")
    end
    unless media_item.videos.nil?
      more_media.push("video")
    end
    caption = media_item.caption["text"]
    unless more_media.empty?
      # Append a link to more media...
      caption = caption+" ("+more_media.join('/')+" at #{media_item.link})"
    end
    # Now create a new status with the media_ids
pp caption
pp media
# FIXME This will need checking once issue #9 in mastodon-api is fixed
    mastodon.create_status(caption, nil, media)
  end
end

# Remember where we got to
settings["most_recent_post_time"] = latest_post
File.open(ARGV[0], "r+") do |file|
  file.write(settings.to_yaml)
end


