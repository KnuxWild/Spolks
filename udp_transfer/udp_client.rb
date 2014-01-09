require 'socket'

help_array = ["-h","help","--help"] # help info
if (help_array.include?(ARGV[0]) or !ARGV[0])
  p "Transmission client usage is:"
  p "tr_client.rb [server_IP] [server_port] [file_path] (block_size)"
  p "[] - required attribute, () - optional attribute"
  exit
end

server_address = ARGV[0] # client side params
server_port = ARGV[1].to_i
file_path = ARGV[2]
block_size = (ARGV[3] || "102400").to_i
bytes_sent = 0
percentage = 10

file = File.open(file_path) # working with file

p "Sending file to server:"
while (bytes_sent < file_size) do
  packet = file.read(block_size)
  UDPSocket.open.send(packet,0,server_address, server_port)
  bytes_sent = bytes_sent + packet.size
end


