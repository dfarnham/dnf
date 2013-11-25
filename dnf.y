%{
/*
 * dnf.y
 * Dave Farnham -- initial
 * Fri Jun 21 21:36:05 MDT 2013
 *
 * Based on the white paper:
 *   "KeyNote Policy Files and Conversion to Disjunctive Normal Form for Use in IPsec"
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tree.h"

#define INITIALIZE   /* Define this only here */
#include "const.h"

extern int      yylex                   (void);

void            yyerror                 (char *);
void            ncopy                   (struct node *, struct node *);
void            free_node               (struct node *);
void            free_tree               (struct node *);
struct node *   nalloc                  (void);
struct node *   add_leaf                (int, char *);
struct node *   add_node                (int, struct node *, struct node *);
void            extract_DNF_tree        (struct node *);
void            permeate_nots           (struct node *);
void            apply_double_negation   (struct node *);
void            apply_DeMorgan          (struct node *, int);
void            inverse_operators       (struct node *);
void            distribute_DNF          (struct node *);
int             and_distribute          (struct node *);
void            distribute_branches     (struct node *);
struct node *   copy_tree               (struct node *);
int             binary_node             (struct node *);
void            print_tree              (struct node *);
int             main                    (int, char *[]);

%}
%union {
    struct node * np;
};
%type <np> expr

/*
 * Tokens provided by the scanner
 */
%token OR AND EQ NE LT LE GT GE NOT IDENT

/*
 * Associativity and precedence (low to high)
 */
%left OR
%left AND
%left EQ NE
%left LT LE GT GE
%left NOT

/*
 * The starting rule
 */
%start input

%%
input:
        | input '\n'        { printf("> ");                         }
        | input expr '\n'   { extract_DNF_tree($2);
                              print_tree($2);
                              free_tree($2);
                              printf("\n> ");                       }
        ;
expr:     IDENT             { $$ = add_leaf(IDENT_TYPE, Ident.buf); }
        | expr AND expr     { $$ = add_node(AND_TYPE, $1, $3);      }
        | expr OR expr      { $$ = add_node(OR_TYPE, $1, $3);       }
        | expr LT expr      { $$ = add_node(LT_TYPE, $1, $3);       }
        | expr LE expr      { $$ = add_node(LE_TYPE, $1, $3);       }
        | expr GT expr      { $$ = add_node(GT_TYPE, $1, $3);       }
        | expr GE expr      { $$ = add_node(GE_TYPE, $1, $3);       }
        | expr EQ expr      { $$ = add_node(EQ_TYPE, $1, $3);       }
        | expr NE expr      { $$ = add_node(NE_TYPE, $1, $3);       }
        | NOT expr          { $$ = add_node(NOT_TYPE, $2, NNULL);   }
        | '(' expr ')'      { $$ = $2;                              }
        ;
%%
/* ----end of grammar----*/



static char *progname;      /* for error messages */

/**************************************************
 * yyerror:
 * Output error string to stderr and exit
 **************************************************/
void
yyerror(char *s) {
    fprintf (stderr, "%s: %s\n", progname, s);
    exit(1);
}

/**************************************************
 * ncopy:
 * Copy node "from" to node "to"
 **************************************************/
void
ncopy(struct node *from, struct node *to) {
    to->type = from->type;
    if (to->value) {      // we're overwriting an existing node
        free(to->value);  // reclaim resources
    }
    to->value = (from->value) ? strdup(from->value) : (char *)NULL;
    to->left = from->left;
    to->right = from->right;
}

/**************************************************
 * free_node:
 * Free a node
 **************************************************/
void
free_node(struct node *np) {
    if (np != NNULL) {
        if (np->value) {
            free(np->value);
        }
        free(np);
    }
}

/**************************************************
 * free_tree:
 * free the tree
 **************************************************/
void
free_tree(struct node *tree) {
    if (tree != NNULL) {
        free_tree(LCHILD(tree));
        free_tree(RCHILD(tree));
        free_node(tree);
    }
}

/**************************************************
 * nalloc:
 * Allocate memory for a node and return it
 **************************************************/
struct node *
nalloc(void) {
    struct node *np;
    if (!(np = (struct node *) malloc(sizeof(struct node)))) {
        yyerror("nalloc: Out of Memory\n");
    }
    np->type = NULL_TYPE;
    np->value = (char *)NULL;
    LCHILD(np) = RCHILD(np) = NNULL;
    return np;
}

/**************************************************
 * add_leaf:
 * Generates a leaf (a node with value filled)
 **************************************************/
struct node *
add_leaf(int type, char *value) {
    struct node *np = nalloc();
    np->type = type;
    np->value = strdup(value);
    LCHILD(np) = RCHILD(np) = NNULL;
    return np;
}

/**************************************************
 * add_node:
 * Generates a node with an operator type
 * type - type of operator:
 *   AND, OR, NOT, LT, LE, GT, GE, EQ, NE
 * left - pointer to the left child
 * right - pointer to the right child
 **************************************************/
struct node *
add_node(int type, struct node *left, struct node *right) {
    struct node *np = nalloc();
    np->type = type;
    LCHILD(np) = left;
    RCHILD(np) = right;
    return np;
}

/**************************************************
 * extract_DNF_tree:
 * Converts tree to DNF form
 **************************************************/
void
extract_DNF_tree(struct node *root) {
    permeate_nots(root);
    distribute_DNF(root);
}

/**************************************************
 * permeate_nots:
 * Converts expressions of type:
 *   NOT (x AND y) -> (NOT x) OR (NOT y)
 *   NOT (x OR y)  -> (NOT x) AND (NOT y)
 **************************************************/
void
permeate_nots(struct node *snode) {
    if (snode == NNULL) {
        return;
    }

    // if root node type is a NOT
    if (snode->type == NOT_TYPE && LCHILD(snode) != NNULL) {
        // if left child type is a NOT
        if (LCHILD(snode)->type == NOT_TYPE) {
            // remove the two NOTs and permeate
            apply_double_negation(snode);
            permeate_nots(snode);
        } else if (LCHILD(snode)->type == AND_TYPE || LCHILD(snode)->type == OR_TYPE) {
            apply_DeMorgan(snode, LCHILD(snode)->type);
        } else {
            // the node's type is relational
            inverse_operators(snode);
        }
    }

    if (!ISLEAF(snode)) {
        permeate_nots(LCHILD(snode));
        permeate_nots(RCHILD(snode));
    }
}

/**************************************************
 * apply_double_negation:
 * Converts expression of type:
 *   NOT (NOT x) -> x
 **************************************************/
void
apply_double_negation(struct node *snode) {
    struct node *child, *grand_child;
    child = LCHILD(snode);
    grand_child = LCHILD(child);
    ncopy(grand_child, snode);
    free_node(child);
    free_node(grand_child);
}

/**************************************************
 * apply_DeMorgan:
 * Converts expression for AND_TYPE:
 *   NOT (x AND y) -> (NOT x) OR (NOT y)
 *
 * Converts expression for OR_TYPE:
 *   NOT (x OR y) -> (NOT x) AND (NOT y)
 **************************************************/
void
apply_DeMorgan(struct node *snode, int type) {
    struct node *child, *grand_child1, *grand_child2, *new_child;
    child = LCHILD(snode);
    grand_child1 = LCHILD(child);
    grand_child2 = RCHILD(child);
    snode->type = (type == AND_TYPE) ? OR_TYPE : AND_TYPE;
    child->type = NOT_TYPE;
    RCHILD(child) = NNULL;
    new_child = add_node(NOT_TYPE, grand_child2, NNULL);
    RCHILD(snode) = new_child;
}

/**************************************************
 * inverse_operators:
 * Converts expressions:
 *   NOT (x RELATIONAL_OPERATOR y) -> x INVERSE_RELATIONAL_OPERATOR y
 **************************************************/
void
inverse_operators(struct node *snode) {
    struct node *child = LCHILD(snode);
    int relational = 0;

    if (child->type == EQ_TYPE) {
        child->type = NE_TYPE;
        relational = 1;
    } else if (child->type == NE_TYPE) {
        child->type = EQ_TYPE;
        relational = 1;
    } else if (child->type == LT_TYPE) {
        child->type = GE_TYPE;
        relational = 1;
    } else if (child->type == GT_TYPE) {
        child->type = LE_TYPE;
        relational = 1;
    } else if (child->type == LE_TYPE) {
        child->type = GT_TYPE;
        relational = 1;
    } else if (child->type == GE_TYPE) {
        child->type = LT_TYPE;
        relational = 1;
    }

    if (relational) {
        ncopy(child, snode);
        free(child);
    }
}

/**************************************************
 * distribute_DNF:
 * Applies distributive law to tree
 **************************************************/
void
distribute_DNF(struct node *snode) {
    int distribution = 0;
    do {
        distribution = and_distribute(snode);
    } while (distribution);
}

/**************************************************
 * and_distribute:
 * Converts recursively expressions of type:
 *   (x OR y) AND z to -> (x AND z) OR (y AND z)
 *
 * returns 1 if distributive law was applied or if
 * there was a change to the tree, 0 otherwise
 **************************************************/
int
and_distribute(struct node *snode) {
    int left, right;
    if (snode == NNULL) {
        return 0;
    }

    if (snode->type == AND_TYPE) {
        // if right child's type is an OR, swap positions of left and right child
        // expressions like: x AND (y OR z) become (y OR z) AND x
        // don't bother swapping if left child is an OR as that will happen next
        if (RCHILD(snode)->type == OR_TYPE && LCHILD(snode)->type != OR_TYPE) {
            struct node *temp = nalloc();
            ncopy(RCHILD(snode), temp);
            ncopy(LCHILD(snode), RCHILD(snode));
            ncopy(temp, LCHILD(snode));
            free_node(temp);
        }

        // if left child is an OR (possibly from above swap)
        // convert: (y OR z) AND x -> (y AND x) OR (z AND x)
        if (LCHILD(snode)->type == OR_TYPE) {
            distribute_branches(snode);
            and_distribute(snode);
            return 1;
        } else {
            left = right = 0;

            // if left child is not a leaf, apply distributive law to it
            if (!ISLEAF(LCHILD(snode))) {
                left = and_distribute(LCHILD(snode));
            }
            // if right child is not a leaf, apply distributive law to it
            if (!ISLEAF(RCHILD(snode))) {
                right = and_distribute(RCHILD(snode));
            }
            return (left || right);
        }
    } else {
        // if node is already an OR apply distributive law to its children
        if (snode->type == OR_TYPE) {
            left = and_distribute(LCHILD(snode));
            right = and_distribute(RCHILD(snode));
            return (left || right);
        }
        return 0;
    }
}

/**************************************************
 * distribute_branches:
 * Converts an expression of type:
 *   (x OR y) AND z -> (x AND z) OR (y AND z)
 **************************************************/
void
distribute_branches(struct node *snode) {
    struct node *rchild, *cp_rchild, *gchild1, *gchild2;
    rchild = RCHILD(snode);
    cp_rchild = copy_tree(rchild);
    gchild1 = LCHILD(LCHILD(snode));
    gchild2 = RCHILD(LCHILD(snode));
    snode->type = OR_TYPE;
    LCHILD(snode)->type = AND_TYPE;
    RCHILD(snode) = add_node(AND_TYPE, gchild2, rchild);
    RCHILD(LCHILD(snode)) = cp_rchild;
}

/**************************************************
 * copy_tree:
 * Generates a copy of a tree
 **************************************************/
struct node *
copy_tree(struct node *snode) {
    struct node *ctree;
    if (snode == NNULL) {
        return NNULL;
    }

    // copy root node
    ctree = nalloc();
    ncopy(snode, ctree);

    // copy left child
    LCHILD(ctree) = copy_tree(LCHILD(snode));

    // copy right child
    RCHILD(ctree) = copy_tree(RCHILD(snode));
    return ctree;
}

/**************************************************
 * binary_node:
 * Return 1 if node has two operands, 0 otherwise
 **************************************************/
int
binary_node(struct node *snode) {
    return (snode->type == AND_TYPE || snode->type == OR_TYPE ||
            snode->type == LT_TYPE  || snode->type == LE_TYPE ||
            snode->type == GT_TYPE  || snode->type == GE_TYPE ||
            snode->type == EQ_TYPE  || snode->type == NE_TYPE);
}

/**************************************************
 * print_tree:
 * Output tree to stdout
 **************************************************/
void
print_tree(struct node *snode) {
    if (snode == NNULL) {
        return;
    }

    if (ISLEAF(snode)) {                  // leaf node
        printf("%s",snode->value);
    } else if (binary_node(snode)) {      // node with two children
        printf("(");

        // print left child
        print_tree(LCHILD(snode));

        // print operator
        switch(snode->type) {
            case AND_TYPE:
                printf(" %s ", AND_STR); break;
            case OR_TYPE:
                printf(" %s ", OR_STR); break;
            case NOT_TYPE:
                printf(" %s ", NOT_STR); break;
            case LT_TYPE:
                printf(" %s ", LT_STR); break;
            case LE_TYPE:
                printf(" %s ", LE_STR); break;
            case GT_TYPE:
                printf(" %s ", GT_STR); break;
            case GE_TYPE:
                printf(" %s ", GE_STR); break;
            case EQ_TYPE:
                printf(" %s ", EQ_STR); break;
            case NE_TYPE:
                printf(" %s ", NE_STR); break;
        }

        // print right child
        print_tree(RCHILD(snode));

        printf(")");
    } else if (snode->type == NOT_TYPE) { // node with one child
        printf("(");

        // print operator
        printf("%s", NOT_STR);

        // print left child
        print_tree(LCHILD(snode));

        printf(")");
    }
}

/**************************************************
 * main:
 * Read expression from stdin (line at a time)
 * and output DNF form
 **************************************************/
int
main(int argc, char *argv[]) {
    progname = argv[0];
    printf ("dnf: Quit with ^D\n");
    printf ("> ");
    yyparse();
    free(Ident.buf);
    exit(0);
}
