#ifndef __TREE_H__
#define __TREE_H__
/**************************************************************************
* node
* There can be two types of nodes: intermediate and leaf/terminal nodes
* An intermediate node uses:
* type, which can be: a logical or relational operator
* left, which contains:
* pointer to left child node
* and may also use (if the operator is binary)
* right, which contains: 
* pointer to right child node
* (Fields not mentioned are empty/ignored)
*
* A leaf node has:
* type, which can be: IDENT_TYPE
* value actual string value of the identifier
***************************************************************************/

#define NULL_TYPE  0

#define AND_TYPE   1
#define AND_STR   "&&"

#define OR_TYPE    2
#define OR_STR    "||"

#define NOT_TYPE   3
#define NOT_STR   "!"

#define LT_TYPE    4
#define LT_STR    "<"

#define LE_TYPE    5
#define LE_STR    "<="

#define GT_TYPE    6
#define GT_STR    ">"

#define GE_TYPE    7
#define GE_STR    ">="

#define EQ_TYPE    8
#define EQ_STR    "=="

#define NE_TYPE    9
#define NE_STR    "!="

#define IDENT_TYPE 10

struct node {
    int type;
    char *value;
    struct node *left;
    struct node *right;
};

#define LCHILD(snode) ((snode)->left)
#define RCHILD(snode) ((snode)->right)
#define ISLEAF(snode) ((snode)->type == IDENT_TYPE)
#define NNULL ((struct node *) 0)
#endif /* __TREE_H__ */
