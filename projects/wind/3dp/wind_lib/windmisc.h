/*   Miscellaneous routines   */

#include "defs.h"


#include <time.h>
#include <stdio.h>

char *time_to_YMDHMS(double time);
double MDYHMS_to_time(char *s);
double YMDHMS_to_time(char *s);


char *bit_pattern_o(int4 u,char *flags);
char *bit_pattern(int4 u,char *on_flags,char *off_flags);

int print_data_changes(FILE *fp,uchar data[],uchar lastdata[],int size);



time_t mkgmtime(struct tm *t);

uint4 decomp19_8(uint2 cx);   /* 8 bit to 19 bit decompression */

int signdecomp12(uchar s);  /* 8 bit to 12 bit signed decompression */
uint decomp12(uchar s);       /* 8 bit to 12 bit decompression */

int2 str_to_int2(uchar *u);
uint2 str_to_uint2(uchar *u);
int4 str_to_int4(uchar *u);

uint4 decompress(uint2 cx,uint2 m);

void init_decomp19_8();
void init_decomp12_8();

uint2 comp19_8(uint4 l);
/* compress 19 bit to 8 bit  */

void err_out(char *s);
FILE *nfile(char *s);
int mem_check(int i);

extern  FILE *debug;
extern  char *output_directory;
