#include "windmisc.h"

#include <stdlib.h>
#include <string.h>


double lt_sum_period = 3600.;   /* used for long term accumulations.  This is the
				 * period in seconds to accumulate over
				 */

FILE *debug;


/* standard routine to display error messages */
void err_out(char *s)
{
        debug = stdout; 
	if(debug){
		fputs(s,debug);  
		fputs("\n",debug);
	}
}


/* time_to_YMDHMS: returns a statically stored string that contains the time */
char *time_to_YMDHMS(double time)
{
	static char buff[25];
	time_t t;
	struct tm *ts;

	t = time;
	ts = gmtime(&t);
#if 1
	sprintf(buff,"%4d-%02d-%02d/%02d:%02d:%02d",ts->tm_year+1900,
	   ts->tm_mon+1,ts->tm_mday,ts->tm_hour,ts->tm_min,ts->tm_sec);
#else
	sprintf(buff,"%3d-%02d-%02d/%02d:%02d:%02d",ts->tm_year,ts->tm_mon+1,
		ts->tm_mday,ts->tm_hour,ts->tm_min,ts->tm_sec);
#endif
	return(buff);
}



/*************************************************************************** 
Returns absolute time given a character string.  The string should have the
format:   MON-DAY-YEAR/HOUR:MIN:SEC  
*****************************************************************************/
double MDYHMS_to_time(char *s)
{
	int n;
	static struct tm t;
	double secs;
	long tme;

	t.tm_isdst = 0;            /* assume no daylight savings time */
	secs = 0.;

	t.tm_hour = t.tm_min = t.tm_sec = 0;
	t.tm_mon = t.tm_mday = 1;
	n=sscanf(s,"%d-%d-%d/%d:%d:%lf",&t.tm_mon,&t.tm_mday,&t.tm_year,
		    &t.tm_hour,&t.tm_min,&secs);
	if(n==0)
		return(0.);
	if(t.tm_year > 1900)
		t.tm_year -= 1900;
	t.tm_mon  -= 1;
	t.tm_sec = secs;      /* integer portion of seconds */
	secs -= t.tm_sec;     /* fractional portion of seconds */
	tme = mkgmtime(&t);
	return((double) tme + secs);
}


double YMDHMS_to_time(char *s)
{
	int n;
	static struct tm t;
	double secs;
	long tme;

	t.tm_isdst = 0;            /* assume no daylight savings time */

	secs = 0.;
	t.tm_year = 90;   /*  1990 */
	t.tm_mon  = 1;
	t.tm_mday = 1;
	t.tm_hour = t.tm_min = t.tm_sec = 0;

	n=sscanf(s,"%d-%d-%d/%d:%d:%lf",&t.tm_year,&t.tm_mon,&t.tm_mday,
		    &t.tm_hour,&t.tm_min,&secs);
	if(t.tm_year > 1900)
		t.tm_year -= 1900;
	t.tm_mon  -= 1;
	t.tm_sec = secs;      /* integer portion of seconds */
	secs -= t.tm_sec;     /* fractional portion of seconds */
	tme = mkgmtime(&t);
	return((double) tme + secs);
}


/* warning! This may give wrong results if START_YEAR is a leap year */
#define START_YEAR 1970
#define isleap(y) (!((y) % 4) && ((y) % 100) || !((y) % 400) && ((y) % 4000))
#define nleap(y)  ((y)/4 - (y)/100 + (y)/400 - (y)/4000)

time_t mkgmtime(struct tm *t)
{
	time_t time;
	int year;
	static short  *ndays;
	static short ndays_n[12]={0,31,59,90,120,151,181,212,243,273,304,334};
	static short ndays_l[12]={0,31,60,91,121,152,182,213,244,274,305,335};
	
	while(t->tm_mon < 0){
		t->tm_mon += 12;
		t->tm_year -= 1;
	}
	while(t->tm_mon >= 12){
		t->tm_mon -= 12;
		t->tm_year += 1;
	}

	year = 1900 + t->tm_year;

	ndays = isleap(year) ? ndays_l : ndays_n;
	if(year >= START_YEAR){
		time = (year - START_YEAR) * 365;
		time +=  nleap(year-1) - nleap(START_YEAR-1);
		time += ndays[t->tm_mon] + t->tm_mday -1;
		time *= 24;
		time += t->tm_hour;
		time *= 60;
		time += t->tm_min;
		time *= 60;
		time += t->tm_sec;
	}
	else
		time = 0;
	*t = *gmtime(&time);   /* correct the t structure if nec. */
	return(time);
}


#define RECOMP 0


static uint4 decomp_table_8_19[256]
#if !RECOMP
={
     0,      1,      2,      3,      4,      5,      6,      7,
     8,      9,     10,     11,     12,     13,     14,     15,
    16,     17,     18,     19,     20,     21,     22,     23,
    24,     25,     26,     27,     28,     29,     30,     31,
    32,     34,     36,     38,     40,     42,     44,     46,
    48,     50,     52,     54,     56,     58,     60,     62,
    64,     68,     72,     76,     80,     84,     88,     92,
    96,    100,    104,    108,    112,    116,    120,    124,
   128,    136,    144,    152,    160,    168,    176,    184,
   192,    200,    208,    216,    224,    232,    240,    248,
   256,    272,    288,    304,    320,    336,    352,    368,
   384,    400,    416,    432,    448,    464,    480,    496,
   512,    544,    576,    608,    640,    672,    704,    736,
   768,    800,    832,    864,    896,    928,    960,    992,
  1024,   1088,   1152,   1216,   1280,   1344,   1408,   1472,
  1536,   1600,   1664,   1728,   1792,   1856,   1920,   1984,
  2048,   2176,   2304,   2432,   2560,   2688,   2816,   2944,
  3072,   3200,   3328,   3456,   3584,   3712,   3840,   3968,
  4096,   4352,   4608,   4864,   5120,   5376,   5632,   5888,
  6144,   6400,   6656,   6912,   7168,   7424,   7680,   7936,
  8192,   8704,   9216,   9728,  10240,  10752,  11264,  11776,
 12288,  12800,  13312,  13824,  14336,  14848,  15360,  15872,
 16384,  17408,  18432,  19456,  20480,  21504,  22528,  23552,
 24576,  25600,  26624,  27648,  28672,  29696,  30720,  31744,
 32768,  34816,  36864,  38912,  40960,  43008,  45056,  47104,
 49152,  51200,  53248,  55296,  57344,  59392,  61440,  63488,
 65536,  69632,  73728,  77824,  81920,  86016,  90112,  94208,
 98304, 102400, 106496, 110592, 114688, 118784, 122880, 126976,
131072, 139264, 147456, 155648, 163840, 172032, 180224, 188416,
196608, 204800, 212992, 221184, 229376, 237568, 245760, 253952,
262144, 278528, 294912, 311296, 327680, 344064, 360448, 376832,
393216, 409600, 425984, 442368, 458752, 475136, 491520, 507904,
}
#endif
;

void  init_decomp19_8()
{
	int c;
	for(c=0;c<256;c++)
		decomp_table_8_19[c] = decompress( c, 4);
#if RECOMP
	FILE *fp;
	fp = nfile("decomp19_8");
	for(c=0;c<256;c++)
		fprintf(fp,"%6d,%c",decomp_table_8_19[c],(c%8)==7 ? '\n' : ' ');
	fclose(fp);	
#endif
}



#define RECOMP_12 0


static uint2 decomp_table_8_12[256]
#if !RECOMP_12
={
     0,      1,      2,      3,      4,      5,      6,      7,
     8,      9,     10,     11,     12,     13,     14,     15,
    16,     17,     18,     19,     20,     21,     22,     23,
    24,     25,     26,     27,     28,     29,     30,     31,
    32,     33,     34,     35,     36,     37,     38,     39,
    40,     41,     42,     43,     44,     45,     46,     47,
    48,     49,     50,     51,     52,     53,     54,     55,
    56,     57,     58,     59,     60,     61,     62,     63,
    64,     66,     68,     70,     72,     74,     76,     78,
    80,     82,     84,     86,     88,     90,     92,     94,
    96,     98,    100,    102,    104,    106,    108,    110,
   112,    114,    116,    118,    120,    122,    124,    126,
   128,    132,    136,    140,    144,    148,    152,    156,
   160,    164,    168,    172,    176,    180,    184,    188,
   192,    196,    200,    204,    208,    212,    216,    220,
   224,    228,    232,    236,    240,    244,    248,    252,
   256,    264,    272,    280,    288,    296,    304,    312,
   320,    328,    336,    344,    352,    360,    368,    376,
   384,    392,    400,    408,    416,    424,    432,    440,
   448,    456,    464,    472,    480,    488,    496,    504,
   512,    528,    544,    560,    576,    592,    608,    624,
   640,    656,    672,    688,    704,    720,    736,    752,
   768,    784,    800,    816,    832,    848,    864,    880,
   896,    912,    928,    944,    960,    976,    992,   1008,
  1024,   1056,   1088,   1120,   1152,   1184,   1216,   1248,
  1280,   1312,   1344,   1376,   1408,   1440,   1472,   1504,
  1536,   1568,   1600,   1632,   1664,   1696,   1728,   1760,
  1792,   1824,   1856,   1888,   1920,   1952,   1984,   2016,
  2048,   2112,   2176,   2240,   2304,   2368,   2432,   2496,
  2560,   2624,   2688,   2752,   2816,   2880,   2944,   3008,
  3072,   3136,   3200,   3264,   3328,   3392,   3456,   3520,
  3584,   3648,   3712,   3776,   3840,   3904,   3968,   4032,
}
#endif
;

void  init_decomp12_8()
{
	int c;
	for(c=0;c<256;c++)
		decomp_table_8_12[c] = decompress( c, 5);
#if RECOMP_12
	FILE *fp;
	fp = fopen("decomp12_8","w");
	for(c=0;c<256;c++)
		fprintf(fp,"%6d,%c",decomp_table_8_12[c],(c%8)==7 ? '\n' : ' ');
	fclose(fp);	
#endif
}


uint4 decomp19_8(uint2 cx)   /* 8 bit to 19 bit decompression */
{            
	return( decomp_table_8_19[cx & 0xff] );
}

#if 1
uint decomp12(uchar c)
{
	return( decomp_table_8_12[c] );
}
#else

uint decomp12(uchar c)
{
	return( c );
}

#endif 

#if 1
int signdecomp12(uchar u)  /* 8 bit to 12 bit signed decompression */
{
	schar s;
	s = (schar)u;
	if(s < 0)
		return(- (int)( decomp12( -s * 2 ) /2)); 
	else
		return( decomp12( s * 2) /2 );
}
#else
int signdecomp12(uchar s)  /* 8 bit to 12 bit signed decompression */
{
	return((int)((schar)s));  /* not written yet */
}
#endif


int2 str_to_int2(uchar *u)
/* converts byte stream from byte reversed machines to 2 byte integer */
{
	int2 i;
	i = ( (char) u[1] )*256 + u[0];
	return(i);
}

uint2 str_to_uint2(uchar *u)
/* converts byte stream from byte reversed machines to 2 byte unsigned integer*/
{
	uint2 ui;
	ui = u[1]*256 + u[0];
	return(ui);
}



int4 str_to_int4(uchar *u)
/* converts byte stream from byte reversed machines to 4 byte integer */
{
	return( (((u[3]*256)+u[2])*256+u[1])*256+u[0] );
}




/* standard decompression for compressed cx with m bit mantissa (hidden bit assumed) */
uint4 decompress(uint2 cx,uint2 m)
{             
	uint2 e,mask;
	uint4 result;
	mask = 0xffff << m; 
	e = cx >> m;
	result = cx & (~mask);
	if(e) result += (1 << m);
	if(e>1)  result <<= (e-1);
	return( result );
}


#define B31 0x8000  /* or (1l<<31) */
uint2 comp19_8(uint4 l)
/* compress 19 bit to 8 bit  */
{              
	int i;
	uint2 m,e;
	if(l<=32) return((uint2)l);
	if(l >= 507904) return(255); 
	l <<= 13;
	for(e=15;!(l & B31);l<<=1,e--)
		;
	l <<= 1;
	m = l>>16;
	m >>= 12;
	e <<= 4;
	return(m+e);
}



/* returns a string representing the bit patern of an unsigned 4 byte integer */
char *bit_pattern(int4 u,char *on_flags,char *off_flags)
{
	static char buff[32+12];
	int n,nbits;
	uint4 mask;

	nbits = strlen(on_flags);

	if(nbits > 32)
		nbits = 32;
	n = 0;
	mask = 1<<(nbits-1);
	while(nbits > 0){
		buff[n++] = (mask & u) ? *on_flags : *off_flags;
		on_flags++;
		off_flags++;
		mask >>= 1;
		nbits--;
	}
	buff[n] = 0;
	return(buff);
}



char *bit_pattern_o(int4 u,char *on_flags)
{
	return(	bit_pattern(u,on_flags,"                                "));
}



int print_data_changes(FILE *fp,uchar data[],uchar lastdata[],int size)
{
	int c,i;
	uint num_changes=0;

	if(fp==0)
		return(0);

	fprintf(fp,"    ");
	for(i=0;i<16;i++)
		fprintf(fp," %2x ",i);
	for(i=0;i<size;i++){
		if(i%16==0)
			fprintf(fp,"\n %2x ",i/16);
		if(data[i] != lastdata[i]){
			c = '*';
			num_changes++;
		}
		else{
/*			lastdata[i] = data[i]; */
			c = ' ';
		}
		fprintf(fp," %02x%c",data[i],c);
	}
	fprintf(fp,"\n");
	return(num_changes);
}











/* following are temporary routines designed for program development */



#if 0

#include <string.h>
static struct filelistdef {
	FILE *fp;
	char filename[26];
	struct filelistdef *nextfile;
};


FILE *nfile(char *s)
{
	static struct filelistdef *firstfile;
	struct filelistdef *file;
	char buff[200];
	sprintf(buff,"%s%s",output_directory,s);  /* prepend directory name */
	s = buff;

	file = firstfile;
	while(file){
		if(strcmp(s,file->filename)==0) return(file->fp);
		file = file->nextfile;
	}
	  /* file not found, open it; */
	file = (struct filelistdef *) malloc(sizeof(struct filelistdef));
	if(file==0){
		fprintf(stderr,"Can't get memory for file server\n");
		return(stderr);
	}
	file->fp = fopen(s,"w");
	if(file->fp == 0){
		fprintf(stderr,"Can't open file '%s'.  Routing through stdout\n",s);
		file->fp=stdout;
	}
	else
		fprintf(stderr,"Opening output file '%s'.\n",s);
	strncpy(file->filename,s,25);
	file->nextfile = firstfile;
	firstfile = file;
	return(file->fp);
}

#endif


#if 0
int mem_check(int i)
{
	static char *mem;
	
	if(i==0){
		mem = (char*)malloc(20);
		if(mem==0){
			fprintf(stderr,"Cannot allocate memory for check\n");
			return(0);
		}
		for(i=0;i<20;i++)
			mem[i] = 3*i+5;
		return(1);
	}

	if(i==1 && mem){
		for(i=0;i<20;i++){
			if(mem[i] != 3*i+5){
				fprintf(stderr,"Memory overwritten.  Hit 'esc'.\n");
#ifdef MSDOS
				while(getkey()!=27)
					;
#endif
				return(0);
			}
		}
		return(1);
	}
		

	if(i==2 && mem){
		free(mem);
		mem = 0;
		return(i);
	}
	return(0);
}
#endif
	
