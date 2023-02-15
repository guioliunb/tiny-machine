flex lexico.l
bison -d sintatico.y 
gcc -c -o lexico.o lex.yy.c
gcc -c -o sintatico.o sintatico.tab.c 
gcc -o main sintatico.o lexico.o
./main prog1.cmm > instruction.tm
./tm.out saida.tm