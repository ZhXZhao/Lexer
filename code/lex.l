%option noyywrap nodefault yylineno case-insensitive
%{
#include <stdio.h>
#include <stdarg.h>
#include "yacc.tab.h"
#include "ast_node.h"


%}

%s BTWMODE

%%

  /* keywords */

SELECT {return SELECT;}
FROM {return FROM;}
WHERE {return WHERE;}
<BTWMODE>AND {BEGIN INITIAL; return BTWAND;}
AND {return AND;}
OR {return OR;}
XOR {return XOR;}
NOT {return NOT;}
LIKE {return LIKE;}
IS {return IS;}
NULL {return NULLX;}
IN {return IN;}
EXISTS {return EXISTS;}
GROUP {return GROUP;}
BY {return BY;}
ASC {return ASC;}
DESC {return DESC;}
HAVING {return HAVING;}
ORDER {return ORDER;}
LIMIT {return LIMIT;}
ALL {return ALL;}
DISTINCT {return DISTINCT;}
AS {return AS;}
JOIN {return JOIN;}
INNER {return INNER;}
CROSS {return CROSS;}
OUTER {return OUTER;}
LEFT {return LEFT;}
RIGHT {return RIGHT;}
ON {return ON;}
BETWEEN {BEGIN BTWMODE; return BETWEEN;}
ANY {return ANY;}
SOME {return SOME;}
COUNT {return FCOUNT;}
DELETE {return DELETE;}
IGNORE {return IGNORE;}
QUICK {return QUICK;}
LOW_PRIORITY {return LOW_PRIORITY;}
INSERT {return INSERT;}
INTO {return INTO;}
VALUES? {return VALUES;}
UPDATE {return UPDATE;}
DEFAULT {return DEFAULT;}
SET {return SET;}

  /* number */
-?[0-9]+ {yylval.strval = strdup(yytext); return INTNUM;}
-?[0-9]+"."[0-9]* |
-?"."[0-9]+ |
-?[0-9]+"."[0-9]*E[-+]?[0-9]+ |
-?"."[0-9]+E[-+]?[0-9]+ {yylval.strval = strdup(yytext); return APPROXNUM;}

  /* booleans */
TRUE |
UNKNOWN |
FALSE {yylval.strval = strdup(yytext); return BOOL;}

  /* strings */
'(\\.|''|[^'\n])*' |
\"(\\.|\"\"|[^"\n])*\"  {yylval.strval = strdup(yytext); return STRING;}
'(\\.|[^'\n])*$   {yyerror("Unterminated string %s", yytext);}
\"(\\.|[^"\n])*$  {yyerror("Unterminated string %s", yytext);}

  /* hex strings */
X'[0-9A-F]+' |
0X[0-9A-F]+  {yylval.strval = strdup(yytext); return STRING;}

  /* bit strings */
0B[01]+ |
B'[01]+'  {yylval.strval = strdup(yytext); return STRING;}

  /* operators */
[-+&~|^/%*(),.;!] {return yytext[0];}
"&&" {return AND;}
"||" {return OR;}
"=" |
"<=>" |
">=" |
">" |
"<=" |
"<" |
"!=" |
"<>" {yylval.strval = strdup(yytext); return COMPARISON;}
"<<" |
">>" {yylval.strval = strdup(yytext); return SHIFT;}
":=" {return ASSIGN;}

  /* variables */
[A-Za-z][A-Za-z0-9_]* {yylval.strval = strdup(yytext); return NAME;}
'[^`/\\.\n]+' {yylval.strval = strdup(yytext+1); yylval.strval[yyleng-2]=0; return NAME;}
'[^`\n]*$ {yyerror("unterminated quoted name %s", yytext);}

  /* the others */
[ \t\n] {}
. {yyerror("mystery character '%c'", *yytext);}
%%
