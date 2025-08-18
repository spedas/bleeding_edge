#ifndef MAIN_CFG_H
#define MAIN_CFG_H

#include "mcfg_dcm.h"

/*  The following structure is the MASTER structure that contains ALL info
pertinent to the interpretation of SST data.  The user should NEVER change
any elements of this structure!!!!! */


struct MAIN_config_str {
	double time;        /* seconds since 1970 */
	double temperature1_2; 
	double temperature3;
	double spin_period; /* (Crit) */
	Mconfig norm_cfg;   /* (Crit) useful data from normal config packets*/

/* if any of the above critical values may need changing:  */
	 	/* Foil Detectors:  */
	float         foil_geom[6][2];                   /* geometric factors */
	float         rnergs_3d_F_mid[6][14];            /* 3d energy steps  */
	float         rnergs_3d_F_width[6][14];
	float         rnergs_3d_F_min[6][14];
 	float         rnergs_3d_F_max[6][14];
 	float         rnergs_3d_F_eff[6][7];
	float         rnergs_spect_F_mid[6][32];        /* spectra energy steps  */
	float         rnergs_spect_F_width[6][32];
	float         rnergs_spect_F_min[6][32];
 	float         rnergs_spect_F_max[6][32];
 	float         rnergs_spect_F_eff[6][16];


	 	/* Open Detectors:  */
	float         open_geom[6][2];
	float         rnergs_3d_O_mid[6][18];
	float         rnergs_3d_O_width[6][18];
	float         rnergs_3d_O_min[6][18];
	float         rnergs_3d_O_max[6][18];
	float         rnergs_spect_O_mid[6][48];
	float         rnergs_spect_O_width[6][48];
	float         rnergs_spect_O_min[6][48];
	float         rnergs_spect_O_max[6][48];

	 	/* Thick Detectors:  */
	float         thick_geom[6][2];
	float         rnergs_3d_OT_mid[2][9];
	float         rnergs_3d_OT_width[2][9];
	float         rnergs_3d_OT_min[2][9];
	float         rnergs_3d_OT_max[2][9];
	float         rnergs_spect_OT_mid[2][24];
	float         rnergs_spect_OT_width[2][24];
	float         rnergs_spect_OT_min[2][24];
	float         rnergs_spect_OT_max[2][24];
	float         rnergs_3d_FT_mid[2][7];
	float         rnergs_3d_FT_width[2][7];
	float         rnergs_3d_FT_min[2][7];
	float         rnergs_3d_FT_max[2][7];
	float         rnergs_3d_FT_eff[2][7];
	float         rnergs_spect_FT_mid[2][24];
	float         rnergs_spect_FT_width[2][24];
	float         rnergs_spect_FT_min[2][24];
	float         rnergs_spect_FT_max[2][24];
	float         rnergs_spect_FT_eff[2][24];
	float         rnergs_spect_T_mid[2][24];
	float         rnergs_spect_T_width[2][24];
	float         rnergs_spect_T_min[2][24];
	float         rnergs_spect_T_max[2][24];

/*	struct MAIN_config_str *next;     /* pointer to next config */
/*	struct MAIN_config_str *prev; */
	int valid;
};
typedef struct MAIN_config_str MCFG;



/* function prototypes:  */


MCFG *get_MCFG(double time);

int  get_nrg_3d_O(float y[6][18],int ne,int pos,MCFG *cfg);
int  get_nrg_3d_F(float y[6][14],int ne,int pos,MCFG *cfg);
int  get_nrg_3d_OT(float y[2][9],int ne,int pos,MCFG *cfg);
int  get_nrg_3d_FT(float y[2][7],int ne,int pos,MCFG *cfg);
int  get_nrg_spect_O(float y[6][48],int ne,int pos,MCFG *cfg);
int  get_nrg_spect_F(float y[6][32],int ne,int pos,MCFG *cfg);
int  get_nrg_spect_OT(float y[2][24],int ne,int pos,MCFG *cfg);
int  get_nrg_spect_FT(float y[2][24],int ne,int pos,MCFG *cfg);
int  get_nrg_spect_T(float y[2][24],int ne,int pos,MCFG *cfg);

float F_electronic_to_electron_energy(float x);
float O1_electronic_to_proton_energy(float x);
float O_electronic_to_proton_energy(float x);
float polynom5(float *coeff,float x);
enum { SSTMIN,SSTMAX,SSTMID,SSTEFF };

#endif
