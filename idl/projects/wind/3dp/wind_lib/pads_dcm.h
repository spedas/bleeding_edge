#ifndef PADS_DCM_H
#define PADS_DCM_H

#include "wind_pk.h"
#include "esteps.h"



typedef struct {
	double time1;        /*   starting time */
	double time2;        /*   ending time   */
	int num_samples;     /*  Number of spins of data               */
	units_format units;  /*  structure for units  */
	int num_angles;      /* Number of angle sectors ( <= 16 )      */
	int num_energies;    /* Number of energy steps (typically 15)  */
	int t_start;         /* starting theta channel   0, 16, or 32  */
	int t_stop;          /* ending  theta channel    16,32, or 40  */
	int map;             /* pitch angle map */
	double Vsw[3];         /* solar wind velocity */
	double Bdir_cart[3];   /* average B field direction  (cartesian)*/ 
	double Bdir_sphr[3];   /* spherical coordinates  (r,theta,phi) */
	double angles[16];     /* values of the pitch angles */
	double area[16];       /* relative geometric area */ 
	double energies[15];      /* energy (velocity) values */
	double nrg_min[15];
	double nrg_max[15];
	double flux[15*16];    /* data  [a][e]  */
}  PADdata; 




int pads_decom(packet *pk,PADdata *pad);
PADdata *get_next_ehpad(packet_selector *pks);

/*int init_rom_arrays(void ); */


#endif
