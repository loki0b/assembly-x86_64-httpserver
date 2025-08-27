SRC=http-server.s
OBJ=http-server.o
OUT=http-server

all:
	as $(SRC) -o $(OBJ)
	ld $(OBJ) -o $(OUT)

run:
	./$(OUT)

