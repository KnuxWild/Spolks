require 'socket'
require 'timeout'

help_array = ["-h","help","--help"] # help info
if (help_array.include?(ARGV[0]) or !ARGV[0])
  p "Transmission client usage is:"
  p "tr_client.rb [server_IP] [server_port] [file_path] (block_size) (timeout)"
  p "[] - required attribute, () - optional attribute"
  exit
end

server_address = ARGV[0] # client side params
server_port = ARGV[1].to_i
file_path = ARGV[2]
current_block = 0
block_size = (ARGV[3] || "14000").to_i
timeout = (ARGV[4] || "20").to_i
PR_size = 1024 # protocol message size

file = File.open(file_path) # working with file
file_size = file.size
file_name = file_path.split("/") # normalizing file name from "/../../file"
file_name = file_name.last           # to "file"
blocks_num = file_size / block_size 
blocks_num = blocks_num + 1 if (file_size - blocks_num * block_size != 0) # block for the rest of file
# description string "file_name::size::block_size::blocks_num::timeout" is formed here: 
file_description = file_name + "::" + file_size.to_s + "::" + block_size.to_s + "::" + blocks_num.to_s + "::" + timeout.to_s

client = Addrinfo.tcp(server_address, server_port) # connecting to server
server = client.connect
p "Connected"

server_state = server.recv(PR_size) 
server_state = server_state.split("::") # server_state[0] - state; 
# server_state[1] - file name; server_state[2] - current block;
# server_state[3] - block_size
p "Transferring state: #{server_state[0]}"
p "The latest file block on server: #{server_state[2]}"

if (server_state[0] == "ready") # server is ready to accept file
  server.send(file_description,0)
  p "Description is sent"
  p "Sending file to server:"
  while (current_block < blocks_num) do
    begin 
      status = Timeout::timeout(timeout) do
        packet = file.read(block_size)
        server.send(packet,0)
        print "."
        current_block = current_block + 1
      end
    rescue Timeout::Error
      p "Connection seems to be aborted."
      file.close
      break
    end
  end

elsif (server_state[0] == "aborted" and server_state[1] == file_name) # file reuploading
  file = File.open(file_path, "r")
  current_block = server_state[2].to_i
  block_size = server_state[3].to_i
  file.read(current_block * block_size)
  p "Reuploading file:"
  while (current_block < blocks_num) do
    begin 
      status = Timeout::timeout(timeout) do
        packet = file.read(block_size)
        server.send(packet,0)
        print "."
        current_block = current_block + 1
      end
    rescue Timeout::Error
      p "Connection seems to be aborted."
      file.close
      break
    end
  end
else # server is waiting for another file to be reloaded
  p "Server is waiting for another file to be uploaded"
end
  

