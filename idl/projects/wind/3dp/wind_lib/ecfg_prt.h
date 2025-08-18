#ifndef ECFG_PRT_H
#define ECFG_PRT_H


#include "winddefs.h"
#include "wind_pk.h"


extern FILE *eesa_cfg_fp;
extern FILE *ecfg_par_fp;
extern FILE *eesa_sweep_par_fp;

extern FILE *eesa_xcfg_fp;
extern FILE *excfg_par_fp;

extern FILE *elswp_fp;
extern FILE *ehswp_fp;

extern FILE *eesa_cscb_fp;

int print_eesa_cscb_packet(packet *pk);

int print_econfig_packet(packet *pk);
int print_exconfig_packet(packet *pk);


#endif

