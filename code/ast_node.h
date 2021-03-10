#ifndef PARSE_NODE_H
#define PARSE_NODE_H

#include "yacc.tab.h"
#include <string.h>

extern int yylineno;

struct ast {
    int nodetype;
    const char *val;
    struct ast *nextnode;
    struct ast *childnode;
};

void yyerror(const char *s, ...);
struct ast *newast(int nodetype, struct ast *childnode);
struct ast *newast_value(int nodetype, struct ast *childnode, const char *val);
struct ast *newnode_value(int nodetype, const char *val);
struct ast *newnode(int nodetype);
void showtree(struct ast *node, int layer);
void createjson(struct ast *node, FILE *writerstr, int state);
const char *getelemname(int nodetype);
#endif


