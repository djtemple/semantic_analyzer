/****************************************************/
/* File: analyze.h                                  */
/* Semantic analyzer interface for C- compiler      */
/* C- Compiler Project				                */
/*        	                                        */
/****************************************************/
#ifndef _ANALYZE_H_
#define _ANALYZE_H_

/* Function buildSymtab constructs the symbol 
 * table by preorder traversal of the syntax tree
 */
void buildSymtab(TreeNode *);

extern int scope_a;
extern int num_scopes;


/* Procedure typeCheck performs type checking 
 * by a postorder syntax tree traversal
 */
void typeCheck(TreeNode *);

#endif
