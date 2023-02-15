%{
    #include <stdio.h>
    #include <stdlib.h>
    void yyerror(char *);
    int yylex(void);
    int sym[26];
	int erroSemantico;
	//#define YYDEBUG 1

extern FILE *yyin;
extern FILE *yyout;
%}
%union{
	int inteiro;
	char *cadeia;
}
%token VAR INTEIRO ESCREVA MAIN NUM
%token PLUS MINUS TIMES DIVIDE
%left '+' '-'
%left '*' '/'
%type<inteiro> exp NUM
%token <inteiro> ID
%nonassoc UMINUS

%%

programa:	declaracoes '{' lista_cmds '}'
	{
		printf("\nSintaxe ok.\n");
		if (erroSemantico) {
		  printf("\nErro semantico: esqueceu de declarar alguma variavel que usou...");
		} else {
		  printf("\nSemantica ok: se variaveis usadas, elas foram declaradas ok.\n");
		}		

	}
;
declaracoes: VAR linhas_decl		{;}
;
linhas_decl: linha_decl			{;}
		| linha_decl linhas_decl	{;}
;
linha_decl: lista_id ':' INTEIRO ';'		{;}
;
lista_id: ID
	{
		//printf("declarando id\n");
	}
	| ID ',' lista_id
	{
		//printf("declarando id\n");
	}
;
lista_cmds:	cmd ';'				{;}
		| cmd ';' lista_cmds		{;}
;
cmd:		cmd_saida			{;}
		| cmd_atribuicao		{;}
;
cmd_saida:	ESCREVA '(' exp ')'
	{
		/* generate code for exp to write */
//		cGen(tree->child[0]);
		/* now output it */
	}
;
cmd_atribuicao: ID '=' exp
	{
		
	}
;
exp:
        NUM                             
        { 
            $$ = $1; }
        | ID                      { $$ = sym[$1]; }
        | exp exp PLUS     { $$ = $1 + $2; }
        | exp exp MINUS     { $$ = $1 - $2; }
        | exp exp TIMES     { $$ = $1 * $2; }
        | exp exp DIVIDE {   $$ = $1 / $2; }
        | '(' exp ')'            { $$ = $2; }
        ;

%%

void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

int main(void) {
    freopen ("a.txt", "r", stdin);  //a.txt holds the exp
    yyparse();
}

