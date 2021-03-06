/****************************************************/
/* File: CM.y                                       */
/* The C-   Yacc/Bison specification file           */
/* Fatemeh Hosseini                                 */
/****************************************************/
%{
#define YYPARSER /* distinguishes Yacc output from other code files */
#define YYDEBUG 1 
#include "globals.h"
#include "util.h"
#include "scan.h"
#include "parse.h"

#define YYSTYPE TreeNode * /*return type by yyparse procedure, enbale us to create syntax tree*/
static char * savedName; /* for use in assignments, temporarily stores identifier string to be inserted in TreeNode that is not created yet */
static char * savedNUM;
static char * savedFunName;
static char * savedVarName;
static int savedVarLineNo;
static int savedFunLineNo;
static int savedLineNo;  /* proper source code line number will be accosiated with identifiers */
static TreeNode * savedTree; /* temporarily stores syntax tree for later return */
static int yylex();
int yyerror(char * s);

static int firstTime = 1; //only at the first time, yyin and yyout are getting values in getToken

%}
%token    ENDFILE ERROR
%token    IF ELSE WHILE RETURN VOID BOOL TRUE FALSE INT NOT
%token    ID NUM
%token    ASSIGN EQ NQ LT GT LE GE PLUS MINUS TIMES OVER LPAREN RPAREN SEMI COMMA LBRACK RBRACK LCBRACK RCBRACK AND OR
%%
program : declaration_list
		{ savedTree = $1;} 
        ;
declaration_list : declaration_list declaration
			{
			 YYSTYPE t = $1;
                         if (t != NULL)
                          { while (t->sibling != NULL)
                                   t = t->sibling;
                            t->sibling = $2;
                            $$ = $1; }
                         else $$ = $2;
			}
		 | declaration {$$ = $1;}
                 ;
declaration : var_declaration {$$ = $1;}
	    | fun_declaration {$$ = $1;}
	    ;
var_declaration : INT ID { savedVarName = copyString(tokenString); savedVarLineNo = lineno;
			   //fprintf(listing,"var name:%s\n",savedVarName);	
			  }
                  SEMI 
		   {
		    $$ = newDecNode(VarK);
                    $$->attr.name = savedVarName;
                    $$->type = Integer;
		    $$->lineno = savedVarLineNo;
		   }
		| INT ID { savedVarName = copyString(tokenString); savedVarLineNo = lineno;}
		  LBRACK NUM { savedNUM = copyString(tokenString);}
                  RBRACK SEMI
		   {
		    $$ = newDecNode(ArrayK);
		    $$->attr.name = savedVarName;
		    $$->type = Integer;
		    $$->lineno = savedVarLineNo;
		    $$->isArray = 1; //True
		    $$->value = atoi(savedNUM);
		   }
		;

fun_declaration : INT ID {savedFunName = copyString(tokenString); savedFunLineNo = lineno;}
	          LPAREN params RPAREN compound_stmt
	  	   {
		    $$ = newDecNode(FunK);
		    $$->attr.name = savedFunName;
		    $$->type = Integer;
		    $$->lineno = savedFunLineNo;
		    $$->child[0] = $5;
		    $$->child[1] = $7;
		    
		   }
		| VOID ID
			   {savedFunName = copyString(tokenString); savedFunLineNo = lineno;
			    //fprintf(listing,"savedName:%s\n",savedName);
			    }
	          LPAREN params RPAREN compound_stmt
	  	   {//fprintf(listing,"func:%s\n",savedName);
		    $$ = newDecNode(FunK);
		    $$->attr.name = savedFunName;
		    $$->type = Void;
		    $$->lineno = savedFunLineNo;
		    $$->child[0] = $5;
		    $$->child[1] = $7;
		    //if ($$->child[1] == NULL) fprintf(listing,"no compound_stmt\n");
		    //else fprintf(listing,"compound_stmt is not NULL\n");
		   }
		;
params : param_list {$$ = $1;}
       | VOID {$$ = NULL;}
       ;
param_list : param_list COMMA param
		{
		 YYSTYPE t = $1;
                 if (t != NULL)
                  { while (t->sibling != NULL)
                           t = t->sibling;
                    t->sibling = $3;
                    $$ = $1; }
                    else $$ = $3;
		}
           | param {$$ = $1;}
	   ;
param : INT ID
	{
	 $$ = newDecNode(VarK);
	 $$->attr.name = copyString(tokenString);
         $$->type = Integer;
	 $$->lineno = lineno;
         $$->isParameter = 1; //True
	 $$->param_size += 1;
	}
      | INT ID {savedName = copyString(tokenString); savedLineNo = lineno;}
	LBRACK RBRACK
	{
	 $$ = newDecNode(ArrayK);
	 $$->attr.name = savedName;
	 $$->type = Integer;
	 $$->lineno = savedLineNo;
	 $$->isParameter = 1; //True
	 $$->param_size += 1;
	 $$->isArray = 1; //True
        }
      ;
compound_stmt : LCBRACK local_declarations statement_list RCBRACK
		 {//fprintf(listing,"compound_statement\n");
		  $$ = newStmtNode(CompoundK);
		  $$->child[0] = $2;
		  $$->child[1] = $3;
		  $$->lineno = lineno;
		 }
	      ;
local_declarations : local_declarations var_declaration
			{ //fprintf(listing,"local_declarations\n");
			  YYSTYPE t = $1;
                   	  if (t != NULL)
                           { while (t->sibling != NULL)
                       	        t = t->sibling;
                    	     t->sibling = $2;
                    	     $$ = $1; }
                    	   else $$ = $2;
                        }
                   | %empty {$$ = NULL;}
		   ;
statement_list : statement_list statement
		 { //fprintf(listing,"statement_list\n ");
		   YYSTYPE t = $1;
                   if (t != NULL)
                   { while (t->sibling != NULL)
                        t = t->sibling;
                     t->sibling = $2;
                     $$ = $1; }
                   else $$ = $2;
                 }
               | %empty {$$ = NULL;}
	       ;
statement : expression_stmt {$$ = $1;}
          | compound_stmt {$$ = $1;}
          | selection_stmt {$$ = $1;}
          | iteration_stmt {$$ = $1;}
          | return_stmt {$$ = $1;}
	  ;
expression_stmt : expression SEMI {$$ = $1;}
                | SEMI {$$ = NULL;}
		;
selection_stmt  : IF LPAREN expression RPAREN statement
		   { $$ = newStmtNode(IfK);
                     $$->child[0] = $3;
                     $$->child[1] = $5;
		     $$->lineno = lineno;
                   }
                | IF LPAREN expression RPAREN statement ELSE statement
		   { $$ = newStmtNode(IfK);
                     $$->child[0] = $3;
                     $$->child[1] = $5;
                     $$->child[2] = $7;
		     $$->lineno = lineno;
                   }
                ;
iteration_stmt : WHILE LPAREN expression RPAREN statement
		  { $$ = newStmtNode(WhileK);
                    $$->child[0] = $3;
                    $$->child[1] = $5;
		    $$->lineno = lineno;
                  }
               ;
return_stmt : RETURN SEMI
	       { $$ = newStmtNode(ReturnK);
                 $$->child[0] = NULL;
                 $$->lineno = lineno;
               }
            | RETURN expression SEMI
	       {  $$ = newStmtNode(ReturnK);
                  $$->child[0] = $2;
		  $$->lineno = lineno;
               }
            ;
expression : var ASSIGN expression
		{//fprintf(listing,"assigned value:%d\n",$3->attr.val);
		 $$ = newExpNode(AssignK);
                 $$->child[0] = $1;
                 $$->child[1] = $3;
                 $$->attr.val = $3->attr.val;
		 $$->lineno = lineno;
		}
           | simple_expression {$$ = $1;}
           ;
var : ID {$$ = newExpNode(IdK);
          $$->attr.name = copyString(tokenString);
	  $$->lineno = lineno;
	 }
    | ID {savedName = copyString(tokenString); savedLineNo = lineno;}
      LBRACK expression RBRACK
	{
	 $$ = newDecNode(ArrayK);
	 $$->attr.name = savedName;
	 $$->isArray = 1; //True
         $$->value = $4->attr.val; //array size
	 $$->lineno = savedLineNo;
	}
    ;
simple_expression : additive_expression LE additive_expression
			{
		   	 $$ = newExpNode(OpK);
                  	 $$->child[0] = $1;
                  	 $$->child[1] = $3;
                  	 $$->attr.op = LE;
			 $$->lineno = lineno;
			}
		  | additive_expression LT additive_expression 
                	 { $$ = newExpNode(OpK);
                  	   $$->child[0] = $1;
                  	   $$->child[1] = $3;
                  	   $$->attr.op = LT;
			   $$->lineno = lineno;
                	 }
		  | additive_expression GT additive_expression 
                	 { $$ = newExpNode(OpK);
                  	   $$->child[0] = $1;
	                   $$->child[1] = $3;
        	           $$->attr.op = GT;
			   $$->lineno = lineno;
                 	}
		  | additive_expression GE additive_expression 
                	 { $$ = newExpNode(OpK);
	                   $$->child[0] = $1;
        	           $$->child[1] = $3;
                	   $$->attr.op = GE;
			   $$->lineno = lineno;
                 	}
		  | additive_expression EQ additive_expression 
	                 { $$ = newExpNode(OpK);
        	           $$->child[0] = $1;
                	   $$->child[1] = $3;
                   	   $$->attr.op = EQ;
			   $$->lineno = lineno;
                 	}
		  | additive_expression NQ additive_expression 
	                 { $$ = newExpNode(OpK);
        	           $$->child[0] = $1;
                	   $$->child[1] = $3;
                 	   $$->attr.op = NQ;
			   $$->lineno = lineno;
                 	 }
                  | additive_expression {$$ = $1;}
		  ;

additive_expression : additive_expression PLUS term 
			{
			  $$ = newExpNode(OpK);
          	          $$->child[0] = $1;
	                  $$->child[1] = $3;
                  	  $$->attr.op = PLUS;
			  $$->lineno = lineno;
			 }
		    | additive_expression MINUS term
			{
			 $$ = newExpNode(OpK);
			 $$->child[0] = $1;
			 $$->child[1] = $3;
			 $$->attr.op = MINUS;
			 $$->lineno = lineno;
			}
                    | term {$$ = $1;}
		    ;
term : term TIMES factor
	{
	 $$ = newExpNode(OpK);
         $$->child[0] = $1;
         $$->child[1] = $3;
         $$->attr.op = TIMES;
	 $$->lineno = lineno;
	}
     | term OVER factor
	{
	 $$ = newExpNode(OpK);
	 $$->child[0] = $1;
	 $$->child[1] = $3;
	 $$->attr.op = OVER;
	 $$->lineno = lineno;
	}
     | factor {$$ = $1;}
     ;

factor : LPAREN expression RPAREN
	     {$$ = $2;}
       | var {$$ = $1;}
       | call {$$ = $1;}
       | NUM {$$ = newExpNode(ConstK);
              $$->attr.val = atoi(tokenString);}
       | error {$$ = NULL;}
       ;
call : ID {savedName = copyString(tokenString); savedLineNo = lineno;} 
       LPAREN args RPAREN
	{
	 $$ = newStmtNode(CallK);
         $$->child[0] = $4;
         $$->attr.name = savedName;
	 $$->lineno = savedLineNo;
	}
     ;
args : arg_list {$$ = $1;}
     | %empty {$$ = NULL;}
     ;
arg_list : arg_list COMMA expression 
	   {
	    YYSTYPE t = $1;
            if (t != NULL)
             { while (t->sibling != NULL)
                      t = t->sibling;
               t->sibling = $3;
               $$ = $1; }
            else $$ = $3;
	   }
         | expression {$$ = $1;}
	 ;

%%

int yyerror(char * message)
{ fprintf(listing,"Syntax error at line %d: %s\n",lineno,message);
  fprintf(listing,"Current token: ");
  printToken(yychar,tokenString);
  Error = TRUE;
  return 0;
}

/* yylex calls getToken to make Yacc/Bison output
 * compatible with ealier versions of the C- scanner
 */
static int yylex(void)
{
 
 TokenType t = getToken(firstTime);
 firstTime = 0;
 if(t != EOF)
  {//printf("not EOF\n");
    return t;
  }
 return 0;
}

TreeNode * parse(void)
{ 
  yyparse();
  return savedTree;
}
/****************************************************/
/* File: CM.y                                       */
/* The C-   Yacc/Bison specification file           */
/* Fatemeh Hosseini                                 */
/****************************************************/
%{
#define YYPARSER /* distinguishes Yacc output from other code files */
#define YYDEBUG 1 
#include "globals.h"
#include "util.h"
#include "scan.h"
#include "parse.h"

#define YYSTYPE TreeNode * /*return type by yyparse procedure, enbale us to create syntax tree*/
static char * savedName; /* for use in assignments, temporarily stores identifier string to be inserted in TreeNode that is not created yet */
static char * savedNUM;
static char * savedFunName;
static char * savedVarName;
static int savedVarLineNo;
static int savedFunLineNo;
static int savedLineNo;  /* proper source code line number will be accosiated with identifiers */
static TreeNode * savedTree; /* temporarily stores syntax tree for later return */
static int yylex();
int yyerror(char * s);

static int firstTime = 1; //only at the first time, yyin and yyout are getting values in getToken

%}
%token    ENDFILE ERROR
%token    IF ELSE WHILE RETURN VOID BOOL TRUE FALSE INT NOT
%token    ID NUM
%token    ASSIGN EQ NQ LT GT LE GE PLUS MINUS TIMES OVER LPAREN RPAREN SEMI COMMA LBRACK RBRACK LCBRACK RCBRACK AND OR
%%
program : declaration_list
		{ savedTree = $1;} 
        ;
declaration_list : declaration_list declaration
			{
			 YYSTYPE t = $1;
                         if (t != NULL)
                          { while (t->sibling != NULL)
                                   t = t->sibling;
                            t->sibling = $2;
                            $$ = $1; }
                         else $$ = $2;
			}
		 | declaration {$$ = $1;}
                 ;
declaration : var_declaration {$$ = $1;}
	    | fun_declaration {$$ = $1;}
	    ;
var_declaration : INT ID { savedVarName = copyString(tokenString); savedVarLineNo = lineno;
			   //fprintf(listing,"var name:%s\n",savedVarName);	
			  }
                  SEMI 
		   {
		    $$ = newDecNode(VarK);
                    $$->attr.name = savedVarName;
                    $$->type = Integer;
		    $$->lineno = savedVarLineNo;
		   }
		| INT ID { savedVarName = copyString(tokenString); savedVarLineNo = lineno;}
		  LBRACK NUM { savedNUM = copyString(tokenString);}
                  RBRACK SEMI
		   {
		    $$ = newDecNode(ArrayK);
		    $$->attr.name = savedVarName;
		    $$->type = Integer;
		    $$->lineno = savedVarLineNo;
		    $$->isArray = 1; //True
		    $$->value = atoi(savedNUM);
		   }
		;

fun_declaration : INT ID {savedFunName = copyString(tokenString); savedFunLineNo = lineno;}
	          LPAREN params RPAREN compound_stmt
	  	   {
		    $$ = newDecNode(FunK);
		    $$->attr.name = savedFunName;
		    $$->type = Integer;
		    $$->lineno = savedFunLineNo;
		    $$->child[0] = $5;
		    $$->child[1] = $7;
		    
		   }
		| VOID ID
			   {savedFunName = copyString(tokenString); savedFunLineNo = lineno;
			    //fprintf(listing,"savedName:%s\n",savedName);
			    }
	          LPAREN params RPAREN compound_stmt
	  	   {//fprintf(listing,"func:%s\n",savedName);
		    $$ = newDecNode(FunK);
		    $$->attr.name = savedFunName;
		    $$->type = Void;
		    $$->lineno = savedFunLineNo;
		    $$->child[0] = $5;
		    $$->child[1] = $7;
		    //if ($$->child[1] == NULL) fprintf(listing,"no compound_stmt\n");
		    //else fprintf(listing,"compound_stmt is not NULL\n");
		   }
		;
params : param_list {$$ = $1;}
       | VOID {$$ = NULL;}
       ;
param_list : param_list COMMA param
		{
		 YYSTYPE t = $1;
                 if (t != NULL)
                  { while (t->sibling != NULL)
                           t = t->sibling;
                    t->sibling = $3;
                    $$ = $1; }
                    else $$ = $3;
		}
           | param {$$ = $1;}
	   ;
param : INT ID
	{
	 $$ = newDecNode(VarK);
	 $$->attr.name = copyString(tokenString);
         $$->type = Integer;
	 $$->lineno = lineno;
         $$->isParameter = 1; //True
	 $$->param_size += 1;
	}
      | INT ID {savedName = copyString(tokenString); savedLineNo = lineno;}
	LBRACK RBRACK
	{
	 $$ = newDecNode(ArrayK);
	 $$->attr.name = savedName;
	 $$->type = Integer;
	 $$->lineno = savedLineNo;
	 $$->isParameter = 1; //True
	 $$->param_size += 1;
	 $$->isArray = 1; //True
        }
      ;
compound_stmt : LCBRACK local_declarations statement_list RCBRACK
		 {//fprintf(listing,"compound_statement\n");
		  $$ = newStmtNode(CompoundK);
		  $$->child[0] = $2;
		  $$->child[1] = $3;
		  $$->lineno = lineno;
		 }
	      ;
local_declarations : local_declarations var_declaration
			{ //fprintf(listing,"local_declarations\n");
			  YYSTYPE t = $1;
                   	  if (t != NULL)
                           { while (t->sibling != NULL)
                       	        t = t->sibling;
                    	     t->sibling = $2;
                    	     $$ = $1; }
                    	   else $$ = $2;
                        }
                   | %empty {$$ = NULL;}
		   ;
statement_list : statement_list statement
		 { //fprintf(listing,"statement_list\n ");
		   YYSTYPE t = $1;
                   if (t != NULL)
                   { while (t->sibling != NULL)
                        t = t->sibling;
                     t->sibling = $2;
                     $$ = $1; }
                   else $$ = $2;
                 }
               | %empty {$$ = NULL;}
	       ;
statement : expression_stmt {$$ = $1;}
          | compound_stmt {$$ = $1;}
          | selection_stmt {$$ = $1;}
          | iteration_stmt {$$ = $1;}
          | return_stmt {$$ = $1;}
	  ;
expression_stmt : expression SEMI {$$ = $1;}
                | SEMI {$$ = NULL;}
		;
selection_stmt  : IF LPAREN expression RPAREN statement
		   { $$ = newStmtNode(IfK);
                     $$->child[0] = $3;
                     $$->child[1] = $5;
		     $$->lineno = lineno;
                   }
                | IF LPAREN expression RPAREN statement ELSE statement
		   { $$ = newStmtNode(IfK);
                     $$->child[0] = $3;
                     $$->child[1] = $5;
                     $$->child[2] = $7;
		     $$->lineno = lineno;
                   }
                ;
iteration_stmt : WHILE LPAREN expression RPAREN statement
		  { $$ = newStmtNode(WhileK);
                    $$->child[0] = $3;
                    $$->child[1] = $5;
		    $$->lineno = lineno;
                  }
               ;
return_stmt : RETURN SEMI
	       { $$ = newStmtNode(ReturnK);
                 $$->child[0] = NULL;
                 $$->lineno = lineno;
               }
            | RETURN expression SEMI
	       {  $$ = newStmtNode(ReturnK);
                  $$->child[0] = $2;
		  $$->lineno = lineno;
               }
            ;
expression : var ASSIGN expression
		{//fprintf(listing,"assigned value:%d\n",$3->attr.val);
		 $$ = newExpNode(AssignK);
                 $$->child[0] = $1;
                 $$->child[1] = $3;
                 $$->attr.val = $3->attr.val;
		 $$->lineno = lineno;
		}
           | simple_expression {$$ = $1;}
           ;
var : ID {$$ = newExpNode(IdK);
          $$->attr.name = copyString(tokenString);
	  $$->lineno = lineno;
	 }
    | ID {savedName = copyString(tokenString); savedLineNo = lineno;}
      LBRACK expression RBRACK
	{
	 $$ = newDecNode(ArrayK);
	 $$->attr.name = savedName;
	 $$->isArray = 1; //True
         $$->value = $4->attr.val; //array size
	 $$->lineno = savedLineNo;
	}
    ;
simple_expression : additive_expression LE additive_expression
			{
		   	 $$ = newExpNode(OpK);
                  	 $$->child[0] = $1;
                  	 $$->child[1] = $3;
                  	 $$->attr.op = LE;
			 $$->lineno = lineno;
			}
		  | additive_expression LT additive_expression 
                	 { $$ = newExpNode(OpK);
                  	   $$->child[0] = $1;
                  	   $$->child[1] = $3;
                  	   $$->attr.op = LT;
			   $$->lineno = lineno;
                	 }
		  | additive_expression GT additive_expression 
                	 { $$ = newExpNode(OpK);
                  	   $$->child[0] = $1;
	                   $$->child[1] = $3;
        	           $$->attr.op = GT;
			   $$->lineno = lineno;
                 	}
		  | additive_expression GE additive_expression 
                	 { $$ = newExpNode(OpK);
	                   $$->child[0] = $1;
        	           $$->child[1] = $3;
                	   $$->attr.op = GE;
			   $$->lineno = lineno;
                 	}
		  | additive_expression EQ additive_expression 
	                 { $$ = newExpNode(OpK);
        	           $$->child[0] = $1;
                	   $$->child[1] = $3;
                   	   $$->attr.op = EQ;
			   $$->lineno = lineno;
                 	}
		  | additive_expression NQ additive_expression 
	                 { $$ = newExpNode(OpK);
        	           $$->child[0] = $1;
                	   $$->child[1] = $3;
                 	   $$->attr.op = NQ;
			   $$->lineno = lineno;
                 	 }
                  | additive_expression {$$ = $1;}
		  ;

additive_expression : additive_expression PLUS term 
			{
			  $$ = newExpNode(OpK);
          	          $$->child[0] = $1;
	                  $$->child[1] = $3;
                  	  $$->attr.op = PLUS;
			  $$->lineno = lineno;
			 }
		    | additive_expression MINUS term
			{
			 $$ = newExpNode(OpK);
			 $$->child[0] = $1;
			 $$->child[1] = $3;
			 $$->attr.op = MINUS;
			 $$->lineno = lineno;
			}
                    | term {$$ = $1;}
		    ;
term : term TIMES factor
	{
	 $$ = newExpNode(OpK);
         $$->child[0] = $1;
         $$->child[1] = $3;
         $$->attr.op = TIMES;
	 $$->lineno = lineno;
	}
     | term OVER factor
	{
	 $$ = newExpNode(OpK);
	 $$->child[0] = $1;
	 $$->child[1] = $3;
	 $$->attr.op = OVER;
	 $$->lineno = lineno;
	}
     | factor {$$ = $1;}
     ;

factor : LPAREN expression RPAREN
	     {$$ = $2;}
       | var {$$ = $1;}
       | call {$$ = $1;}
       | NUM {$$ = newExpNode(ConstK);
              $$->attr.val = atoi(tokenString);}
       | error {$$ = NULL;}
       ;
call : ID {savedName = copyString(tokenString); savedLineNo = lineno;} 
       LPAREN args RPAREN
	{
	 $$ = newStmtNode(CallK);
         $$->child[0] = $4;
         $$->attr.name = savedName;
	 $$->lineno = savedLineNo;
	}
     ;
args : arg_list {$$ = $1;}
     | %empty {$$ = NULL;}
     ;
arg_list : arg_list COMMA expression 
	   {
	    YYSTYPE t = $1;
            if (t != NULL)
             { while (t->sibling != NULL)
                      t = t->sibling;
               t->sibling = $3;
               $$ = $1; }
            else $$ = $3;
	   }
         | expression {$$ = $1;}
	 ;

%%

int yyerror(char * message)
{ fprintf(listing,"Syntax error at line %d: %s\n",lineno,message);
  fprintf(listing,"Current token: ");
  printToken(yychar,tokenString);
  Error = TRUE;
  return 0;
}

/* yylex calls getToken to make Yacc/Bison output
 * compatible with ealier versions of the C- scanner
 */
static int yylex(void)
{
 
 TokenType t = getToken(firstTime);
 firstTime = 0;
 if(t != EOF)
  {//printf("not EOF\n");
    return t;
  }
 return 0;
}

TreeNode * parse(void)
{ 
  yyparse();
  return savedTree;
}
