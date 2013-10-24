require 'socket'

address = ARGV[0]
port = ARGV[1].to_i

server = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)
addrinfo = Socket.sockaddr_in(port, address)
server.bind(addrinfo)
server.listen(1)

client = server.accept  # client[0] - socket descriptor, client[1] - Addrinfo 

loop do
  data = client[0].recv(1488)
  break if data.empty?
  client[0].send(data, 0)
end

server.close