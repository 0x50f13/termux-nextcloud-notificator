require 'httparty'
require 'json'
require 'termux.rb'

module Auth
  def self.authenticate(endpoint, poll_time=2)
      print("=> Authenticating at #{endpoint}\n")
      resp=HTTParty.post("https://#{endpoint}/index.php/login/v2")
      json=JSON.parse(resp.body)
      poll=json["poll"]["endpoint"]
      token=json["poll"]["token"]
      login=json["login"]
      print("=> Opening login page #{login}\n")
      Termux::open_url(login)
      print("=> token=#{token}\n")
      authorised=false
      while not authorised
          resp=HTTParty.post("https://cloud.p01ar.net/index.php/login/v2/poll", :body=> {:token => token})
          print("=> Polling response code #{resp.code}\n")
          if resp.code == 200 then
             authorised=true
          end
          sleep(poll_time)
     end
     print("==> Authentication succeeded\n")
     token=JSON.parse(resp.body)["appPassword"]
     token
  end
end
