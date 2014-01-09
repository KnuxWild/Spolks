require 'socket'
require 'timeout'

help_array = ["-h","help","--help"] #help info
if (help_array.include?(ARGV[0]) or !ARGV[0])
  p "Transmission server usage is:"
  p "tr_server.rb [server_IP] [server_port]"
  exit
end

server = UDPSocket.open
server.bind('192.168.1.2',2020)

file = File.open("En.pdf","w")
loop do
  until packet = server.recvfrom(1024) do
    UDPSocket.open.send("+",0,'192.168.1.9',2020)
  end
  file.write(packet)
end

file.close