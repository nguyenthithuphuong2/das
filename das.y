%{
/*
 * Copyright 2012 Jon Povey <jon@leetfighter.com>
 * Released under the GPL v2
 */
#include <stdio.h>

#include "common.h"

int yylex();

void yyerror(char *);
int get_lineno(void);
void parse_error(char *str);
%}

%union {
	int  integer;
	char *string;
	struct expr *expr;
	struct operand *operand;
	struct dat_elem *dat_elem;
}

%token <string> SYMBOL LABEL STRING
%token <integer> CONSTANT
%token <integer> REG
%token <integer> OP1 OP2 DAT
%token <integer> OPERATOR
%token <integer> LSHIFT RSHIFT

%type <expr> expr
%type <operand> operand op_expr
%type <dat_elem> dat_elem datlist

%left '|'
%left '^'
%left '&'
%left LSHIFT RSHIFT
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS '~'

%%

program:
	program line '\n'			{ /*printf("line\n");*/ }
	| program '\n'				/* empty line or comment */
	|
	;

line:
	statement
	| label
	| label statement
	;							

label:
	LABEL						{ label_parse($1); }
	;

statement:
	dat
	| instr
	;

instr:
	OP2 operand ',' operand		{
								operand_set_position($2, OP_POS_B);
								operand_set_position($4, OP_POS_A);
								gen_instruction($1, $2, $4);
								}
	| OP1 operand				{
								operand_set_position($2, OP_POS_A);
								gen_instruction($1, NULL, $2);
								}
	| error						{ parse_error("bad instruction "); }
	;

operand:
	op_expr
	| '[' op_expr ']'			{ $$ = operand_set_indirect($2); }
	;

op_expr:
	REG							{ $$ = gen_operand($1, NULL, OPSTYLE_SOLO); }
	| expr						{ $$ = gen_operand(REG_NONE, $1, OPSTYLE_SOLO); }
	| REG expr  /* PICK n */	{ $$ = gen_operand($1, $2, OPSTYLE_PICK); }
	| expr '+' REG				{ $$ = gen_operand($3, $1, OPSTYLE_PLUS); }
	| REG '+' expr				{ $$ = gen_operand($1, $3, OPSTYLE_PLUS); }
 /*	| error						{ parse_error("bad op_expr"); } */
	;

expr:
	CONSTANT					{ $$ = gen_const($1); }
	| SYMBOL					{ $$ = gen_symbol($1); }
	| '-' expr %prec UMINUS 	{ $$ = expr_op(UMINUS, NULL, $2); }
	| '~' expr %prec '~'		{ $$ = expr_op('~', NULL, $2); }
	| expr '+' expr				{ $$ = expr_op('+', $1, $3); }
	| expr '-' expr				{ $$ = expr_op('-', $1, $3); }
	| expr '*' expr				{ $$ = expr_op('*', $1, $3); }
	| expr '/' expr				{ $$ = expr_op('/', $1, $3); }
	| expr '^' expr				{ $$ = expr_op('^', $1, $3); }
	| expr '&' expr				{ $$ = expr_op('&', $1, $3); }
	| expr '|' expr				{ $$ = expr_op('|', $1, $3); }
	| expr LSHIFT expr			{ $$ = expr_op(LSHIFT, $1, $3); }
	| expr RSHIFT expr			{ $$ = expr_op(RSHIFT, $1, $3); }
	| '(' expr ')'				{ $$ = expr_op('(', NULL, $2); }
	;

dat:
	DAT datlist					{ gen_dat($2); }
	;

datlist:
	dat_elem
	| dat_elem ',' datlist		{ $$ = dat_elem_follows($1, $3); }
	;

dat_elem:
	expr						{ $$ = new_expr_dat_elem($1); }
	| STRING					{ $$ = new_string_dat_elem($1); }
	/* maybe 8bit char array etc later */
	;

%%

void parse_error(char *str)
{
	// yylineno has advanced since the actual line this was found on
	fprintf(stderr, "line %d: parse error: %s\n", get_lineno() - 1, str);
	das_error = 1;
}
