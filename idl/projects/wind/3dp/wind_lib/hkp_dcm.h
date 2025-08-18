#ifndef HKP_DCM_H
#define HKP_DCM_H

#include "wind_pk.h"




									      /*
Typedefs
~~~~~~~~								      */

typedef struct hkp_def 
    {
    double time;
    uint  errors;
    uchar inst_mode;			/* instrument mode (bit-coded) */ 
    uchar mode;				/* manuever/science mode stat */
    uchar burst_stat;			/* burst readout status       */
    uchar rate;				/* 2X mode (values 1 or 2)    */
    uchar frame_seq;  		        /* frame counter              */
    uint2  offset;     			/* offset to first data byte  */
    uint2  spin;
    uchar phase;
    uchar magel;
    uint2  magaz;
    uchar num_commands;
    uchar lastcmd[12];      	/* not plot-able */
    uchar main_version;
    uchar main_status;      	/* bit-coded */
    uchar main_last_error;      
    uchar main_num_errors;
    uchar main_num_resets;
    uchar main_burst_stat;	/* bit-coded */
    float fspin;
    float main_p5;
    float main_m5;
    float main_p12;
    float main_m12;
    float sst_p9;
    float sst_p5;
    float sst_m4;
    float sst_m9;
    float sst_hv;
    uchar eesa_version;
    uchar eesa_status;      	/* bit-coded */
    uchar eesa_last_error;      
    uchar eesa_num_errors;
    uchar eesa_num_resets;
    uchar eesa_burst_stat;	/* bit-coded */
    uchar eesa_swp; /* 0: eesa_swpl is valid;  1: eesa_swph is valid */
    float eesa_p5;
    float eesa_p12;
    float eesa_m12;
    float eesa_mcpl;
    float eesa_mcph;
    float eesa_pmt;
    float eesa_swpl;      /* altered only if ->eesa_swp ==0 */
    float eesa_swph;      /* altered only if ->eesa_swp ==1 */
    uchar pesa_version;
    uchar pesa_status;
    uchar pesa_last_error;      
    uchar pesa_num_errors;
    uchar pesa_num_resets;
    uchar pesa_burst_stat;	/* bit-coded */
    uchar pesa_swp; /* 0: pesa_swpl is valid;  1: pesa_swph is valid */
    float pesa_p5;
    float pesa_p12;
    float pesa_m12;
    float pesa_mcpl;
    float pesa_mcph;
    float pesa_pmt;
    float pesa_swpl;      /* altered only if ->pesa_swp ==0 */
    float pesa_swph;      /* altered only if ->pesa_swp ==1 */

	/* temperature data */
    float eesa_temp;
    float pesa_temp;
    float sst1_temp;
    float sst3_temp;
    int   valid;        /* set to 1 if data is valid  */

    } hkpPktStruct;



typedef struct {
	int num_samples;
	double *time;
	float  *magel;
	float  *magaz;
	float  *eesa_temp;
	float  *pesa_temp;
	float  *sst1_temp;
	float  *sst3_temp;
	float  *eesa_mcpl;
	float  *eesa_mcph;
	float  *pesa_mcpl;
	float  *pesa_mcph;
	float  *eesa_pmt;
	float  *pesa_pmt;
	float  *eesa_swp;
	float  *pesa_swp;
} hkp_fill_str;




/* function prototypes */

int number_of_hkp_samples(double t1,double t2);
/*  returns the number of hkpPktStruct 's between time t1 and t2  */
/*  If t2 is greater than the time of the last packet sample then the number */
/*  is estimated.   */

int get_next_hkp_struct(packet_selector *pks, hkpPktStruct *hkp);
/* Gets the next hkpPktStruct with a time greater than BUT NOT EQUAL to time */
/* *hkp remains unchanged if unsuccesful  */
/* returns 0 if unsuccessful */
/* returns 1 if successful */



int fill_hkp_data(hkp_fill_str ptr);
/*takes structure with pointers to empty data buffers and fills them with data*/



/* Miscellaneous  */

int  fill_hkp_struct(packet *pk,hkpPktStruct *hkp);

char *inst_mode_str(uchar inst_mode);


#endif
