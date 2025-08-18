#ifndef DEFS_H
#define DEFS_H

/*==============================================================================
|------------------------------------------------------------------------------|
|									       |
|				    DEFS.H				       |
|									       |
|------------------------------------------------------------------------------|
|									       |
| CONTENTS								       |
| --------								       |
| This header file contains basic preprocessor definitions (macros), typedef   |
| declarations, etc.							       |
|									       |
| AUTHOR								       |							       | ------								       |
| Todd H. Kermit, Space Sciences Laboratory, U.C. Berkeley		       |
|									       |	------------------------------------------------------------------------------*/

#include <sys/types.h>

#ifdef SOLARIS
#include <sunmath.h>
#endif

/* Typedef declarations
/* ~~~~~~~~~~~~~~~~~~~~ */

#ifndef SOLARIS
typedef int 		boolean_t;
#define B_TRUE          1
#define B_FALSE         0
#endif

typedef unsigned char 	uchar;
typedef unsigned short  uint2;
typedef unsigned int    uint4;

typedef char            schar;
typedef short		int2;
typedef int 		int4;

#ifndef _SYS_TYPES_H
typedef unsigned int  	uint;
typedef unsigned long   ulong;
#endif /* _SYS_TYPES_H */

typedef double           Align;          /* provides alignment restriction */
typedef float		data_t;

#define NaN		quiet_nan(0)

#ifdef IDL_STRING_SHORT
typedef struct {
	unsigned short length; 
	short reserved;
	char *s;
} IDL_STRING;
#else
typedef struct {
	int length;       
	short reserved;
	char *s;
} IDL_STRING;
#endif	



#endif /* DEFS_H  */
