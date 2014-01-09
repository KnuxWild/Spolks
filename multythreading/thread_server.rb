require 'socket'

help_array = ["-h","help","--help"] #help info
if (help_array.include?(ARGV[0]) or !ARGV[0])
  p "Transmission server usage is:"
  p "tr_server.rb [server_IP] [server_port]"
  exit
end

address = ARGV[0]  #server side params
port = ARGV[1].to_i
block_size = 102400
file_name = ""
current_block = 0

connections = {} # hash, where will be stored socket and connection's description     

server = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM) #oppening connection section
server.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR, true)
addr = Addrinfo.tcp(address, port)  #sockaddr structure
server.bind(addr)
server.listen(1) #server socket will listen for new connections

loop do
  file = {} # connection description hash :name, :size, :recieved, :fd

  client_info = server.accept  # client[0] - socket descriptor, client[1] - Addrinfo 
  client = client_info[0] # client socket 
  p "New connection established"

  file_description = client.recv(block_size)
  p "File description: #{file_description}"
  file_description = file_description.split("::")
  # file_description[0] - file_name ; file_description[1] - file_size; file_description[2] - block_size;
  connections[client] = file_description
  
  Thread.new do
    p "New Thread started."
    socket = client
    percent = 10
    file_desc = connections[socket]

    file_name = file_desc[0]
    file_size = file_desc[1].to_i
    file_recieved = 0
    block_size = (file_desc[2] || block_size).to_i

    File.open(file_name,"w") do |file|
      loop do
        data = socket.recv(block_size,0)
        file_recieved = file_recieved + data.size
        file.write(data)

        if (file_recieved > (file_size / 100 * percent))
          p "More than #{percent} percents of file #{file_name} have been recieved"
          percent = percent + 10
        end

        if ((file_recieved == file_size) or (data.size == 0)) # all data is recieved or connection is aborted
          p "File #{file_name} has been succesfully recieved." if (file_recieved == file_size)
          p "Connection #{file_name} was aborted." if data.size == 0 
          socket.shutdown
          connections.delete(socket)
          break
        end
      end
    end
    p "Thread was closed."
  end
end