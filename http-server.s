.intel_syntax noprefix

.equ AF_INET, 2
.equ SOCK_STREAM, 1
.equ IPPROTO_TCP, 0
.equ INADDR_ANY, 0x00000000
.equ PORT, 80
.equ SOMAXCONN, 128
.equ BUFFER_SIZE, 1024

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
  .lcomm buffer, BUFFER_SIZE

.section .text
  .global _start

_start:
  # Creating a socket (TCP)
  mov rdi, AF_INET
  mov rsi, SOCK_STREAM
  mov rdx, IPPROTO_TCP
  mov rax, 41 # socket()
  syscall

  mov dword ptr [sockfd], eax

  # Bind
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

  # int listen(int sockfd, int backlog)
  mov rdi, sockfd # sockfd
  mov rsi, SOMAXCONN  # backlog
  mov rax, 50 # listen
  syscall

  # int accept(int sockfd, struct sockaddr *_Nullable restrict addr, socklen_t *_Nullable restrict addrlen)
  mov dword ptr [client_len], SOCKADDR_IN_size  # client_len = SOCKADDR_IN_size

  mov rdi, sockfd # sockfd
  lea rsi, sockaddr_in_client # addr
  lea rdx, client_len # addrlen
  mov rax, 43 # accept
  syscall
  
  mov dword ptr [sockfd_client], eax

  # ssize_t read(size_t count; int fd, void buf[count], size_t count);
  mov rdi, sockfd_client  # fd
  lea rsi, buffer # buf
  mov rdx, BUFFER_SIZE
  mov rax, 0  # read
  syscall

  # ssize_t write(size_t count; int fd, const void buf[count], size_t count);
  mov rdi, [sockfd_client]  # fd
  lea rsi, msg  # buf
  mov rdx, 20 # count
  mov rax, 1  # write
  syscall
  
  # int close(int fd)
  mov rdi, sockfd_client  # fd
  mov rax, 3  # close
  syscall

  # Exiting program
  mov rdi, 0  # status
  mov rax, 60 # exit
  syscall
