#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "ast_node.h"
#include "yacc.tab.h"

  /* new an ast */
struct ast *newast(int nodetype, struct ast *childnode){
    struct ast *a = (struct ast *)malloc(sizeof(struct ast));
    if(!a){
      yyerror("out of space!");
      exit(0);
    }
    a->nodetype = nodetype;
    a->nextnode = NULL;
    a->childnode = childnode;
    return a;
}

  /* new an ast with value */
struct ast *newast_value(int nodetype, struct ast *childnode, const char *val){
  struct ast *a = (struct ast *)malloc(sizeof(struct ast));
  if(!a){
    yyerror("out of space!");
    exit(0);
  }
  a->nodetype = nodetype;
  a->nextnode = NULL;
  a->childnode = childnode;
  a->val = val;
  return a;
}

  /* new a node for ast */
struct ast *newnode(int nodetype){
  struct ast *a = (struct ast *)malloc(sizeof(struct ast));
  if(!a){
    yyerror("out of space!");
    exit(0);
  }
  a->nodetype = nodetype;
  a->nextnode = NULL;
  a->childnode = NULL;
}

  /* new a node with value */
struct ast *newnode_value(int nodetype, const char *val){
  struct ast *a = (struct ast *)malloc(sizeof(struct ast));
  if(!a){
    yyerror("out of space!");
    exit(0);
  }
  a->nodetype = nodetype;
  a->nextnode = NULL;
  a->childnode = NULL;
  a->val = val;
  return a;
}

  /* dfs show ast */
void showtree(struct ast *node, int layer){
  if(node == NULL){
    return;
  }else{
    for(int i = 0;i < layer; i++){
      printf("\t");
    }
    if(node->val == NULL){
      printf("%s\n", getelemname(node->nodetype));
    }else{
      printf("%s\n", node->val);
    }
    if(node->childnode != NULL){
      struct ast *temp = node->childnode;
      while(temp != NULL){
        showtree(temp, layer+1);
        temp = temp->nextnode;
      }
    }
  }
  return;
}

  /* transfer ast to json */
void createjson(struct ast *node, FILE *fp, int state)
{
    if(node == NULL) return;
    if(state == 0) fprintf(fp, ",");
    fprintf(fp, "{");
    fprintf(fp, "\"nodetype\":");
    fprintf(fp, "\"");
    fprintf(fp, "%s", getelemname(node->nodetype));
    fprintf(fp, "\"");
    //value
    if(node->val != NULL){
        fprintf(fp, ",\"value\":");
        fprintf(fp, "\"");
        fprintf(fp, "%s", node->val);
        fprintf(fp, "\"");
    }
    //child_node
    if(node->childnode != NULL){
        fprintf(fp, ",\"child_node\":[");
        struct ast *temp = node->childnode;
        createjson(temp, fp,1);
        temp = temp->nextnode;
        while(temp != NULL){
            createjson(temp, fp,0);
            temp = temp->nextnode;
        }
        fprintf(fp, "]");
    }
    fprintf(fp, "}");
}

  /* enum to const char* */
const char *getelemname(int nodetype){
  const char *s;
  switch(nodetype){
    case ADD : s = "+"; break;
    case SUB : s = "-"; break;
    case MUL : s = "*"; break;
    case DIV : s = "/"; break;
    case MOD : s = "%"; break;
    case AND : s = "AND"; break;
    case OR : s = "OR"; break;
    case XOR : s = "XOR"; break;
    case OROP : s = "|"; break;
    case ANDOP : s = "&"; break;
    case XOROP : s = "^"; break;
    case NOT : s = "NOT"; break;
    case BETWEEN : s = "BETWEEN"; break;
    case LIKE : s = "LIKE"; break;
    case NOTLIKE : s = "NOTLIKE"; break;
    case IS : s = "IS"; break;
    case ISNOT : s = "ISNOT"; break;
    case IN : s = "NOTIN"; break;
    case NOTIN : s = "NOTIN"; break;
    case EXISTS : s = "EXISTS"; break;
    case SELECT_QUERY : s = "SELECT_QUERY"; break;
    case SELECT : s = "SELECT"; break;
    case FROM : s = "FROM"; break;
    case WHERE : s = "WHERE"; break;
    case GROUP_BY : s = "GROUP_BY"; break;
    case BY_NODE : s = "BY_NODE"; break;
    case ASC : s = "ASC"; break;
    case DESC : s = "DESC"; break;
    case HAVING : s = "HAVING"; break;
    case ORDER_BY : s = "ORDER_BY"; break;
    case LIMIT : s = "LIMIT"; break;
    case ALL : s = "ALL"; break;
    case DISTINCT : s = "DISTINCT"; break;
    case AS : s = "AS"; break;
    case DTNAME : s = "DTNAME"; break;
    case ON : s = "ON"; break;
    case ALLCOLUMN : s = "*"; break;
    case DELETE : s = "DELETE"; break;
    case DELETE_QUERY : s = "DELETE_QUERY"; break;
    case INSERT : s = "INSERT"; break;
    case INTO : s = "INTO"; break;
    case VALUES : s = "VALUES"; break;
    case INSERT_QUERY : s = "INSERT_QUERY"; break;
    case INSERT_VALS : s = "INSERT_VALS"; break;
    case DEFAULT : s = "DEFAULT"; break;
    case SET : s = "SET"; break;
    case UPDATE : s = "UPDATE"; break;
    case NAME : s = "NAME"; break;
    case STRING : s = "STRING"; break;
    case INTNUM : s = "INTNUM"; break;
    case BOOL : s = "BOOL"; break;
    case APPROXNUM : s = "APPROXNUM"; break;
    case COMPARISON : s = "COMPARISON"; break;
    case COMPARISON_ANY : s = "COMPARISON_ANY"; break;
    case COMPARISON_SOME : s = "COMPARISON_SOME"; break;
    case COMPARISON_ALL : s = "COMPARISON_ALL"; break;
    case UPDATE_QUERY : s = "UPDATE_QUERY"; break;
    case SELECT_EXPR_LIST : s = "SELECT_EXPR_LIST"; break;
    case SELECT_OPTS : s = "SELECT_OPTS"; break;
    case N_N_NODE : s = "N_N_NODE"; break;
    case TABLE_SUBQUERY : s = "TABLE_SUBQUERY"; break;
    case JOINTYPE : s = "JOINTYPE"; break;
    case NULLX : s = "NULL"; break;
    case LOW_PRIORITY : s = "LOW_PRIORITY"; break;
    case QUICK : s = "QUICK"; break;
    case IGNORE : s = "IGNORE"; break;
    case FUNC_NAME: s = "FUNC_NAME"; break;
  }
  return s;
}
