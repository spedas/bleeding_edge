#ifndef EMOM_DCM_H
#define EMOM_DCM_H


#include "wind_pk.h"
#include "eesa_cfg.h"

#include <stdio.h>   /* for printing */

struct comp_eesa_mom_def {
	uint2 c0;                 /* 12 bits are used for the density */ 
	schar c1,c2,c3,c4,c5,c6;
	uchar c7,c8,c9;
	schar c10,c11,c12;
};
typedef struct comp_eesa_mom_def comp_eesa_mom;




struct eesa_mom_def {
	uint4 m0;    /* n  */
	 int4 m1;    /* n Vx  */
	 int4 m2;    /* n Vy  */
	 int4 m3;    /* n Vz  */
	 int4 m4;    /*  Pxy  */
	 int4 m5;    /*  Pyz  */
	 int4 m6;    /*  Pxz  */
	uint4 m7;    /*  Pxx  */
	uint4 m8;    /*  Pyy  */
	uint4 m9;    /*  Pzz  */
	 int4 m10;    /*  Qx  */
	 int4 m11;    /*  Qy  */
	 int4 m12;    /*  Qz  */ 
	uchar overflow;
};
typedef struct eesa_mom_def eesa_mom;



typedef struct distribution_def emomdata;



struct eesa_mom_data_def {
	double time;
	uint2  spin;
	int2    gap;
	int2    valid;
	comp_eesa_mom cmom;
	emomdata dist;
};
typedef struct eesa_mom_data_def eesa_mom_data;



typedef struct {
	int num_samples;
	double *time;
	float  *dens;
	float  *temp;
	float  *Vx;
	float  *Vy;
	float  *Vz;
	float  *Pe;
	float  *Qe;
} emom_fill_str;




/* decomutation routines */
int emom_decom(packet *pk,eesa_mom_data *Emom);
int calc_emom_param(eesa_mom_data *Emom,ECFG *cfg);

/* Gets next emom structure with a time greater than BUT NOT EQUAL to time */
/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_emom_struct(packet_selector *pks, eesa_mom_data Emom[16]);


/*  returns the number of electron moment samples between time t1 and t2  */
/*  Note:  there are 16 samples per packet  */
/*  If t2 is greater than the time of the last packet sample then the number */
/*  is estimated.   */
int number_of_emom_struct_samples(double t1,double t2);


/*  Takes structure of pointers to blank memory and fills it with data*/
int fill_emom_data(emom_fill_str ptr);


#endif
