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
file_size = file.size
file_name = file_path.split("/") # normalizing file name from "/../../file"
file_name = file_name.last       # to "file"
# description string "file_name::file_size::block_size" is formed here: 
file_description = file_name + "::" + file_size.to_s + "::" + block_size.to_s

client = Addrinfo.tcp(server_address, server_port) # connecting to server
server = client.connect
p "Connected"
server.send(file_description,0)
p "Description is sent"
p "Sending file to server:"
while (bytes_sent < file_size) do
  packet = file.read(block_size)
  server.send(packet,0)
  bytes_sent = bytes_sent + packet.size
  if (bytes_sent > (file_size/100*percentage))
  	p "More than #{percentage}% of file has been transferred."
  	server.send(percentage.chr,Socket::MSG_OOB)
  	percentage = percentage + 10
  end
end


