#ifndef PMOM_DCM_H
#define PMOM_DCM_H


#include "pesa_cfg.h"
#include "wind_pk.h"

#include <stdio.h>

typedef struct distribution_def pmomdata;


struct pesa_mom_def {
	uint4 m0;    /* n * Vx  */
	uint4 m1;    /*  Vx     */
	 int4 m2;    /*  Vy     */
	 int4 m3;    /*  Vz     */
	 int4 m4;    /*  Pxy/n  */
	 int4 m5;    /*  Pyz/n  */
	 int4 m6;    /*  Pxz/n  */
	uint4 m7;    /*  Pxx/n  */
	uint4 m8;    /*  Pyy/n  */
	uint4 m9;    /*  Pzz/n  */
};
typedef struct pesa_mom_def pesa_mom;

struct comp_pesa_mom_def {
	uchar c0;   /* flux n*Vx */
	uchar c1;   /*  Vx  */
	schar c2;   /*  Vy/Vx  */
	schar c3;   /*  Vz/Vx  */
	schar c4;   /*  Vxy  */
	schar c5;   /*  Vxz  */
	schar c6;   /*  Vyz  */
	uchar c7;   /*  Vxx  */
	uchar c8;   /*  Vyy  */
	uchar c9;   /*  Vzz  */
};
typedef struct comp_pesa_mom_def comp_pesa_mom;


struct pesa_mom_data_def {
	double time;
	uint2   spin;
	int2   gap;      /* set to 1 if a data gap is sensed */
	int2   valid;    /* set to 1 if data is valid */
	uchar  E_s;      /* starting point of pesa low sweep */
	uchar  ps;       /* starting phi sector in moment calculation */
	comp_pesa_mom cmom;  /* compressed moments */
	uint2   Vc;       /* compressed Vx value (only useful for debugging )*/
	float  E_min;    /* Lowest energy of sweep */
	float  E_max;    /* Highest energy of sweep */
	pmomdata  dist;      /* physical quantities */
};
typedef struct pesa_mom_data_def pesa_mom_data;


typedef struct {
	int num_samples;
	double *time;
	float  *dens_p;
	float  *temp_p;
	float  *Vpx;
	float  *Vpy;
	float  *Vpz;
	int2   *Vc;
	float  *Pp;
	float  *Qp;
	float  *dens_a;
	float  *temp_a;
	float  *Vax;
	float  *Vay;
	float  *Vaz;
	float  *Pa;
	float  *Qa;
} pmom_fill_str;


/* function prototypes  */

/* decomutation routines */

/* Gets next pmom structure with a time greater than BUT NOT EQUAL to time */
/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_pmom_struct(packet_selector *pks, pesa_mom_data Pmom[16], pesa_mom_data Amom[16]);



/*  Takes structure of pointers to blank memory and fills it with data*/
int fill_pmom_data(pmom_fill_str ptr);



/*  returns the number of ion moment samples between time t1 and t2  */
/*  Note:  there are 16 samples per packet  */
/*  If t2 is greater than the time of the last packet sample then the number */
/*  is estimated.   */
int number_of_pmom_struct_samples(double t1,double t2);



int   pmom_decom(packet *pk,pesa_mom_data Pmom[16],pesa_mom_data Amom[16]);
int   calc_pmom_param( pesa_mom_data *Pmom,PCFG *cfg);



#define N_ENERGY_PL 14
#define OVERLAP 56
#define START_V 32760


#endif
