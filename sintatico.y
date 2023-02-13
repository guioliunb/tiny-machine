/* gera codigo para cmd de saida com constante numerica inteira */
%{
#include <stdio.h>
#include "code.h"

//#define YYDEBUG 1

extern FILE *yyin;
extern FILE *yyout;

// SEMANTICO
struct regTabSimb {
	char *nome; /* nome do simbolo */
	char *tipo; /* tipo_int ou tipo_cad ou nsa */
	char *natureza; /* variavel ou procedimento */
	char *usado; /* sim ou nao */
	int locMem;
	struct regTabSimb *prox; /* ponteiro */
};
typedef struct regTabSimb regTabSimb;
regTabSimb *tabSimb = (regTabSimb *)0;
regTabSimb *colocaSimb();
int erroSemantico;

static int proxLocMemVar = 0;
// FIM SEMANTICO

// GERA CODIGO
int locMemId = 0; /* para recuperacao na TS */

/* TM location number for current instruction emission */
static int emitLoc = 0 ;

/* Highest TM location emitted so far
   For use in conjunction with emitSkip,
   emitBackup, and emitRestore */
static int highEmitLoc = 0;
// FIM GERA CODIGO
%}
%union{
	int inteiro;
	char *cadeia;
}
%token VAR INTEIRO ESCREVA MAIN NUM
%token PLUS MINUS TIMES DIVIDE
%type<inteiro> exp NUM
%token <cadeia> ID
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
		colocaSimb($1,"tipo_int","variavel","nao",proxLocMemVar++);
	}
	| ID ',' lista_id
	{
		//printf("declarando id\n");
		colocaSimb($1,"tipo_int","variavel","nao",proxLocMemVar++);
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
		/* generate code for expression to write */
//		cGen(tree->child[0]);
		/* now output it */
		emitRO("OUT",ac,0,0,"escreve ac");

	}
;
cmd_atribuicao: ID '=' exp
	{
		locMemId = recuperaLocMemId($1);
		emitRM("ST",ac,locMemId,gp,"atribuicao: armazena valor");
	}
;
exp:		
	exp exp PLUS { $$=$1+$2; 	
	  printf("Está somando\n")
	  //corrigir tabela de simbolo para array estatico
	  emitRM("ADD",ac,$1,$2,"add numbers");
	}
	| exp exp MINUS { $$=$1-$2; }
	| exp exp TIMES { $$=$1*$2; }
	| exp exp DIVIDE { $$=$1/$2; }
	| NUM
	{
		emitRM("LDC",ac,$1,0,"carrega constante em ac");
		$$ = $1;
		printf("%d\n", $1);
	}
	|	ID
	{
		if (!constaTabSimb($1)) {
		  erroSemantico=1;
		} else {
		  locMemId = recuperaLocMemId($1);
		  emitRM("LD",ac,locMemId,gp,"carrega valor de id em ac");
		  $$ = locMemId;
		}
	}
	
;
%%
// SEMANTICO
regTabSimb *colocaSimb(char *nomeSimb, char *tipoSimb, char *naturezaSimb, char *usadoSimb,int loc){
	regTabSimb *ptr;
	ptr = (regTabSimb *) malloc (sizeof(regTabSimb));

	ptr->nome= (char *) malloc(strlen(nomeSimb)+1);
	ptr->tipo= (char *) malloc(strlen(tipoSimb)+1);
	ptr->natureza= (char *) malloc(strlen(naturezaSimb)+1);
	ptr->usado= (char *) malloc(strlen(usadoSimb)+1);

	strcpy (ptr->nome,nomeSimb);
	strcpy (ptr->tipo,tipoSimb);
	strcpy (ptr->natureza,naturezaSimb);
	strcpy (ptr->usado,usadoSimb);
	ptr->locMem= loc;

	ptr->prox= (struct regTabSimb *)tabSimb;
	tabSimb= ptr;
	return ptr;
}
int constaTabSimb(char *nomeSimb) {
	regTabSimb *ptr;
	for (ptr=tabSimb; ptr!=(regTabSimb *)0; ptr=(regTabSimb *)ptr->prox)
	  if (strcmp(ptr->nome,nomeSimb)==0) return 1;
	return 0;
}
// FIM SEMANTICO

// GERA CODIGO
void emitRO( char *op, int r, int s, int t, char *c)
{ fprintf(yyout,"%3d:  %5s  %d,%d,%d ",emitLoc++,op,r,s,t);
//  if (TraceCode) fprintf(code,"\t%s",c) ;
  fprintf(yyout,"\n") ;
//  if (highEmitLoc < emitLoc) highEmitLoc = emitLoc ;
} /* emitRO */

/* Procedure emitRM emits a register-to-memory
 * TM instruction
 * op = the opcode
 * r = target register
 * d = the offset
 * s = the base register
 * c = a comment to be printed if TraceCode is TRUE
 */
void emitRM( char * op, int r, int d, int s, char *c)
{ fprintf(yyout,"%3d:  %5s  %d,%d(%d) ",emitLoc++,op,r,d,s);
//  if (TraceCode) fprintf(code,"\t%s",c) ;
  fprintf(yyout,"\n") ;
//  if (highEmitLoc < emitLoc)  highEmitLoc = emitLoc ;
} /* emitRM */

// recupera locacao de memoria de um id cujo nome eh passado em parametro
int recuperaLocMemId(char *nomeSimb) {
	regTabSimb *ptr;
	for (ptr=tabSimb; ptr!=(regTabSimb *)0; ptr=(regTabSimb *)ptr->prox)
	  if (strcmp(ptr->nome,nomeSimb)==0) return ptr->locMem;
	return -1;
}
// FIM GERA CODIGO

main(argc, argv)
int argc;
char **argv;
{
//	extern int yydebug;
//	yydebug=1;

	erroSemantico=0;

	++argv; --argc; 	    /* abre arquivo de entrada se houver */
	if(argc > 0)
		yyin = fopen(argv[0],"rt");
	else
		yyin = stdin;    /* cria arquivo de saida se especificado */
	if(argc > 1)
		yyout = fopen(argv[1],"wt");
	else
		//yyout = stdout;
		yyout = fopen("saida.tm","wt");

//emitComment("Standard prelude:");
emitRM("LD",mp,0,ac,"load maxaddress from location 0");
emitRM("ST",ac,0,ac,"clear location 0");
//emitComment("End of standard prelude.");

	yyparse ();

//emitComment("End of execution.");
emitRO("HALT",0,0,0,"");

	fclose(yyin);
	fclose(yyout);
}
yyerror (s) /* Called by yyparse on error */
	char *s;
{
	printf ("Problema com a analise sintatica!\n", s);
}
