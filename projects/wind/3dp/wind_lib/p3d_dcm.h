#ifndef P3D_DCM_H
#define P3D_DCM_H

#include "defs.h"
#include "wind_pk.h"
/*#include "map3d.h" */



/* this structure gives useful info for a single angle bin of a given map */
typedef struct {
	int   ne;          /* number of energy steps */
	int   offset;      /*  offset to spectrum in the data array */
	float geom;        /* geometric area */
	float gf;
	float dt;
	float theta,phi[30];
	float dtheta,dphi,domega;
} BinRange;

#define MAX3DBINS 128
#define MAX3DSAMPLES 2048

typedef struct {
	double  time;
	float   integ_t;    /* duration of sample  */
	float   delta_t;    /* time between samples */
	float   spin_period;
	float   geom_factor;   /* instrument geometric factor  */
	float   mass;
	int     inst;          /* instrument number specifies which analyzer */
	uint2   spin;
	uint2  	mapcode;
	uint2 	erescode;
	int     ntheta;  /* typically 16 or 24  */
	int   	nbins;   /* number of angle bins  */
	int   	nsamples; /* number of data samples (bytes) */
	int	nenergies; /* number energies that will be used in idl struct*/
	int     max_bytes_per_packet;  
	int     flux_units; 
	int     nrg_units;
	int     status;
	int     npackets;
	int     map_is_initialized;/* flag;*/
	uchar   p0;               /* first phi bin after pass thru x-direction*/
	uchar   shift;            /* flight shift value  */
	double  nrg_min[30];  
	double  nrg_max[30];
	double	nrg15[15];
	double  nrg30[30];
	double	dnrg15[15];
	double  dnrg30[30];
	uint 	 ptmap[24*32];  /* phi theta map of size [24 x 32]  */
	BinRange bin[MAX3DBINS];   /*  will contain nbins elements */
	float   data[MAX3DSAMPLES];   /*  will have nsamples of elements */
	int     dt[MAX3DSAMPLES];
	uchar	magel;
	uint2	magaz;
} data_map_3d;



typedef struct {
        IDL_STRING project_name;
        IDL_STRING data_name;
        IDL_STRING units_name;
        IDL_STRING units_procedure;
        double time;           /* sample time */
        double end_time;
        double trange[2];
        double integ_t;        /* integration time typically 3 seconds */
        double delta_t;        /* time between samples */
        double mass;
        double geom_factor;
        int4  index;
        int4  n_samples;
        uchar shift;
        int2  valid;
        int4  spin;
        int2  nbins;
        int2  nenergy;
        uint2 dac_code[15*8];
        float volts[15*8];
        float flux[88][15];   /* counts,flux,   [t*p][e] */
        float nrg[88][15];
        float dnrg[88][15];
        float phi[88][15];        
        float dphi[88][15];
        float theta[88][15];
        float dtheta[88][15];
        uchar bins[88][15];
        float dt[88][15];
        float gf[88][15];
        float bkgrate[88][15];
        float deadtime[88][15];
        float dvolume[88][15];
        float ddata[88][15];
        float mag[3];
        float vsw[3];
        float domega[88];    /* solid angle [t][p] */
        float sc_pot;
        float e_shift;
}  e3d_data;

typedef struct {
        IDL_STRING project_name;
        IDL_STRING data_name;
        IDL_STRING units_name;
        IDL_STRING units_procedure;
        double time;           /* sample time */
        double end_time;
        double trange[2];
        double integ_t;        /* integration time typically 3 seconds */
        double delta_t;        /* time between samples */
        double mass;
        double geom_factor;
        int4  index;
        int4  n_samples;
        uchar shift;
        int2  valid;
        int4  spin;
        int2  nbins;
        int2  nenergy;
        uint2 dac_code[15*8];
        float volts[15*8];
        float flux[32][15];   /* counts,flux,   [t*p][e] */
        float nrg[32][15];
        float dnrg[32][15];
        float phi[32][15];        
        float dphi[32][15];
        float theta[32][15];
        float dtheta[32][15];
        uchar bins[32][15];
        float dt[32][15];
        float gf[32][15];
        float bkgrate[32][15];
        float deadtime[32][15];
        float dvolume[32][15];
        float ddata[32][15];
        float mag[3];
        float vsw[3];
        float domega[32];    /* solid angle [t][p] */
        float sc_pot;
        float e_shift;
}  elc_data;

typedef struct {
        IDL_STRING project_name;
        IDL_STRING data_name;
        IDL_STRING units_name;
        IDL_STRING units_procedure;
        double time;           /* sample time */
        double end_time;
        double trange[2];
        double integ_t;        /* integration time typically 3 seconds */
        double delta_t;        /* time between samples */
        double mass;
        double geom_factor;
        int4  index;
        int4  n_samples;
        uchar shift;
        int2  valid;
        int4  spin;
        int2  nbins;
        int2  nenergy;
        uint2 dac_code[15*8];
        float volts[15*8];
        float flux[24][30];   /* counts,flux,   [t*p][e] */
        float nrg[24][30];
        float dnrg[24][30];
        float phi[24][30];        
        float dphi[24][30];
        float theta[24][30];
        float dtheta[24][30];
        uchar bins[24][30];
        float dt[24][30];
        float gf[24][30];
        float bkgrate[24][30];
        float deadtime[24][30];
        float dvolume[24][30];
        float ddata[24][30];
        float mag[3];
        float vsw[3];
        float domega[24];    /* solid angle [t][p] */
        float sc_pot;
        float e_shift;
}  ehs_data;

typedef struct {
	double time;
/* user input */
	int units;        /* will give the units of flux  */
	int bin1,bin2;    /* starting, ending bin  (does not include end bin) */
/*	int tstart,tstop;         not used yet */
/*	int pstart,pstop;         not used yet */
/* output  */
	float integ_t;    /* duration of sample  */
	float delta_t;    /* time between samples */
	float flux[15];
	float nrg_min[15];    /* not all steps will be used!!! */
	float nrg_max[15];
} spectra_3d_omni;




#if 0
typedef struct {
	double time;
/* user input */
	int units;
/* output  */
	int ne;
	int nt;
	int np;
	float flux[15*32*32];
}  data_full3d;
#endif


/*   prototypes:  */


int number_of_el_omni_samples(double t1,double t2);

int get_next_el_omni_spec(double time,spectra_3d_omni *spec);
/* omni-directional energy spectra for EESA Low */
/* returns 0 if data is not available */
/* returns 1 if data is filled  */

int number_of_ph_omni_samples(double t1,double t2);

int get_next_ph_omni_spec(double time,spectra_3d_omni *spec);
/* omni-directional energy spectra for PESA HIGH */
/* returns 0 if data is not available */
/* returns 1 if data is filled  */



int number_of_eh_omni_samples(double t1,double t2);

int get_next_eh_omni_spec(double time,spectra_3d_omni *spec);
/* omni-directional energy spectra for EESA HIGH */
/* returns 0 if data is not available */
/* returns 1 if data is filled  */



/* The following routines are not for general use yet  */
int get_next_p3d(packet_selector *pks, data_map_3d *map, int exppk);
int sum_p3d_15_channels(data_map_3d *p3d,int bin1,int bin2,spectra_3d_omni *spec);
int make_3d_array(data_map_3d *map,float *buff);

#include "pads_dcm.h"
int sum_pad_15_channels(PADdata *pad,int bin1,int bin2,spectra_3d_omni *spec);
int average_p3d_channels(data_map_3d *p3d,uchar *blanked,spectra_3d_omni *spec);

#endif
