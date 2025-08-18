
#include "wind_pk.h"
#include "windmisc.h"

#include <stdio.h>


typedef struct  {
    double time;
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
} pAtoD_struct;



/* function prototypes */

int number_of_pAtoD_samples(double t1,double t2);
/*  returns the number of pAtoD 's between time t1 and t2  */
/*  If t2 is greater than the time of the last packet sample then the number */
/*  is estimated.   */

int get_next_pAtoD_struct(packet_selector *pks, pAtoD_struct *pAtoD);
/* Gets the next pAtoD with a time greater than BUT NOT EQUAL to time */
/* *hkp remains unchanged if unsuccesful  */
/* returns 0 if unsuccessful */
/* returns 1 if successful */


/* Miscellaneous  */

extern FILE *pAtoD_fp;

int  fill_pAtoD_struct(packet *pk,pAtoD_struct *pAtoD);
int print_pAtoD_packet(packet *pk);
int print_pAtoD_struct(FILE *fp,  pAtoD_struct *pAtoD);
