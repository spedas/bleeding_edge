#include "wind_pk.h"


double  raw_to_temperature(uchar c);
double  resistance_to_temperature(double r);
/*  These must match the values in filter.c */
#define MAX_KPDBYTES   33
#define MAX_HKPBYTES   54
#define MAX_THMBYTES   4


typedef struct  {
	double time;
	float  eesa;
	float  pesa;
	float  sst1_2;
	float  sst3;
	uchar  eesa_raw;
	uchar  pesa_raw;
	uchar  sst1_2_raw;
	uchar  sst3_raw;
} instrum_temperature;



int decom_temperature(packet *pk,instrum_temperature *temp);

int print_tmp_packet(packet *pk);
