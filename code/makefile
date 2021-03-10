sql-parser: lex.l yacc.y ast_node.h
	bison -dv yacc.y
	flex -o lex.lex.c lex.l
	g++ -o $@ yacc.tab.c lex.lex.c ast_node.c
