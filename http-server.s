.intel_syntax noprefix

.equ AF_INET, 2
.equ SOCK_STREAM, 1
.equ IPPROTO_TCP, 0
.equ INADDR_ANY, 0
.equ PORT, 80
.equ SOMAXCONN, 128
.equ BUFFER_SIZE, 1024
.equ O_RDONLY, 0

# struct sockaddr_in
.equ SOCKADDR_IN_sin_family, 0
.equ SOCKADDR_IN_sin_port, 2
.equ SOCKADDR_IN_sin_addr, 6
.equ SOCKADDR_IN_size, 16

# struct in_addr
.equ IN_ADDR_s_addr, 0
.equ IN_ADDR_size, 4

.section .data
  msg: .asciz "HTTP/1.0 200 OK\r\n\r\n"

.section .bss
  .lcomm sockaddr_in, SOCKADDR_IN_size
  .lcomm sockaddr_in_client, SOCKADDR_IN_size
  .lcomm sockfd, 4
  .lcomm sockfd_client, 4
  .lcomm client_len, 4
  .lcomm req_buffer, BUFFER_SIZE
  .lcomm uri, BUFFER_SIZE
  .lcomm uri_size, 4
  .lcomm file, BUFFER_SIZE

.section .text
  .global _start

_start:
  # Creating a socket (TCP)
  mov rdi, AF_INET
  mov rsi, SOCK_STREAM
  mov rdx, IPPROTO_TCP
  mov rax, 41 # socket
  syscall

  mov dword ptr [sockfd], eax # saving the host socket

  # Binding host socket to an address
  mov ax, AF_INET
  mov word ptr [sockaddr_in + SOCKADDR_IN_sin_family], ax # sockaddr_in.sin_family = AF_INET

  mov ax, PORT
  xchg al, ah # swap lower and high bytes
  mov word ptr [sockaddr_in + SOCKADDR_IN_sin_port], ax  # sockaddr_in.sin_port = 8080

  mov eax, INADDR_ANY
  bswap eax # Converting to network endianess (big endian)
  mov dword ptr [sockaddr_in + SOCKADDR_IN_sin_addr + IN_ADDR_s_addr], eax # sockaddr_in.sin_addr.s_addr = '0.0.0.0'

  mov rdi, sockfd  # sockfd
  lea rsi, sockaddr_in  # &addr
  mov rdx, SOCKADDR_IN_size  # addrlen
  mov rax, 49 # bind()
  syscall

  # Making the host socket a passive socket
  mov rdi, sockfd # host socket
  mov rsi, SOMAXCONN  # max connections
  mov rax, 50 # listen
  syscall

  mov dword ptr [client_len], SOCKADDR_IN_size  # client_len = SOCKADDR_IN_size


while:
.accept:
  mov rdi, sockfd # sockfd
  lea rsi, sockaddr_in_client # addr
  lea rdx, client_len # addrlen
  mov rax, 43 # accept
  syscall
  
  mov dword ptr [sockfd_client], eax
  
  mov rax, 57 # fork
  syscall

  cmp rax, 0
  jne .clear
  
  mov rax, 3 # close host fd
  syscall

  # Reading client request
  mov rdi, sockfd_client  # fd
  lea rsi, req_buffer # buf
  mov rdx, BUFFER_SIZE # count
  mov rax, 0  # read
  syscall
  call get_uri

.read_resource:
  lea rdi, uri  # path
  mov rsi, O_RDONLY # flags
  mov rax, 2  # open
  syscall

  mov rdi, rax # fd
  lea rsi, file # buf
  mov rdx, BUFFER_SIZE # count
  mov rax, 0 # read
  syscall
  
  mov rbx, rax # read return

  mov rax, 3
  syscall

.write_http_message:
  mov rdi, [sockfd_client]  # fd
  lea rsi, msg  # buf
  mov rdx, 19 # count
  mov rax, 1  # write
  syscall

.send_resource:
  mov rdi, [sockfd_client]  # fd
  lea rsi, file  # buf
  mov rdx, rbx # count
  mov rax, 1  # write
  syscall
  
  mov rdi, sockfd_client  # closing fd
  mov rax, 3
  syscall

  jmp .exit

.clear:
  mov rdi, sockfd_client
  mov rax, 3
  syscall

  jmp .accept

.exit:
  mov rdi, sockfd_client
  mov rax, 3
  syscall

  mov rdi, 0  # status
  mov rax, 60 # exit
  syscall

get_uri:
  xor rax, rax  # index 0
.loop_get_uri:
  mov bl, byte ptr [req_buffer + 4 + rax]
  mov byte ptr [uri + rax], bl # copying the nth byte of req_buffer to uri
  inc rax
  mov bl, byte ptr [req_buffer + 4 + rax]
  cmp bl, 0x20 # checking if the value of the new addr is a space
  jne .loop_get_uri
.done:
  ret
