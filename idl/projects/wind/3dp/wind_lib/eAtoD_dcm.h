#ifndef EATOD_DCM_H
#define EATOD_DCM_H


#include "wind_pk.h"
#include "windmisc.h"

#include <stdio.h>


/* This structure must match the structure in get_eatod.pro  */
typedef struct  {
    double time;
    uint2  spin;
    float  MCP_low;
    float  waves;
    float  MCP_high;
    float  PMT;
    float  sweep_low;
    float  sweep_high;
    float  def_up;
    float  def_down;
    float  tp_0;
    float  tp_1;
    float  ref_plus;
    float  gnd_adc;
    float  ref_minus;
    float  eesa_p5;
    float  boom_p5;
    float  eesa_m5;
    float  cover;
    float  eesa_p12;
    float  boom_p12;
    float  eesa_m12;
    float  boom_m12;
    float  eesa_ref;
    float  gnd_eesa;
    int2   valid;
} eAtoD_struct;



#if 0  /* OBSOLETE  */
typedef struct {
	int num_samples;
	double *time;
	float  *MCP_low;
	float  *MCP_high;
	float  *waves;
	float  *sweep_low;
	float  *sweep_high;
	float  *def_up;
	float  *def_down;
	float  *PMT;
} eAtoD_fill_str;

int fill_eAtoD_data(eAtoD_fill_str ptr);
/*takes structure with pointers to empty data buffers and fills them with data*/

#endif



/* function prototypes */

int number_of_eAtoD_samples(double t1,double t2);
/*  returns the number of eAtoD 's between time t1 and t2  */
/*  If t2 is greater than the time of the last packet sample then the number */
/*  is estimated.   */

int get_next_eAtoD_struct(packet_selector * pks, eAtoD_struct *eAtoD);
/* Gets the next eAtoD with a time greater than BUT NOT EQUAL to time */
/* *hkp remains unchanged if unsuccesful  */
/* returns 0 if unsuccessful */
/* returns 1 if successful */



/* Miscellaneous  */

extern FILE *eAtoD_fp;

int  fill_eAtoD_struct(packet *pk,eAtoD_struct *eAtoD);
int print_eAtoD_packet(packet *pk);
int print_eAtoD_struct(FILE *fp,  eAtoD_struct *eAtoD);

#endif
