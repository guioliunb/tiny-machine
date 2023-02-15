%{
  #include "stdlib.h"
  #include "sintatico.tab.h"
%}

int        [0-9]+
float      ([0-9]+\.[0-9]*|\.[0-9]+)
id         [_a-zA-Z][_a-zA-Z0-9]*

%x C_COMMENT

%%
"/*".        		{ BEGIN(C_COMMENT); }
<C_COMMENT>"*/" 	{ BEGIN(INITIAL); printf("; comentarios multilinha\n");}
<C_COMMENT>\n   	{ }
<C_COMMENT>.    	{ }


"read"      {return READ;}
"write"     {return WRITE;}
"while"     {return WHILE;}
"do"        {return DO;}

{int}       { yylval.inteiro = atoi(yytext); return NUM;}
{id}        { yylval.cadeia = strdup(yytext); return ID;}

"+"			{ return '+'; }
"-"			{ return '-'; }
"*"			{ return '*'; }
"/"			{ return '/'; }

"<"         { return LT; }
"<="        { return LE; }
">"         { return GT; }
">="        { return GE; }
"!="        { return NE; }
"=="        { return EQ; }

"{"			{ return '{';}
"}"			{ return '}';}
"["			{ return '[';}
"]"			{ return ']';}
"("			{ return '(';}
")"			{ return ')';}
";"			{ return ';';}
","			{ return ',';}
"="			{ return '=';}

[ \t\n]+      {;}
.        {return yytext[0];}

%%

int yywrap() {
  return 1;
}