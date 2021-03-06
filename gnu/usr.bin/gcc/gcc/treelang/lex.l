%{ /* -*- c -*- = mode for emacs editor
/* 

   TREELANG lexical analysis

   ---------------------------------------------------------------------

   Copyright (C) 1986, 87, 89, 92-96, 1997, 1999, 2000, 2001, 2002 Free Software Foundation, Inc.
   
   This program is free software; you can redistribute it and/or modify it 
   under the terms of the GNU General Public License as published by the
   Free Software Foundation; either version 2, or (at your option) any
   later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, 59 Temple Place - Suite 330,
   Boston, MA 02111-1307, USA.
   
   In other words, you are welcome to use, share and improve this program.
   You are forbidden to forbid anyone else to use, share and improve
   what you give them.   Help stamp out software-hoarding!  
   
   ---------------------------------------------------------------------
   
   Written by Tim Josling 1999-2001, based in part on other parts of
   the GCC compiler. 
 
*/

#include <stdio.h>
#include <memory.h>
#include "ansidecl.h"
#include "config.h"
#include "system.h"

/* Avoid poisoned malloc problem.  */
#undef IN_GCC

#include "config.h"
#include "diagnostic.h"
#include "tree.h"

/* Token defs.  */
#include "treelang.h"
#include "parse.h"

extern int option_lexer_trace;

int yylex (void);
void update_yylval (int a); 

static int next_tree_lineno=1;
static int next_tree_charno=1;
 
static void update_lineno_charno (void);
static void dump_lex_value (int lexret);
 
#define SAVE_RETURN(a) {update_yylval (a); if (option_lexer_trace)\
   {fprintf (stderr, "\nlexer returning"); dump_lex_value (a);} return a;}
#define NOT_RETURN(a) {update_yylval (a); if (option_lexer_trace)\
   {fprintf (stderr, "\nlexer swallowing"); dump_lex_value (a);}}

%}

%option nostack
%option nounput
%option noyywrap
%option pointer
%option nodefault

%%

 { 
   /* Should really allocate only what we need. lll;.  */
   yylval = my_malloc (sizeof (struct prod_token_parm_item));
   ((struct prod_token_parm_item *)yylval)->tp.tok.lineno = next_tree_lineno;
   ((struct prod_token_parm_item *)yylval)->tp.tok.charno = next_tree_charno;
 }

[ \n]+ {
  update_lineno_charno ();
    NOT_RETURN (WHITESPACE);
}
  
"//".*  {
  /* Comment.  */
    update_lineno_charno ();
    NOT_RETURN (COMMENT);
}
   
"{" {
  update_lineno_charno ();
  SAVE_RETURN (LEFT_BRACE);
}
  
"}" {
  update_lineno_charno ();
  SAVE_RETURN (RIGHT_BRACE);
}
  
"(" {
  update_lineno_charno ();
  SAVE_RETURN (LEFT_PARENTHESIS);
}
  
")" {
  update_lineno_charno ();
  SAVE_RETURN (RIGHT_PARENTHESIS);
}
  
"," {
  update_lineno_charno ();
  SAVE_RETURN (COMMA);
}
  
";" {
  update_lineno_charno ();
  SAVE_RETURN (SEMICOLON);
}
  
"+" {
  update_lineno_charno ();
  SAVE_RETURN (PLUS);
}
  
"-" {
  update_lineno_charno ();
  SAVE_RETURN (MINUS);
}
  
"=" {
  update_lineno_charno ();
  SAVE_RETURN (ASSIGN);
}
  
"==" {
  update_lineno_charno ();
  SAVE_RETURN (EQUALS);
}
  
[+-]?[0-9]+ {
  update_lineno_charno ();
  SAVE_RETURN (INTEGER);
}
  
"external_reference" {
  update_lineno_charno ();
  SAVE_RETURN (EXTERNAL_REFERENCE);
}
  
"external_definition" {
  update_lineno_charno ();
  SAVE_RETURN (EXTERNAL_DEFINITION);
}
  
"static" {
  update_lineno_charno ();
  SAVE_RETURN (STATIC);
}
  
"automatic" {
  update_lineno_charno ();
  SAVE_RETURN (AUTOMATIC);
}
  
"int" {
  update_lineno_charno ();
  SAVE_RETURN (INT);
}
  
"char" {
  update_lineno_charno ();
  SAVE_RETURN (CHAR);
}
  
"void" {
  update_lineno_charno ();
  SAVE_RETURN (VOID);
}
  
"unsigned" {
  update_lineno_charno ();
  SAVE_RETURN (UNSIGNED);
}
  
"return" {
  update_lineno_charno ();
  SAVE_RETURN (RETURN);
}
  
"if" {
  update_lineno_charno ();
  SAVE_RETURN (IF);
}
  
"else" {
  update_lineno_charno ();
  SAVE_RETURN (ELSE);
}
  
[A-Za-z_]+[A-Za-z_0-9]* {
  update_lineno_charno ();
  update_yylval (NAME); 
  if (option_lexer_trace) 
    {
      fprintf (stderr, "\nlexer returning"); 
      dump_lex_value (NAME);
    } 
  return NAME;
}
  
[^\n]  {
  update_lineno_charno ();
  fprintf (stderr, "%s:%i:%i: Unrecognized character %c\n", in_fname, 
           ((struct prod_token_parm_item *)yylval)->tp.tok.lineno, 
           ((struct prod_token_parm_item *)yylval)->tp.tok.charno, yytext[0]);
  errorcount++;
}

%%

/* 
   Update line number (1-) and character number (1-).  Call this
   before processing the token.  */

static void 
update_lineno_charno (void)
{
   /* Update the values we send to caller in case we sometimes don't
      tell them about all the 'tokens' eg comments etc.  */
   int yyl;
   ((struct prod_token_parm_item *)yylval)->tp.tok.lineno = next_tree_lineno;
   ((struct prod_token_parm_item *)yylval)->tp.tok.charno = next_tree_charno;
   for ( yyl = 0; yyl < yyleng; ++yyl ) 
      {
         if ( yytext[yyl] == '\n' ) 
            {
               ++next_tree_lineno;
               next_tree_charno = 1;
            } 
         else 
           next_tree_charno++;
      }
}

/* Fill in the fields of yylval - the value of the token.  The token
   type is A.  */
void 
update_yylval (int a)
{
  struct prod_token_parm_item * tok;
  tok=yylval;
  
  tok->category = token_category;
  tok->type = a;
  tok->tp.tok.length = yyleng;
  /* Have to copy yytext as it is just a ptr into the buffer at the
     moment.  */
  tok->tp.tok.chars = my_malloc (yyleng + 1);
  memcpy (tok->tp.tok.chars, yytext, yyleng);
}

/* Trace the value LEXRET and the position and token details being
   returned by the lexical analyser.  */

static void
dump_lex_value (int lexret) 
{
  int ix;
  fprintf (stderr, " %d l:%d c:%d ln:%d text=", lexret,
         ((struct prod_token_parm_item *) yylval)->tp.tok.lineno,
         ((struct prod_token_parm_item *) yylval)->tp.tok.charno,
         ((struct prod_token_parm_item *) yylval)->tp.tok.length);
  for (ix = 0; ix < yyleng; ix++) 
    {
      fprintf (stderr, "%c", yytext[ix]);
    }
  fprintf (stderr, " in hex:");
  for (ix = 0; ix < yyleng; ix++) 
    {
      fprintf (stderr, " %2.2x", yytext[ix]);
    }
  fprintf (stderr, "\n");
}  

