/* Analisador Lexico */
%{
#include "sintatico.tab.h"
%}
%%

"+"    { return PLUS; }
"-"    { return MINUS; }
"*"    { return TIMES; }
"/"    { return DIVIDE; }
main		{return MAIN;}
var		{return VAR;}
inteiro		{return INTEIRO;}
escreva		{return ESCREVA;}
[0-9]+		{yylval.inteiro = atoi(yytext); return NUM;}
[a-zA-Z][a-zA-Z0-9]*	{yylval.cadeia= (char *) strdup(yytext); return ID;}
[ \t\n]+	{;}
.		{return yytext[0];}
%%
int yywrap() {
  return 1;
}