#ifndef MCFG_PRT_H
#define MCFG_PRT_H

#include "wind_pk.h"

extern FILE *main_cfg_fp;
extern FILE *main_cscb_fp;

int print_main_cscb_packet(packet *pk);
int print_mconfig_packet(packet *pk);

#endif
