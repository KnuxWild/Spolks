require 'socket'
require 'timeout'

help_array = ["-h","help","--help"] #help info
if (help_array.include?(ARGV[0]) or !ARGV[0])
  p "Transmission server usage is:"
  p "tr_server.rb [server_IP] [server_port]"
  exit
end

address = ARGV[0]  #server side params
port = ARGV[1].to_i
MTU = 1400
PR_size = 1024 # hardcoded protocol mesage size
file_name = ""
current_block = 0
state = :ready #ready or aborted

server = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM) #oppening connection section
addr = Addrinfo.tcp(address, port)
server.bind(addr)
server.listen(1)
client_info = server.accept  # client[0] - socket descriptor, client[1] - Addrinfo 
client = client_info[0] # client socket 

server_state = state.to_s + "::" + file_name + "::" + current_block.to_s

client.send(server_state,0)
p "State is sent"

file_description = client.recv(PR_size)
p "File description: #{file_description}"
file_description = file_description.split("::")
# file_description[0] - file_name ; file_description[1] - size; file_description[2] - MTU;
# file_description[3] - blocks_num; file_description[4] - timeout
file_name = file_description[0]
file_size = file_description[1].to_i
MTU = file_description[2].to_i
blocks_num = file_description[3].to_i
timeout = file_description[4].to_i

File.open(file_name,"w") do |file|
  while (current_block < blocks_num) do
  	begin 
      status = Timeout::timeout(timeout) do
        packet = client.recv(MTU,0)
        file.write(packet)
        current_block = current_block + 1
      end
    rescue Timeout::Error
      p "Connection seems to be aborted."
      state = :aborted
    end
    break if (state == :aborted)
  end
end




