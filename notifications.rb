require 'httparty'
require 'termux.rb'
require 'logging.rb'

def download_file(url, filename)
      File.open(filename, "w+") do |file|
        file.binmode
        HTTParty.get(url, stream_body: true) do |fragment|
          file.write(fragment)
        end
      end
end

module Notifications
   class <<self
       attr_accessor :displayed
   end

   @displayed=Set.new([])
   def self.poll(endpoint, user, appPassword)
       resp=HTTParty.get("https://#{endpoint}/ocs/v2.php/apps/notifications/api/v2/notifications", :basic_auth => {:username => user, :password => appPassword}, :headers => {"Accept" => "application/json"})
       notifications=resp.parsed_response["ocs"]["data"]
       display=[]
       notifications.each do |notification|
          if @displayed.add?(notification["notification_id"]) != nil then
             display<<notification
          end
       end
       display
   end

   def self.display_notification(notification)
       furl=notification["icon"]
       fname=furl.split("/")[-1]
       download_file(furl,Dir.pwd+"/.cache/"+fname)
       Logging::debug("Sending notification: #{notification["message"]}")
       Termux::notify(content=notification["message"], group=notification["app"], n_id=notification["notification_id"], title=notification["subject"], image=Dir.pwd+"/.cache/"+fname)
   end

   def self.start_polling(endpoint, user, appPassword, sleep_time=5)
       while true
        begin
	  Logging::debug("Polling new messages")
	  notifications=self.poll(endpoint, user, appPassword)
          notifications.each do |notification|
              self.display_notification(notification)
          end
        rescue Exception => e
          Logging::error("Exception while polling: #{e.message}")
        end
        sleep(sleep_time)
       end
  end
end 
