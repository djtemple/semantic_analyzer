/****************************************************/
/* File: analyze.c                                  */
/* Semantic analyzer                                */
/*                                                  */
/*                                                  */
/*                                                  */
/****************************************************/

#include "globals.h"
#include "symtab.h"
#include "analyze.h"



/* counter for variable memory locations */
static int location[1000];
int scope_a = 0;
int num_scopes = 0;
static int No_change = 0;
int tempScope = 0;
/* Procedure traverse is a generic recursive 
 * syntax tree traversal routine:
 * it applies preProc in preorder and postProc 
 * in postorder to tree pointed to by t
 */
static void traverse( TreeNode * t,
               void (* preProc) (TreeNode *),
               void (* postProc) (TreeNode *) )
{ if (t != NULL)
  {
    if(t->nodekind == DecK && t->kind.dec == FunK){
        ++num_scopes;
          scope_a = num_scopes;

    }
    preProc(t);

    int i;

    for (i=0; i < MAXCHILDREN; i++) {

        traverse(t->child[i], preProc, postProc);

    }
      if(t->kind.dec == FunK){
          scope_a = 0;

      }
    postProc(t);
    traverse(t->sibling,preProc,postProc);
  }
}

/* nullProc is a do-nothing procedure to 
 * generate preorder-only or postorder-only
 * traversals from traverse
 */
static void nullProc(TreeNode * t)
{ if (t==NULL) return;
  else return;
}

static void typeError(TreeNode * t, char * message)
{ fprintf(listing,"Type error at line %d: %s\n",t->lineno,message);
    Error = TRUE;
}

/* Procedure insertNode inserts 
 * identifiers stored in t into 
 * the symbol table 
 */
static void insertNode( TreeNode * t)
{ /* complete it */
 switch (t->nodekind)
  { case StmtK:
      switch (t->kind.stmt)
      { case CallK:
          if(strcmp(t->attr.name, "output") == 0){
              st_insert(t->attr.name,t->lineno, -1, 0 , t->isParameter);
              break;
          }

          if (st_lookup(t->attr.name, scope_a) == -1)
          /* not yet in table, so treat as new definition */
            st_insert(t->attr.name,t->lineno, -1, scope_a , t->isParameter);
          else
          /* already in table, so ignore location, 
             add line number of use only */ 
            st_insert(t->attr.name,t->lineno,-1, scope_a , t->isParameter);
          break;
        default:
          break;
      }
      break;
    case ExpK:
      switch (t->kind.exp)
      { case IdK:
          // check for t->attr.name in tree at 0 scope or current scope
          // else add at old scope value
          if (var_lookup(t->attr.name, scope_a) != NULL){
              st_insert(t->attr.name,t->lineno, No_change , scope_a, t->isParameter);
              break;
          } else if (var_lookup(t->attr.name, 0) != NULL) {
              st_insert(t->attr.name,t->lineno, No_change , 0, t->isParameter);
              break;
          }


          break;
        default:
          break;
      }
      break;
    case DecK:
      switch (t->kind.dec)
      { case VarK:

          if (var_lookup(t->attr.name, scope_a) == NULL){
          /* not yet in table, so treat as new definition */
          // location = numvars in scope
            st_insert(t->attr.name,t->lineno, location[scope_a], scope_a , t->isParameter);
            location[scope_a] = location[scope_a] + 1;
          }
          else
          /* already in table, so ignore location, 
             add line number of use only */

            st_insert(t->attr.name,t->lineno, No_change , scope_a, t->isParameter);
          break;
        case ArrayK:
          if (st_lookup(t->attr.name, scope_a) == -1) {
              /* not yet in table, so treat as new definition */

              st_insert(t->attr.name, t->lineno, location[scope_a], scope_a, t->isParameter);
              location[scope_a] = location[scope_a] + t->value;
          }
          else
          /* already in table, so ignore location, 
             add line number of use only */ 
            st_insert(t->attr.name,t->lineno, No_change , scope_a, t->isParameter);
          break;
        case FunK:
          if (fun_lookup(t->attr.name, 0) == NULL) {

              /* not yet in table, so treat as new definition */
              st_insert(t->attr.name, t->lineno, -1, 0, t->isParameter);
              location[num_scopes] = 0;
              //++num_scopes;
              //scope_a = num_scopes;
          }
          else
          /* already in table, so ignore location, 
             add line number of use only */
            st_insert(t->attr.name,t->lineno, No_change , scope_a, t->isParameter);
          break;
        default:
          break;
      }
      break;
    default:
      break;
  }
}

/* Function buildSymtab constructs the symbol 
 * table by preorder traversal of the syntax tree
 */
void buildSymtab(TreeNode * syntaxTree)
{ traverse(syntaxTree,insertNode,nullProc);
  if (TraceAnalyze)
  { fprintf(listing,"\nSymbol table:\n\n");
    printSymTab(listing);
  }
}



/* Procedure checkNode performs
 * type checking at a single tree node
 */
static void checkNode(TreeNode * t)
{ /* complete it */
 switch (t->nodekind)
  { case ExpK:
      switch (t->kind.exp)
      { case OpK:
          if ((t->child[0]->type != Integer) ||
              (t->child[1]->type != Integer))
            typeError(t,"Op applied to non-integer");
          if ((t->attr.op == LT) || (t->attr.op == LE) || (t->attr.op == GT) || (t->attr.op == GE) || (t->attr.op == EQ) || (t->attr.op == NQ))
            t->type = Boolean;
          else
            t->type = Integer;
          break;
        case AssignK:
          if (t->child[1]->type != Integer)
            typeError(t->child[0],"assignment of non-integer value");
          break;
        case ConstK:
        case IdK:
          t->type = Integer;
          break;
        default:
          break;
      }
      break;
    case StmtK:
      switch (t->kind.stmt)
      { case IfK:
          if (t->child[0]->type == Integer)
            typeError(t->child[0],"if test is not Boolean");
          break;
        case WhileK:
          if (t->child[0]->type == Integer)
            typeError(t->child[0],"while test is not Boolean");
          break;
        case CallK:
          if(t->child[0] == NULL){

          }
           else if (t->child[0]->type != Integer)
            typeError(t->child[0],"parameter is a non-integer value");
          break;
        case ReturnK:
          if (t->child[0]->type != Integer)
            typeError(t->child[0],"return value is a non-integer");
          break;
        default:
          break;
      }
      break;
    default:
      break;

  }

}

/* Procedure typeCheck performs type checking 
 * by a postorder syntax tree traversal
 */
void typeCheck(TreeNode * syntaxTree)
{ traverse(syntaxTree,nullProc,checkNode);
}
