#ifndef SST_PRT_H
#define SST_PRT_H

/* Print routines for SST */
#include "wind_pk.h"

int print_sst_rate_packet(packet *pk);
extern FILE *sst_rate_fp;

int print_sst_spectra_packet(packet *pk);
extern FILE *s_spec_rate_fp;
extern FILE *s_spec_cond_fp;

int print_sst_3410_packet(packet *pk);
int print_sst_0810_packet(packet *pk);
extern FILE *s_0810_cal_fp;
extern FILE *s_3410_fp;

int print_sst_3d_O_packet(packet *pk);
int print_sst_343x_O_packet(packet *pk);
extern FILE *sst_3d_O_fp;
extern FILE *sst_3d_O_burst_fp;
extern FILE *sst_3d_O_accums_fp;

int print_sst_3d_F_packet(packet *pk);
int print_sst_343x_F_packet(packet *pk);
extern FILE *sst_3d_F_fp;
extern FILE *sst_3d_F_burst_fp;
extern FILE *sst_3d_F_accums_fp;

int print_sst_3d_t_packet(packet *pk);
int print_sst_342x_T_packet(packet *pk);
extern FILE *sst_3d_t_fp;
extern FILE *sst_3d_T_burst_fp;




/* Other print routines: */
#include "sst_dcm.h"

int print_sst_3d_O_dist(FILE *fp,sst_3d_O_distribution *dist);
int print_sst_3d_F_dist(FILE *fp,sst_3d_F_distribution *dist);
int print_sst_3d_t_dist(FILE *fp,sst_t_distribution *tdist);

#endif





