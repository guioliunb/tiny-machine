%defines "sintatico.tab.h"
%output  "sintatico.tab.c"
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
static int proxReg = 0 ;

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

%token READ WRITE DO WHILE RETURN QUIT
%token<inteiro> GT GE LT LE NE EQ

%token<cadeia> ID
%token<inteiro> NUM 
%type<inteiro> factor mulop term addop relop exp
%type<inteiro> stmt_sequence statement
%type<inteiro> repeat_stmt assign_stmt read_stmt write_stmt

%%

input   
        :  /* empty */
        | input line {
                printf("\nSintaxe ok.\n");
		if (erroSemantico) {
		  printf("\nErro semantico: esqueceu de declarar alguma variavel que usou...");
		} else {
		  printf("\nSemantica ok: se variaveis usadas, elas foram declaradas ok.\n");
		}
        }
        ;

line
        :    
        | '{' program '}'
        ;

program
        : stmt_sequence
        ;

stmt_sequence
        : statement                      
        | stmt_sequence statement { $$ = $1; }
        ;

statement
        : repeat_stmt  ';'  
        | assign_stmt  ';'
        | read_stmt    ';'
        | write_stmt   ';'
        ;

repeat_stmt
        : DO '&' stmt_sequence '&' WHILE '(' exp relop exp ')' {
                int program_counter = $3;
-
		int reg = recuperaProxReg();
                emitRO("SUB", reg, $7, $9, "subtract numbers");
                int program_address = emitLoc;
                switch ($8) {
                        case 0:
                        // $7 > $9
                        emitRM("JGT", reg, program_counter, gp, "jump if gt");
                        break;
                        case 1:
                        // $7 >= $9
                        emitRM("JGE", reg, program_counter, gp, "jump if ge");
                        break;
                        case 2:
                        // $7 < $9
                        emitRM("JLT", reg, program_counter, gp, "jump if lt");
                        break;
                        case 3:
                        // $7 <= $9
                        emitRM("JLE", reg, program_counter, gp, "jump if le");
                        break;
                        case 4:
                        // $7 != $9
                        emitRM("JNE", reg, program_counter, gp, "jump if ne");
                        break;
                        case 5:
                        // $7 == $9
                        emitRM("JEQ", reg, program_counter, gp, "jump if eq");
                        break;
                        default:
                        // does nothing
                        break;
                }
                $$ = program_address;
        }
        ;

relop
		: GT { $$ = 0; } //>
		| GE { $$ = 1; } //>=
		| LT { $$ = 2; } //<
		| LE { $$ = 3; } //<=
		| NE { $$ = 4; } //!=
		| EQ { $$ = 5; } //==
		;

assign_stmt
        : ID '=' exp {
			colocaSimb($1,"tipo_int","variavel","nao",proxLocMemVar++);
			locMemId = recuperaLocMemId($1);
			emitRM("ST",$3,locMemId*4,gp,"atribuicao: armazena valor");
                        printf("/nASSIGN STATEMENT %d/n", emitLoc);
            $$ = emitLoc;
        }
        ;


read_stmt
        : READ ID{
		colocaSimb($2,"tipo_int","variavel","nao",proxLocMemVar++);
                int reg = recuperaProxReg();
		emitRO("IN",reg,0,0,"lê ac");
                int program_counter = emitLoc;
		locMemId = recuperaLocMemId($2);
		emitRM("ST",$2,locMemId*4,gp,"atribuicao: armazena valor");
                $$ = program_counter;
        }
        ;

write_stmt
        : WRITE exp {
		emitRO("OUT",$2,0,0,"escreve ac");
                printf("/n WRITE%d/n", emitLoc);
                $$ = emitLoc;
        }
        ;

exp
        : exp addop term {
                int reg = recuperaProxReg();
                switch ($2) {
                        case 0:
                        emitRO("ADD",reg,$1,$3,"add numbers");
                        break;
                        case 1:
                        emitRO("SUB",reg,$1,$3,"subtract numbers");
                        break;
                        default:
                        break;
                }

                $$ = reg;
        }
        | term
        ;

addop
        : '+' { $$ = 0; }
        | '-' { $$ = 1; }
        ;

term
        : term mulop factor {
                int reg = recuperaProxReg();
                switch ($2) {
                        case 0:
                        emitRO("MUL",reg,$1,$3,"multiply numbers");
                        break;
                        case 1:
                        emitRO("DIV",reg,$1,$3,"divide numbers");
                        break;
                        default:
                        break;
                }

                $$ = reg;
        }
        | factor
        ;

mulop
        : '*' { $$ = 0; }
        | '/' { $$ = 1; }
        ;


factor  
        : '(' exp ')' { 
			int val = (recuperaProxReg()+4) % 6;
			$$ = val+1;
		 } 
        | NUM  {
		int reg = recuperaProxReg();
		emitRM("LDC",reg,$1,0,"carrega constante em ac");
		$$ = reg;
        }
        | ID {
			if (!constaTabSimb($1)) {
				erroSemantico=1;
			} else {
				locMemId = recuperaLocMemId($1);
				int reg = recuperaProxReg();
				emitRM("LD",reg,locMemId*4,gp,"carrega valor de id em ac");

				printf("LOC: %d\n", locMemId);
				$$ = reg;
				
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

int recuperaProxReg() {
	proxReg= (proxReg+1)%6;
	return proxReg+1;
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
