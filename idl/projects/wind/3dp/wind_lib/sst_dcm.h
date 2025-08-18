#ifndef  SST_DCM_H
#define  SST_DCM_H

#include "defs.h"
#include "wind_pk.h"

/**********  FLAT RATES   (0880) *****************/

struct sst_flat_rate_str {
	double time;
	uint2  magaz;
	int    units;
	uchar  magel;
	float  nrg_min[14];
	float  nrg_max[14];
	float  flux[14][16];
	uint2  spin;
};
typedef struct sst_flat_rate_str sst_flat_rate;

int fill_sst_flat_rate_str(packet *pk,struct sst_flat_rate_str *rate);

/********** RATES+SPECTRA  (0810, 341x, 401x)  *************/

struct sst_spectra_struct {
	double time;
	double integ_t;   /* base integration time */
	double delta_t;   /* time between samples */
	double mass;
	double geom_factor;
	int base;         /* #of spins at base rate */
	int ne;            /* internal use only */
	int valid;         /* must have the value 15 to be valid */
	uint2  magaz;
	uchar  magel;
	uchar  pulse_mode;
	uchar  operating_mode;
	uchar  integration_factor;
	uint2  spin;
	
	float theta_f[6];
	float theta_o[6];
	float phi[6];
	float dtheta[6];
	float dphi[6];
	float domega[6];
	float geom[6];
	float duty_cycle[24];
	int2  pt_F_map[6];
	int2  pt_O_map[6];


	float  e_F_min[6][32]	;
	float  e_F_mid[6][32]	;
	float  e_F_max[6][32];
	float  e_F_eff[6][32];

	float  e_O_min[6][48]	;
	float  e_O_mid[6][48]	;
	float  e_O_max[6][48];

	float e_FT_min[2][24];
	float e_FT_mid[2][24];
	float e_FT_max[2][24];
	float e_FT_eff[2][24];

	float e_OT_min[2][24];
	float e_OT_mid[2][24];
	float e_OT_max[2][24];
	
	float  rates[14];

	float  FT2[24];
	float  OT2[24];
	float  FT6[24];
	float  OT6[24];
	
	float  F6[16];
	float  F2[16];
	float  F3[16];
	float  F4[16];
	float  F5[16];
	float  F1[16];

	float  O6[24];
	float  O2[24];
	float  O3[24];
	float  O4[24];
	float  O5[24];
	float  O1[24];

	uchar  calib_control[6];   /*  0810's only */
};
typedef struct sst_spectra_struct sst_spectra;

int fill_sst_spectra_struct(packet *pk, sst_spectra *spec);

int get_next_sst_spectra_str(packet_selector *pks,struct sst_spectra_struct *sst);



/************* T - DISRIBUTION  (402x 342x) ***********/

struct sst_t_distribution_str {
	double time;
	double integ_t;   /* base integration time */
	double delta_t;   /* time between samples */
	double spin_period;
	double mass;
	double geom_factor;
	int base;         /* #of spins at base rate */
	int ne;            /* internal use only */
	int valid;         /* must have the value 15 to be valid */
	uint2  spin;
	
	float e_FT_mid[2][7];
	float e_FT_min[2][7];
	float e_FT_max[2][7];
	float e_FT_eff[2][7];

	float e_OT_mid[2][9];
	float e_OT_min[2][9];
	float e_OT_max[2][9];
	
	float FT2[7][8];
	float OT2[9][8];
	float FT6[7][8];
	float OT6[9][8];

	int   dt_FT[7][16];
	int   dt_OT[9][16];
	
	float theta[32];
	float phi[32];
	float dtheta[32];
	float dphi[32];
	float domega[32];
	float geom[32];
	float duty_cycle[9];
	int2  pt_FT_map[5][8];
	int2  pt_OT_map[5][8];


	
};
typedef struct sst_t_distribution_str sst_t_distribution;

int fill_sst_t_distribution(packet *pk, sst_t_distribution *tdist);

int get_next_sst_3d_T_str(packet_selector *pks,sst_t_distribution *dist);



/*************  3D-O data  (404x)  *********/


struct sst_3d_O_distribution_str {
	double time;
	double integ_t;   /* base integration time */
	double delta_t;   /* time between samples */
	double mass;
	double geom_factor;
        double spin_period;
	int seqn;         /* sequence number 0-7 */
	int base;         /* #of spins at base rate */
	int ne;            /* internal use only */
	int valid;         /* must have the value 15 to be valid */
	uint2  spin;
	
	float energies[6][18];  /* middle of each energy step  */
	float e_min[6][18];
	float e_max[6][18];
	float duty_cycle[9];

	float rates[14];
	float flux[9][48];
	int   dt[9][48];
	
	float theta[48];
	float phi[48];
	float dtheta[48];
	float dphi[48];
	float domega[48];
	float geom[48];
	int2  pt_map[5][32];
	
};
typedef struct sst_3d_O_distribution_str sst_3d_O_distribution;

int fill_sst_3d_O_distribution(packet *pk, sst_3d_O_distribution *dist);





/*************  3D-F data  (405x)  *********/


struct sst_3d_F_distribution_str {
	double time;
	double integ_t;   /* base integration time */
	double delta_t;   /* time between samples */
	double mass;
	double geom_factor;
        double spin_period;
        uint2 spin;       /* spin number */
	int seqn;         /* sequence number 0-3 */
	int base;	  /* number of spins at base rate */
	int ne;		  /* internal use only */
	int valid;        /* must have the value 15 to be valid */
	
	float energies[6][14];/* middle of each energy step */
	float e_min[6][14];   /* lower energy step value    */
	float e_max[6][14];   /* upper energy step value    */
	float e_eff[6][14];   
	float duty_cycle[7];
     
        float accum_time[7];  /* not used yet! */

	float flux[7][48];/* 7 energies at 48 angles */
	int   dt[7][48];
	
	float theta[48];
	float phi[48];
	float dtheta[48];
	float dphi[48];
	float domega[48];
	float geom[48];
	int2  pt_map[5][32];  /* phi,theta map of the bins */
};

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
        int2  valid;
        int4  spin;
        int2  nbins;
        int2  nenergy;
        int2  detector[48];
        float flux[48][7];   /* counts,flux,   [t][p][e] */
        float nrg[48][7];
        float dnrg[48][7];
        float phi[48][7];        
        float dphi[48][7];
        float theta[48][7];
        float dtheta[48][7];
        uchar bins[48][7];
        float dt[48][7];
        float gf[48][7];
        float bkgrate[48][7];
        float deadtime[48][7];
        float dvolume[48][7];
        float ddata[48][7];
        float mag[3];
        float vsw[3];
        float sc_pot;
        float domega[48];    /* solid angle [t][p] */
        float feff[48][7];
}  sst_foil_data;

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
        int2  valid;
        int4  spin;
        int2  nbins;
        int2  nenergy;
        int2  detector[48];
        float flux[48][9];   /* counts,flux,   [t][p][e] */
        float nrg[48][9];
        float dnrg[48][9];
        float phi[48][9];        
        float dphi[48][9];
        float theta[48][9];
        float dtheta[48][9];
        uchar bins[48][9];
        float dt[48][9];
        float gf[48][9];
        float bkgrate[48][9];
        float deadtime[48][9];
        float dvolume[48][9];
        float ddata[48][9];
        float mag[3];
        float vsw[3];
        float sc_pot;
        float domega[48];    /* solid angle [t][p] */
}  sst_open_data;

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
        int2  valid;
        int4  spin;
        int2  nbins;
        int2  nenergy;
        int2  detector[16];
        float flux[16][7];   /* counts,flux,   [t][p][e] */
        float nrg[16][7];
        float dnrg[16][7];
        float phi[16][7];        
        float dphi[16][7];
        float theta[16][7];
        float dtheta[16][7];
        uchar bins[16][7];
        float dt[16][7];
        float gf[16][7];
        float bkgrate[16][7];
        float deadtime[16][7];
        float dvolume[16][7];
        float ddata[16][7];
        float mag[3];
        float vsw[3];
        float sc_pot;
        float domega[16];    /* solid angle [t][p] */
        float feff[16][7];
}  sft_data;

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
        int2  valid;
        int4  spin;
        int2  nbins;
        int2  nenergy;
        int2  detector[16];
        float flux[16][9];   /* counts,flux,   [t][p][e] */
        float nrg[16][9];
        float dnrg[16][9];
        float phi[16][9];        
        float dphi[16][9];
        float theta[16][9];
        float dtheta[16][9];
        uchar bins[16][9];
        float dt[16][9];
        float gf[16][9];
        float bkgrate[16][9];
        float deadtime[16][9];
        float dvolume[16][9];
        float ddata[16][9];
        float mag[3];
        float vsw[3];
        float sc_pot;
        float domega[16];    /* solid angle [t][p] */
}  sot_data;

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
        int2  valid;
        int4  spin;
        int2  nbins;
        int2  nenergy;
        int2  detector[6];
        float flux[6][16];   /* counts,flux,   [t][p][e] */
        float nrg[6][16];
        float dnrg[6][16];
        float phi[6][16];        
        float dphi[6][16];
        float theta[6][16];
        float dtheta[6][16];
        uchar bins[6][16];
        float dt[6][16];
        float gf[6][16];
        float bkgrate[6][16];
        float deadtime[6][16];
        float dvolume[6][16];
        float ddata[6][16];
        float mag[3];
        float vsw[3];
        float sc_pot;
        float domega[6];    /* solid angle [t][p] */
        float feff[6][16];
}  fspc_data;

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
        int2  valid;
        int4  spin;
        int2  nbins;
        int2  nenergy;
        int2  detector[6];
        float flux[6][24];   /* counts,flux,   [t][p][e] */
        float nrg[6][24];
        float dnrg[6][24];
        float phi[6][24];        
        float dphi[6][24];
        float theta[6][24];
        float dtheta[6][24];
        uchar bins[6][24];
        float dt[6][24];
        float gf[6][24];
        float bkgrate[6][24];
        float deadtime[6][24];
        float dvolume[6][24];
        float ddata[6][24];
        float mag[3];
        float vsw[3];
        float sc_pot;
        float domega[6];    /* solid angle [t][p] */
}  ospc_data;

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
        int2  valid;
        int4  spin;
        int2  nbins;
        int2  nenergy;
        int2  detector[4];
        float flux[4][24];   /* counts,flux,   [t][p][e] */
        float nrg[4][24];
        float dnrg[4][24];
        float phi[4][24];        
        float dphi[4][24];
        float theta[4][24];
        float dtheta[4][24];
        uchar bins[4][24];
        float dt[4][24];
        float gf[4][24];
        float bkgrate[4][24];
        float deadtime[4][24];
        float dvolume[4][24];
        float ddata[4][24];
        float mag[3];
        float vsw[3];
        float sc_pot;
        float domega[4];    /* solid angle [t][p] */
        float feff[4][24];
}  tspc_data;

typedef struct sst_3d_F_distribution_str sst_3d_F_distribution;

int fill_sst_3d_F_distribution(packet *pk, sst_3d_F_distribution *dist);

int number_of_sst_3d_O_samples(double t1,double t2);

int number_of_sst_3d_F_samples(double t1,double t2);

int get_next_sst_3d_O_str(packet_selector *pks,sst_3d_O_distribution *dist, 
		      int mode, uint2 *validmask);

int get_next_sst_3d_F_str(packet_selector *pks,sst_3d_F_distribution *dist, 
		      int mode, uint2 *validmask);

#endif
