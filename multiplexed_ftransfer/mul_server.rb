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
block_size = 1400
PR_size = 1024 # hardcoded protocol mesage size
file_name = ""
current_block = 0
last_packet = ""
state = :ready #ready or aborted

server = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM) #oppening connection section
server.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR, true)
addr = Addrinfo.tcp(address, port)  #sockaddr structure
server.bind(addr)
server.listen(1)
client_info = server.accept  # client[0] - socket descriptor, client[1] - Addrinfo 
client = client_info[0] # client socket 
p "Connection established"
server_state = state.to_s + "::" + file_name + "::" + current_block.to_s + "::" + block_size.to_s
client.send(server_state,0)
p "Server state is sent"

file_description = client.recv(PR_size)
p "File description: #{file_description}"
file_description = file_description.split("::")
# file_description[0] - file_name ; file_description[1] - size; file_description[2] - block_size;
# file_description[3] - blocks_num; file_description[4] - timeout
file_name = file_description[0]
file_size = file_description[1].to_i
block_size = file_description[2].to_i
blocks_num = file_description[3].to_i
timeout = file_description[4].to_i

File.open(file_name,"w") do |file|
  while (current_block < blocks_num - 1) do
  	begin 
      status = Timeout::timeout(timeout) do
        packet = client.recv(block_size,0)
          while packet.length < block_size do                          # This is needed to be sure, that blocks
            packet = packet + client.recv(block_size - packet.length,0)  # with block_size (not less) are written to
          end                                                          # the file
        file.write(packet)
        print "."
        current_block = current_block + 1
      end
    rescue Timeout::Error
      p "Connection seems to be aborted."
      state = :aborted
      file.close
      break
    end
  end
 
  last_packet_size = file_size - block_size * (blocks_num-1) # Write the last portion of data which is less than block_size
  if state == :ready
    while last_packet.length < last_packet_size do
      packet = client.recv(block_size,0)
      last_packet = last_packet + packet
    end
    file.write(last_packet)
  end  
  server.close
end


# Second part of server which will wait until file will be fully reuploaded

while state == :aborted do # Reuploading file after disconnect
  p "Waiting for file reuploading"

  server = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM) #oppening connection section
  server.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR, true)
  addr = Addrinfo.tcp(address, port)  #sockaddr structure
  server.bind(addr)
  server.listen(1)
  client_info = server.accept  # client[0] - socket descriptor, client[1] - Addrinfo 
  client = client_info[0] # client socket 
  p "Connection established"
  server_state = state.to_s + "::" + file_name + "::" + current_block.to_s + "::" + block_size.to_s
  client.send(server_state,0)
  p "Server state is sent"
  state = :ready

  File.open(file_name,"a") do |file|
    while (current_block < blocks_num - 1) do
      begin 
        status = Timeout::timeout(timeout) do
          packet = client.recv(block_size,0)
            while packet.length < block_size do                            # This is needed to be sure, that blocks
              packet = packet + client.recv(block_size - packet.length,0)  # with block_size (not less) are written to
            end                                                            # the file
          file.write(packet)
          print "."
          current_block = current_block + 1
        end
      rescue Timeout::Error
        p "Connection seems to be aborted."
        state = :aborted
        file.close
        break
      end
    end
    
    last_packet_size = file_size - block_size * (blocks_num-1) # Write the last portion of data which is less than block_size
    if state == :ready
      p "Im here, sucker"
      while last_packet.length < last_packet_size do
        packet = client.recv(block_size,0)
        last_packet = last_packet + packet
      end
      file.write(last_packet)
    end  
  end
  server.close
end




