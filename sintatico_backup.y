/* gera codigo para cmd de saida com constante numerica inteira */
%{
#include <stdio.h>
#include "code.h"

//#define YYDEBUG 1

extern FILE *yyin;
extern FILE *yyout;

/* TM location number for current instruction emission */
static int emitLoc = 0 ;

/* Highest TM location emitted so far
   For use in conjunction with emitSkip,
   emitBackup, and emitRestore */
static int highEmitLoc = 0;

%}
%union{
	int inteiro;
}
%token ESCREVA
%token <inteiro> NUM
%%
programa:	'{' lista_cmds '}'
	{
		
	}
;
lista_cmds:	cmd ';'				{;}
		| cmd ';' lista_cmds		{;}
;
cmd:		cmd_saida			{;}
;
cmd_saida:	ESCREVA '(' exp ')'
	{
		/* generate code for expression to write */
//		cGen(tree->child[0]);
		/* now output it */
		emitRO("OUT",ac,0,0,"write ac");

	}
;
exp:		NUM
	{
		emitRM("LDC",ac,$1,0,"load const");
	}
;
%%
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

main(argc, argv)
int argc;
char **argv;
{
//	extern int yydebug;
//	yydebug=1;

	++argv; --argc; 	    /* abre arquivo de entrada se houver */
	if(argc > 0)
		yyin = fopen(argv[0],"rt");
	else
		yyin = stdin;    /* cria arquivo de saida se especificado */
	if(argc > 1)
		yyout = fopen(argv[1],"wt");
	else
		yyout = stdout;

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
