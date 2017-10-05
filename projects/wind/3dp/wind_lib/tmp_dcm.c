#include "tmp_dcm.h"
#include "windmisc.h"

#include <math.h>

/* private functions: */

double  raw_to_temperature(uchar c);
double  resistance_to_temperature(double r);






/*  returns thermister resistance given raw value */
double raw_to_resistance(uchar c)
{
	return((double)c/255.*10.);

}



#define T0  79.7163
#define T1  -26.8341
#define T2  1.43978
#define T3  -.0445503
#define Rpar  10.

/* returns temperature given thermister resistance */
double  resistance_to_temperature(double r)
{
	double x,t;
	r = 1./( 1./r - 1./Rpar);
	x = log(r);
	t = ( (T3 *x + T2) *x + T1) *x + T0;
	return(t);
}



#if 1

/* returns temperature (from logrithmic fit) given raw byte */
/* This is more accurate than the polynomial fit */
double  raw_to_temperature(uchar c)
{
	double r,t;
	if(c==0)
		return(100.);
	r = raw_to_resistance(c);
	t = resistance_to_temperature(r);
	return(t);
}



#else



#define C0 153.7
#define C1 -3.9643
#define C2 .05863
#define C3 -.00045257
#define C4 .000001678
#define C5 -2.405e-9

/* returns temperature (from polynomial fit) given raw byte */
/* These should be the same coeffecients used by NASA  */
double  raw_to_temperature(uchar c)
{
	double x,t;
	x = c;
	t = ((((C5*x+C4)*x+C3)*x+C2)*x+C1)*x+C0;
	return(t);
}

#endif


/*  The following are designed for batch mode... */




#if 1
#define TMP_ID  KPD_ID
#define OFFSET MAX_KPDBYTES
#else
#define TMP_ID  HKP_ID
#define OFFSET MAX_HKPBYTES
#endif



int decom_temperature(packet *pk,instrum_temperature *temp)
{
	uchar *s;
	int offset;
	offset = OFFSET;
	s = pk->data + offset;
	temp->time = pk->time;
     /* the order of bytes may not be correct! */
	temp->eesa_raw   = s[0];
	temp->pesa_raw   = s[1];
	temp->sst1_2_raw = s[2];
	temp->sst3_raw   = s[3];
	temp->eesa   = raw_to_temperature(s[0]);
	temp->pesa   = raw_to_temperature(s[1]);
	temp->sst1_2 = raw_to_temperature(s[2]);
	temp->sst3   = raw_to_temperature(s[3]);
	return(1);
}




