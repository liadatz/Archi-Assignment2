all: exec

exec: 
	nasm -f elf myCalc.s -o myCalc.o
	gcc -m32 -Wall -g myCalc.o -o myCalc

.PHONY: clean
clean:
	rm -rf ./*.o myCalc
