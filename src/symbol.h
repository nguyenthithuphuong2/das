#ifndef SYMBOL_H
#define SYMBOL_H
/*
 * das things to do with symbols
 *
 * Copyright 2012 Jon Povey <jon@leetfighter.com>
 * Released under the GPL v2
 */

struct symbol;

#include "expression.h"
#include "instruction.h"
#include "output.h"

/* Parse */
struct symbol* symbol_parse(char *name);
void label_parse(LOCTYPE loc, char *name);
void directive_equ(LOCTYPE loc, struct symbol *sym, struct expr *expr);
void symbol_mark_used(struct symbol *sym);

/* Analysis */
int symbol_check_defined(LOCTYPE loc, struct symbol *s);
int symbol_value(struct symbol *sym);

/* Output */
void dump_symbol(struct symbol *l);
void dump_symbols(void);
int symbol_print_asm(char *buf, struct symbol *sym);

/* Cleanup */
void symbols_free(void);

#endif
