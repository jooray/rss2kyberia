# requirements:
# # ruby and sqlite has to be installed
# gem install simple-rss simplehttp sqlite3-ruby htmlentities
# # or for debian:
# apt-get install libopenssl-ruby libgemplugin-ruby libsqlite3-ruby libhtmlentities-ruby
# gem install simple-rss simplehttp
# # or for centos:
# yum install ruby rubygem-simple-rss rubygem-sqlite3-ruby
# gem install htmlentities simplehttp

require 'rubygems'
require 'simple-rss'
require 'open-uri'
require 'sqlite3'
require 'simplehttp'
require 'net/smtp'
require 'net/http'
require 'uri'
require 'htmlentities'


# BEGIN CONFIGURATION

RSS_URI = 'http://SOMEONE.soup.io/rss'

DB_FILENAME = "/home/SOMEONE/.soup/soupstore.db"

KYBERIA_NODE = "123456"
KYBERIA_USER_ID = "123456"
KYBERIA_USER_PASS = "..."

ERROR_EMAILS = "email@address.com"
SMTP_SERVER = "192.168.1.1"

POST_LIMIT = 3

# END CONFIGURATION

# MAIL METHODS (FOR ERROR HANDLING)

def send_error_email(destination, body, attachement)

  encodedcontent = [attachement].pack("m")   # base64

  marker = "AUNIQUEMARKER"

  # Define the main headers.
  part1 =<<EOF
From: Kyberia posting robot <#{destination}>
To: <#{destination}>
Subject: Problem posting content
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=#{marker}
--#{marker}
EOF

  # Define the message action
  part2 =<<EOF
Content-Type: text/plain
Content-Transfer-Encoding:8bit

#{body}
--#{marker}
EOF

  # Define the attachment section
  part3 =<<EOF
Content-Type: multipart/mixed; name="attach.html"
Content-Transfer-Encoding:base64
Content-Disposition: attachment; filename="attach.html"

#{encodedcontent}
--#{marker}--
EOF

  mailtext = part1 + part2 + part3

  begin
    Net::SMTP.start(SMTP_SERVER) do |smtp|
      smtp.sendmail(mailtext, destination,
        destination)
    end
  rescue Exception => e
    print "Exception occured: " + e
  end
end

# KYBERIA HANDLING METHODS
def get_phpsessid(setcookie)
	phpsessid = ""
	setcookie.each do |x|
  	  if (x =~ /phpsessid/i)
		phpsessid = x.split(";")[0]
	  end
	end
	phpsessid
end


def login_kyberia(id, password)
  url = URI.parse("http://kyberia.sk/id/#{id}")
  req = Net::HTTP::Post.new(url.path)

  query = {
    "login" => id,
    "password" => password,
    "event" => "login",
    "login_type" => "id",
    "screen_width" => "1024",
    "screen_height" => "768"
  }

  req.set_form_data(query)
  res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
  case res
  when Net::HTTPRedirection
      phpsessid = get_phpsessid(res.get_fields('Set-Cookie'))
  else
    res.error!
  end
  phpsessid
end

def post_kyberia(phpsessid, parent_node, title, content)
  http = SimpleHttp.new "http://kyberia.sk/id/#{parent_node}/"
  http.request_headers["Cookie"] = phpsessid
  query = {
    "node_name" => title,
    "node_content" => content,
    "event" => "add",
    "template_id" => "4",
    "sel_help" => "",
    "get_children_offset" => "0",
    "listing_amount" => "23",
    "search_type" => "title_content",
    "node_parent" => parent_node,
    "new_parent" => "",
    "nodeshell_id" => "",
    "nodeshell_id_select" => "23",
    "get_children_offset" => "0"
  }
  http.post query
end

def is_post_okay(html)
  if (html =~ /center.*span align=.center. class=.most_important./i)
    false
  else
    true
  end
end

def deobjectize(description)
  if (description =~ /(http:\/\/www.youtube.com\/[^"]*)"/)
 	description
  else
  if (description =~ /<object/i) 
    url = "Embedded object removed because of new Kyberia security, click to original link to see it.<p>"
    description.gsub!(/<object.*<\/object>/i, url)
  end
  end
  description
end

phpsessid = nil

db = SQLite3::Database.new( DB_FILENAME )

db.execute( "create table if not exists seen_uuids (uuid text)" )


rss = SimpleRSS.parse open(RSS_URI)
coder = HTMLEntities.new

posted = 0

for i in rss.items.reverse do
  count = db.get_first_value( "select count(*) from seen_uuids where uuid = ?",
    i.guid)

  if count.to_i == 0 then
    posted+=1
    if phpsessid.nil? then
      phpsessid = login_kyberia(KYBERIA_USER_ID, KYBERIA_USER_PASS)
    end

    body = <<EOPOST
    #{deobjectize(coder.decode(i.description))}<p/><a href="#{i.link}">(original post)</a>
EOPOST
    title = coder.decode(i.title)

    puts "Posting #{i.guid}: #{title}"

    ret = post_kyberia(phpsessid, KYBERIA_NODE, title,
      body)

    unless (is_post_okay(ret))
      puts "Posting failed, sending error e-mail to #{ERROR_EMAILS}"
      body = <<EOPOST

Could not handle post:

      #{i.title}
      #{i.link}
      #{i.description}
      #{i.guid}

Will not try to repost this one again, you can find the error
page as an attachement to this e-mail.
EOPOST
      send_error_email(ERROR_EMAILS, body, ret)
    end

    db.execute("insert into seen_uuids (uuid) values (?)", i.guid)

  end
  break if posted >= POST_LIMIT
end

db.close
