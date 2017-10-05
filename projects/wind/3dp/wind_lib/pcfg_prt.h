#ifndef PCFG_PRT_H
#define PCFG_PRT_H

#include "wind_pk.h"



extern FILE *pesa_cfg_fp;
extern FILE *pesa_cfg_raw_fp;
extern FILE *pesa_par_fp;

extern FILE *plswp_fp;
extern FILE *phswp_fp;

int print_pconfig_packet(packet *pk);

#endif
