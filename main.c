#include <stdio.h>
#include "lex.yy.h"
    
extern int yyparse (void);
    
void yyerror(char const *message){
    printf("Error: %s\n", message);
}
    
int main() {
	printf("Informe um token e tecle <enter>:\n");
	yylex(); /* scanner gerado por Flex */
}

