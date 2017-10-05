#ifndef PL_DCM_H
#define PL_DCM_H

#include "winddefs.h"
#include "wind_pk.h"
#include "esteps.h"



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
	int2  valid;
	int4  spin;
	int2  nbins;
	int2  nenergy;
	uint2 dac_code[14*4];
        float volts[14*4];
	float flux[8][8][14];   /* counts,flux,   [t][p][e] */
        float nrg[8][8][14];
        float dnrg[8][8][14];
        float phi[8][8][14];        
        float dphi[8][8][14];
        float theta[8][8][14];
        float dtheta[8][8][14];
        uchar bins[8][8][14];
        float dt[8][8][14];
        float gf[8][8][14];
        float bkgrate[8][8][14];
        float deadtime[8][8][14];
        float dvolume[8][8][14];
        float ddata[8][8][14];
        float mag[3];
        float sc_pot;
        uchar p_shift;
        uchar t_shift;
        uchar e_shift;
	float domega[8][8];    /* solid angle [t][p] */
}  pl_snap_8x8;



/*  WARNING  DO NOT CHANGE without changing get_pl2.pro  */
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
	int2  valid;	
	int4  spin;
        int2  nbins;
        int2  nenergy;
        uint2 dac_code[14*4];
        float volts[14*4];
	float flux[5][5][14];   /* counts,flux,   [t][p][e] */
        float nrg[5][5][14];
        float dnrg[5][5][14];
        float phi[5][5][14];        
        float dphi[5][5][14];
        float theta[5][5][14];
        float dtheta[5][5][14];
        uchar bins[5][5][14];
        float dt[5][5][14];
        float gf[5][5][14];
        float bkgrate[5][5][14];
        float deadtime[5][5][14];
        float dvolume[5][5][14];
        float ddata[5][5][14];
        float mag[3];
        float sc_pot;
        uchar p_shift;
        uchar t_shift;
        uchar e_shift;
	float domega[5][5];     /* solid angle [t][p] */
}  pl_snap_55;



int get_next_plsnap55_struct(packet_selector *pks,pl_snap_55 *snap);
int number_of_plsnap55_samples(double t1,double t2);


int get_next_plsnap88_struct(packet_selector * pks,pl_snap_8x8 *snap);
int number_of_plsnap88_samples(double t1,double t2);


int decom_pl_snapshot_5x5(packet *pk,pl_snap_55 *snap);

int decom_pl_snapshot_8x8(packet *pk,pl_snap_8x8 *snap);
int decom_pl_snapshot_8x8_2(packet *pk1,packet *pk2, pl_snap_8x8 *snap);

#endif


