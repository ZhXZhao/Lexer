%{
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <stdio.h>
#include "ast_node.h"
void yyerror(const char *s, ...);
int yylex(void);
int select_opt_state = 0;
FILE *fp;
%}

%union {
    struct ast *a;
    char *strval;
    int intval;
}

  /* names and literal values */
%token <strval> NAME
%token <strval> STRING
%token <strval> INTNUM
%token <strval> BOOL
%token <strval> APPROXNUM

  /* operators and precedence levels */
%right ASSIGN
%left OR
%left XOR
%left AND
%nonassoc IN IS LIKE
%left NOT '!'
%left BETWEEN
%left <strval> COMPARISON
%left '|'
%left '&'
%left <strval> SHIFT
%left '+' '-'
%left '*' '/' '%' MOD
%left '^'
%nonassoc UMINUS

  /* keywords */
%token ADD
%token SUB
%token MUL
%token DIV
%token MOD
%token AND
%token OR
%token XOR
%token OROP
%token ANDOP
%token XOROP
%token SHIFT
%token NOT
%token COMPARISON
%token COMPARISON_ANY
%token COMPARISON_SOME
%token COMPARISON_ALL
%token BETWEEN
%token BTWAND
%token LIKE
%token NOTLIKE
%token IS
%token ISNOT
%token NULLX
%token IN
%token NOTIN
%token EXISTS
%token SELECT
%token SELECT_QUERY
%token FROM
%token WHERE
%token GROUP
%token BY
%token GROUP_BY
%token BY_NODE
%token ASC
%token DESC
%token HAVING
%token ORDER
%token ORDER_BY
%token LIMIT
%token INTO
%token ALL
%token DISTINCT
%token ALLCOLUMN
%token AS
%token DTNAME
%token JOIN
%token JOINTYPE
%token INNER
%token CROSS
%token OUTER
%token LEFT
%token RIGHT
%token ON
%token ANY
%token SOME
%token N_N_NODE
%token FUNC_NAME
%token FCOUNT
%token DELETE
%token IGNORE
%token LOW_PRIORITY
%token QUICK
%token DELETE_QUERY
%token INSERT
%token VALUES
%token INSERT_QUERY
%token UPDATE
%token INSERT_VALS
%token DEFAULT
%token SET
%token UPDATE_QUERY
%token SELECT_EXPR_LIST
%token SELECT_OPTS
%token TABLE_SUBQUERY

  /* syntax */
%type <a> stmt_list
%type <a> stmt
%type <a> expr
%type <a> val_list
%type <a> select_stmt
%type <a> opt_where
%type <a> opt_groupby
%type <a> groupby_list
%type <a> opt_asc_desc
%type <a> opt_having
%type <a> opt_orderby
%type <a> opt_limit
%type <a> opt_into_list
%type <a> column_list
%type <a> select_opts
%type <a> select_expr_list
%type <a> select_expr
%type <a> opt_as_alias
%type <a> table_references
%type <a> table_reference
%type <a> table_factor
%type <a> join_table
%type <a> opt_join_condition
%type <a> join_condition
%type <a> table_subquery
%type <a> opt_val_list
%type <a> delete_stmt
%type <a> delete_opts
%type <a> insert_stmt
%type <a> opt_col_names
%type <a> insert_vals_list
%type <a> insert_vals
%type <a> update_stmt
%type <a> update_asgn_list

%type <intval> opt_inner_cross
%type <intval> opt_outer
%type <intval> left_or_right

%start stmt_list

%%

stmt_list: stmt ';' {
    showtree($1, 0); 
    createjson($1, fp, 1); 
    fprintf(fp, "\n"); 
    free($1); 
    $1 = NULL;
}   
| stmt_list stmt ';' {
    showtree($2, 0); 
    createjson($2, fp, 1); 
    fprintf(fp, "\n"); 
    free($2); 
    $2 = NULL;
}
;

expr: NAME {$$ = newnode_value(NAME, $1);}
| NAME '.' NAME {struct ast *child = newnode_value(NAME, $1); child->nextnode = newnode_value(NAME, $3); $$ = newast(N_N_NODE, child);}
| STRING {$$ = newnode_value(STRING, $1);}
| INTNUM {$$ = newnode_value(INTNUM, $1);}
| BOOL {$$ = newnode_value(BOOL, $1);}
| APPROXNUM {$$ = newnode_value(APPROXNUM, $1);}
;
expr: expr '+' expr {struct ast *child = $1; child->nextnode = $3; $$ = newast(ADD, child);}
| expr '-' expr {struct ast *child = $1; child->nextnode = $3; $$ = newast(SUB, child);}
| expr '*' expr {struct ast *child = $1; child->nextnode = $3; $$ = newast(MUL, child);}
| expr '/' expr {struct ast *child = $1; child->nextnode = $3; $$ = newast(DIV, child);}
| expr '%' expr {struct ast *child = $1; child->nextnode = $3; $$ = newast(MOD, child);}
| expr MOD expr {struct ast *child = $1; child->nextnode = $3; $$ = newast(MOD, child);}
| '-' expr %prec UMINUS {$$ = newast(UMINUS, $2);}
| expr AND expr {struct ast *child = $1; child->nextnode = $3; $$ = newast(AND, child);}
| expr OR expr {struct ast *child = $1; child->nextnode = $3; $$ = newast(OR, child);}
| expr XOR expr {struct ast *child = $1; child->nextnode = $3; $$ = newast(XOR, child);}
| expr '|' expr {struct ast *child = $1; child->nextnode = $3; $$ = newast(OROP, child);}
| expr '&' expr {struct ast *child = $1; child->nextnode = $3; $$ = newast(ANDOP, child);}
| expr '^' expr {struct ast *child = $1; child->nextnode = $3; $$ = newast(XOROP, child);}
| expr SHIFT expr {struct ast *child = $1; child->nextnode = $3; $$ = newast_value(SHIFT, child, $2);}
| NOT expr {$$ = newast(NOT, $2);}
| '!' expr {$$ = newast(NOT, $2);}
| expr COMPARISON expr {struct ast *child = $1; child->nextnode = $3; $$ = newast_value(XOROP, child, $2);}
| expr BETWEEN expr BTWAND expr %prec BETWEEN {struct ast *child = $1; child->nextnode = $3; child->nextnode->nextnode = $5; $$ = newast(BETWEEN, child);}
| expr LIKE expr {struct ast *child = $1; child->nextnode = $3; $$ = newast(LIKE, child);}
| expr NOT LIKE expr {struct ast *child = $1; child->nextnode = $4; $$ = newast(NOTLIKE, child);}
| '(' expr ')' {$$ = $2;}
| expr COMPARISON '(' select_stmt ')' {struct ast *child = $1; child->nextnode = $4; $$ = newast_value(COMPARISON, child, $2);}
| expr COMPARISON ANY '(' select_stmt ')' {struct ast *child = $1; child->nextnode = $5; $$ = newast_value(COMPARISON_ANY, child, $2);}
| expr COMPARISON SOME '(' select_stmt ')' {struct ast *child = $1; child->nextnode = $5; $$ = newast_value(COMPARISON_SOME, child, $2);}
| expr COMPARISON ALL '(' select_stmt ')' {struct ast *child = $1; child->nextnode = $5; $$ = newast_value(COMPARISON_ALL, child, $2);}
;
expr: expr IS NULLX {struct ast *child = $1; child->nextnode = newnode(NULLX); $$ = newast(IS, child);}
| expr IS NOT NULLX {struct ast *child = $1; child->nextnode = newnode(NULLX); $$ = newast(ISNOT, child);}
| expr IS BOOL {struct ast *child = $1; child->nextnode = newnode_value(BOOL, $3); $$ = newast(IS, child);}
| expr IS NOT BOOL {struct ast *child = $1; child->nextnode = newnode_value(BOOL, $4); $$ = newast(ISNOT, child);}
;
val_list: expr {$$ = $1;}
| expr ',' val_list {$1->nextnode = $3; $$ = $1;}
;
opt_val_list: {$$ = NULL;}
| val_list {$$ = $1;}
;
expr: expr IN '(' val_list ')' {struct ast *child = $1; child->nextnode = $4; $$ = newast(IN, child);}
| expr NOT IN '(' val_list ')' {struct ast *child = $1; child->nextnode = $5; $$ = newast(NOTIN, child);}
| expr IN '(' select_stmt ')' {struct ast *child = $1; child->nextnode = $4; $$ = newast(IN, child);}
| expr NOT IN '(' select_stmt ')' {struct ast *child = $1; child->nextnode = $5; $$ = newast(NOTIN, child);}
| EXISTS '(' select_stmt ')' {struct ast *child = $3; $$ = newast(EXISTS, child);}
;
expr: NAME '(' opt_val_list ')' {struct ast *rtn = newnode_value(FUNC_NAME, $1); rtn->childnode = $3; $$ = rtn;}
;
expr: FCOUNT '(' '*' ')' {struct ast *rtn = newnode_value(FUNC_NAME, "COUNT"); rtn->childnode = newnode(ALLCOLUMN); $$ = rtn;}
| FCOUNT '(' expr ')' {struct ast *rtn = newnode_value(FUNC_NAME, "COUNT"); rtn->childnode = $3; $$ = rtn;}
;
  /* select */
stmt: select_stmt {$$ = $1;}
;
select_stmt: SELECT select_opts select_expr_list {
    struct ast *temp = newast(SELECT_EXPR_LIST, $3);
    if($2 != NULL){
        temp->nextnode = newast(SELECT_OPTS, $2);
    }
    $$ = newast(SELECT_QUERY, newast(SELECT, temp)); 
}
| SELECT select_opts select_expr_list FROM table_references opt_where opt_groupby opt_having opt_orderby opt_limit opt_into_list {
    struct ast *temp = newast(SELECT_EXPR_LIST, $3);
    if($2 != NULL){
        temp->nextnode = newast(SELECT_OPTS, $2);
    }
    struct ast *child = newast(SELECT, temp);
    struct ast *it = child;
    it->nextnode = newast(FROM, $5);
    it = it->nextnode;
    if($6 != NULL) { it->nextnode = $6; it = it->nextnode; } 
    if($7 != NULL) { it->nextnode = $7; it = it->nextnode; } 
    if($8 != NULL) { it->nextnode = $8; it = it->nextnode; } 
    if($9 != NULL) { it->nextnode = $9; it = it->nextnode; } 
    if($10 != NULL) { it->nextnode = $10; it = it->nextnode; } 
    if($11 != NULL) { it->nextnode = $11; it = it->nextnode; }
    $$ = newast(SELECT_QUERY, child);
}
;
select_opts: {select_opt_state = 0; $$ = NULL;}
| select_opts ALL {
    if(select_opt_state & 01){ /* check up repeat option */
        yyerror("repeat ALL and DISTINCT option");
    }
    select_opt_state = select_opt_state | 01;
    struct ast *nodelist = newnode(ALL);
    nodelist->nextnode = $1;
    $$ = nodelist;
}
| select_opts DISTINCT {
    if(select_opt_state & 01){
        yyerror("repeat ALL and DISTINCT option");
    }
    select_opt_state = select_opt_state | 01;
    struct ast *nodelist = newnode(DISTINCT);
    nodelist->nextnode = $1;
    $$ = nodelist;
}
;
select_expr_list: select_expr {$$ = $1;}
| select_expr_list ',' select_expr {struct ast *child = $3; child->nextnode = $1; $$ = child;}
| '*' {$$ = newnode(ALLCOLUMN);}
;
select_expr: expr opt_as_alias {
    if($2 != NULL){
        $2->childnode->nextnode = $1;
        $$ = $2;
    }else{
        $$ = $1;
    }
}
;
opt_as_alias: {$$ = NULL;}
| AS NAME {$$ = newast(AS, newnode_value(NAME, $2));}
| NAME {$$ = newast(AS, newnode_value(NAME, $1));}
;
table_references: table_reference {$$ = $1;}
| table_references ',' table_reference {
    struct ast *child = $1;
    child->nextnode = $3;
    struct ast *rtn = newast_value(JOINTYPE, child, "JOIN");
    $$ = rtn;
}
;
table_reference: table_factor {$$ = $1;}
| join_table {$$ = $1;}
;
table_factor: NAME opt_as_alias {
    struct ast *node = newnode_value(NAME, $1);
    if($2 == NULL){
        $$ = node;
    }else{
        node->nextnode = $2->childnode;
        $2->childnode = node;
        $$ = $2;
    }
}
| NAME '.' NAME opt_as_alias {
    struct ast *node = newnode_value(NAME, $1);
    node->nextnode = newnode_value(NAME, $3);
    node = newast(DTNAME, node);
    if($4 == NULL){
        $$ = node;
    }else{
        node->nextnode = $4->childnode;
        $4->childnode = node;
        $$ = $4;
    }
}
| table_subquery opt_as_alias {
    struct ast *child = $1;
    if($2 == NULL){
        $$ = newast(TABLE_SUBQUERY, child);
    }else{
        child->nextnode = $2;
        $$ = newast(TABLE_SUBQUERY, child);
    }
}
| '(' table_references ')' {$$ = $2;}
;
table_subquery: '(' select_stmt ')' {$$ = $2;}
;
join_table: table_reference opt_inner_cross JOIN table_factor opt_join_condition{
    struct ast *child = $1;
    child->nextnode = $4;
    child->nextnode->nextnode = $5;
    struct ast *rtn = NULL;
    if($2 == 0){
        rtn = newnode_value(JOINTYPE, "JOIN");
    }else if($2 == 1){
        rtn = newnode_value(JOINTYPE, "INNER_JOIN");
    }else if($2 == 2){
        rtn = newnode_value(JOINTYPE, "CROSS_JOIN");
    }
    rtn->childnode = child;
    $$ = rtn;
}
| table_reference left_or_right opt_outer JOIN table_reference join_condition{
    struct ast *child = $1;
    child->nextnode = $5;
    child->nextnode->nextnode = $6;
    struct ast *rtn = NULL;
    if($2 == 1 && $3 == 0){
        rtn = newnode_value(JOINTYPE, "LEFT_JOIN");
    }else if($2 == 1 && $3 == 1){
        rtn = newnode_value(JOINTYPE, "LEFT_OUTER_JOIN");
    }else if($2 == 2 && $3 == 0){
        rtn = newnode_value(JOINTYPE, "RIGHT_JOIN");
    }else if($2 == 2 && $3 == 1){
        rtn = newnode_value(JOINTYPE, "RIGHT_OUTER_JOIN");
    }
    rtn->childnode = child;
    $$ = rtn;
}
;
opt_inner_cross: {$$ = 0;}
| INNER {$$ = 1;}
| CROSS {$$ = 2;}
;
opt_outer: {$$ = 0;}
| OUTER {$$ = 1;}
;
left_or_right: LEFT {$$ = 1;}
| RIGHT {$$ = 2;}
;
opt_join_condition: {$$ = NULL;}
| join_condition {$$ = $1;}
;
join_condition: ON expr {$$ = newast(ON, $2);}
;
opt_where: {$$ = NULL;}
| WHERE expr {$$ = newast(WHERE, $2);}
;
opt_groupby: {$$ = NULL;}
| GROUP BY groupby_list {$$ = newast(GROUP_BY, $3);}
;
groupby_list: expr opt_asc_desc {
    if($2 != NULL){
        struct ast *child = $1;
        child->nextnode = $2;
        $$ = newast(BY_NODE, child);
    }else {
        $$ = $1;
    }
}
| groupby_list ',' expr opt_asc_desc {
    if($4 != NULL) {
        struct ast *child = $3;
        child->nextnode = $4;
        struct ast *temp = newast(BY_NODE, child);
        temp->nextnode = $1;
        $$ = temp;
    }else{
        $3->nextnode = $1;
        $$ = $3;
    }
}
;
opt_asc_desc: {$$ = NULL;}
| ASC {$$ = newnode(ASC);}
| DESC {$$ = newnode(DESC);}
;
opt_having: {$$ = NULL;}
| HAVING expr {$$ = newast(HAVING, $2);}
;
opt_orderby: {$$ = NULL;}
| ORDER BY groupby_list {$$ = newast(ORDER_BY, $3);}
;
opt_limit: {$$ = NULL;}
| LIMIT expr {$$ = newast(LIMIT, $2);}
| LIMIT expr ',' expr {$2->nextnode = $4; $$ = newast(LIMIT, $2);}
;
opt_into_list: {$$ = NULL;}
| INTO column_list {$$ = newast(INTO, $2);}
;
column_list: NAME {$$ = newnode_value(NAME, $1);}
| column_list ',' NAME {struct ast *node = newnode_value(NAME, $3); node->nextnode = $1; $$ = node;}
;
  /*delete*/
stmt: delete_stmt
;
delete_stmt: DELETE delete_opts FROM NAME opt_as_alias opt_where {
    struct ast *child = newnode(DELETE);
    child->childnode = $2;
    struct ast *temp = NULL;
    if($5 != NULL){
        temp = newnode_value(NAME, $4);
        temp->nextnode = $5->childnode;
        $5->childnode = temp;
        child->nextnode = newast(FROM, $5);
    }else{
        child->nextnode = newast(FROM, newnode_value(NAME, $4));
    }
    temp = child->nextnode;
    if($6 != NULL){
        temp->nextnode = $6;
        temp = temp->nextnode;
    }
    $$ = newast(DELETE_QUERY, child);
}
;
delete_opts: {$$ = NULL;}
| delete_opts LOW_PRIORITY {
    struct ast *node = newnode(LOW_PRIORITY);
    node->nextnode = $1;
    $$ = node;
}
| delete_opts QUICK {
    struct ast *node = newnode(QUICK);
    node->nextnode = $1;
    $$ = node;
}
| delete_opts IGNORE {
    struct ast *node = newnode(IGNORE);
    node->nextnode = $1;
    $$ = node;
}
;
  /* insert */
stmt: insert_stmt {$$ = $1;}
;
insert_stmt: INSERT INTO NAME opt_col_names VALUES insert_vals_list{
    struct ast *into_node = newnode(INTO);
    struct ast *node = newnode(INSERT);
    struct ast *temp = newnode_value(NAME, $3);
    if($4 != NULL){
        temp->childnode = $4;
    }
    into_node->childnode = temp;
    node->nextnode = into_node;
    temp = node->nextnode;
    temp->nextnode = newast(VALUES, $6);
    $$ = newast(INSERT_QUERY, node);
}
;
opt_col_names: {$$ = NULL;}
| '(' column_list ')' {$$ = $2;}
;

insert_vals_list: '(' insert_vals ')' {$$ = newast(INSERT_VALS, $2);}
| insert_vals_list ',' '(' insert_vals ')' {struct ast *node = newast(INSERT_VALS, $4); node->nextnode = $1; $$ = node;}
;
insert_vals: expr {$$ = $1;}
| DEFAULT {$$ = newnode(DEFAULT);}
| NULLX {$$ = newnode(NULLX);}
| insert_vals ',' expr {struct ast *temp = $3; temp->nextnode = $1; $$ = temp;}
| insert_vals ',' DEFAULT {struct ast *temp = newnode(DEFAULT); temp->nextnode = $1; $$ = temp;}
| insert_vals ',' NULLX {struct ast *temp = newnode(NULLX); temp->nextnode = $1; $$ = temp;}
;
insert_stmt: INSERT INTO NAME opt_col_names select_stmt {
    struct ast *into_node = newnode(INTO);
    struct ast *node = newnode(INSERT);
    struct ast *temp = newnode_value(NAME, $3);
    if($4 != NULL){
        temp->childnode = $4;
    }
    into_node->childnode = temp;
    node->nextnode = into_node;
    temp = node->nextnode;
    temp->nextnode = $5;
    $$ = newast(INSERT_QUERY, node);
}
;

  /* update */
stmt: update_stmt {$$ = $1;}
;
update_stmt: UPDATE table_references SET update_asgn_list opt_where {
    struct ast *node = newast(UPDATE, $2);
    node->nextnode = newast(SET, $4);
    struct ast *temp = node->nextnode;
    if($5 != NULL){
        temp->nextnode = $5;
    }
    $$ = newast(UPDATE_QUERY, node);
}
;
update_asgn_list: NAME COMPARISON expr {
    struct ast *node = newnode_value(NAME, $1);
    node->nextnode = $3;
    $$ = newast_value(COMPARISON, node, $2);
}
| NAME COMPARISON DEFAULT {
    struct ast *node = newnode_value(NAME, $1);
    node->nextnode = newnode(DEFAULT);
    $$ = newast_value(COMPARISON, node, $2);
}
| NAME '.' NAME COMPARISON expr {
    struct ast *node = newnode_value(NAME, $1);
    node->nextnode = newnode_value(NAME, $3);
    node = newast(DTNAME, node);
    node->nextnode = $5;
    $$ = newast_value(COMPARISON, node, $4);
}
| NAME '.' NAME COMPARISON DEFAULT {
    struct ast *node = newnode_value(NAME, $1);
    node->nextnode = newnode_value(NAME, $3);
    node = newast(DTNAME, node);
    node->nextnode = newnode(DEFAULT);
    $$ = newast_value(COMPARISON, node, $4);
}
| update_asgn_list ',' NAME COMPARISON expr {
    struct ast *node = newnode_value(NAME, $3);
    node->nextnode = $5;
    node = newast_value(COMPARISON, node, $4);
    node->nextnode = $1;
    $$ = node;
}
| update_asgn_list ',' NAME COMPARISON DEFAULT {
    struct ast *node = newnode_value(NAME, $3);
    node->nextnode = newnode(DEFAULT);
    node = newast_value(COMPARISON, node, $4);
    node->nextnode = $1;
    $$ = node;
}
| update_asgn_list ',' NAME '.' NAME COMPARISON expr {
    struct ast *node = newnode_value(NAME, $3);
    node->nextnode = newnode_value(NAME, $5);
    node = newast(DTNAME, node);
    node->nextnode = $7;
    node = newast_value(COMPARISON, node, $6);
    node->nextnode = $1;
    $$ = node;
}
| update_asgn_list ',' NAME '.' NAME COMPARISON DEFAULT {
    struct ast *node = newnode_value(NAME, $3);
    node->nextnode = newnode_value(NAME, $5);
    node = newast(DTNAME, node);
    node->nextnode = newnode(DEFAULT);
    node = newast_value(COMPARISON, node, $6);
    node->nextnode = $1;
    $$ = node;
}
;
%%

void yyerror(const char *s, ...){
    extern int yylineno;

    va_list ap;
    va_start(ap, s);
    fprintf(stderr, "%d:  error:", yylineno);
    vfprintf(stderr, s, ap);
    fprintf(stderr, "\n");
    // printf("error!");
}
int main(int argc, char **argv){
    extern FILE *yyin;
    yyin = fopen(argv[1], "r");
    if((fp = fopen("sql_ast.json", "w")) == NULL){
        printf("open outfile failed\n");
        exit(0);
    }
    yyparse();
    fclose(fp);
    return 0;
}