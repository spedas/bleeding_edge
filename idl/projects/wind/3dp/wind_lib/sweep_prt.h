#ifndef SWEEP_PRT_H
#define SWEEP_PRT_H
#include "eesa_cfg.h"
#include "pesa_cfg.h"

#include <stdio.h>


void print_sweep_el(FILE *fp,ECFG *cfg);
void print_sweep_eh(FILE *fp,ECFG *cfg);
void print_sweep_pl(FILE *fp,PCFG *cfg);
void print_sweep_ph(FILE *fp,PCFG *cfg);


#endif
