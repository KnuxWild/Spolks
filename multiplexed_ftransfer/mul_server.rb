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
  read_sock, _ , err_sock = IO.select(connections.keys.push(server), [], connections.keys)
    
    # handling MSG_OOB messages
    if not err_sock.empty?
      err_sock.each do |socket|
        percentage = socket.recv(1,Socket::MSG_OOB)
        p "More than #{percentage.ord} percents of file '#{connections[socket][:name]}' have been recieved."
      end
    
    # handling new incoming connections
    elsif read_sock.include?(server)
      file = {} # connection description hash :name, :size, :recieved, :fd
      client_info = server.accept  # client[0] - socket descriptor, client[1] - Addrinfo 
      client = client_info[0] # client socket 
      p "New connection established"

      file_description = client.recv(block_size)
      p "File description: #{file_description}"
      file_description = file_description.split("::")
      # file_description[0] - file_name ; file_description[1] - file_size; file_description[2] - block_size;
      
      file[:name] = file_description[0]
      file[:size] = file_description[1].to_i
      file[:recieved] = 0
      fd = File.open(file[:name],"w")
      file[:fd] = fd
      file[:block_size] = (file_description[2] || block_size).to_i
      connections[client] = file
      read_sock.delete(server)

    # recieving data from all sockets and closing all sockets that are done 
    elsif not read_sock.empty?
      read_sock.each do |socket|
        block_size = connections[socket][:block_size]
        fd = connections[socket][:fd]
        recieved = connections[socket][:recieved]
        size = connections[socket][:size]

        data = socket.recv(block_size,0)
        recieved = recieved + data.size
        fd.write(data)
        connections[socket][:recieved] = recieved

        if (recieved >= size) # all data is recieved
          p "File #{connections[socket][:name]} has been succesfully recieved."
          fd.close
          socket.shutdown
          connections.delete(socket)
        end
      end
    end
end