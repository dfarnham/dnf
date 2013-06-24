/*
 * INITIALIZE is to be defined only once
 */
#ifdef INITIALIZE
#define EXTERN
#else
#define EXTERN extern
#endif


/*
 * A buffer for IDENT names (dyamically allocated and resized if needed)
 */
#define BUFSIZE 32

struct _Buffer {
	char *buf;
	int len;
};

EXTERN struct _Buffer Ident;
