require 'socket'

help_array = ["-h","help","--help"] # help info
if help_array.include?(ARGV[0])
  p "Transmission client usage is:"
  p "tr_client.rb [server_IP] [server_port] [file_name] (MTU) (timeout)"
  p "[] - required attribute, () - optional attribute"
  exit
end

server_address = ARGV[0] # client side params
server_port = ARGV[1].to_i
file_name = ARGV[2]
current_block = 0
if ARGV[3]
  MTU = ARGV[3].to_i
else
  MTU = 1400
end
if ARGV[4]
  timeout = ARGV[4].to_i
else
  timeout = 10
end
PR_size = 1024 # protocol message size

file = File.open(file_name) # working with file
file_size = file.size
fname = file_name.split("/") # normalizing file name from "/../../file"
fname = fname.last           # to "file"
blocks_num = file_size / MTU 
blocks_num = blocks_num + 1 if (file_size - blocks_num * MTU != 0) # block for the rest of file
# description string "File_name::size::MTU::blocks_num::timeout" is formed here: 
file_description = fname + "::" + file_size.to_s + "::" + MTU.to_s + "::" + blocks_num.to_s + "::" + timeout

client = Addrinfo.tcp(address, port) # connecting to server
server = client.connect
server_state = sever.recv(PR_size) 
server_state = server_state.split("::") # server_state[0] - state; 
# server_state[1] - file name; server_state[2] - current block

if (server_state[0] == "ready") # server is ready to accept file
  server.send(file_description,0)
  while (current_block < blocks_num)
    packet = file.read(MTU)
    server.send(packet,0)
  #не дописан case
#elsif (server_state[0] == "aborted" and server_state[1] == fname) # file reloading
  #не дописан case
else # server is waiting for another file to be reloaded
  p "Server is waiting for another file to be reloaded"
end
  

