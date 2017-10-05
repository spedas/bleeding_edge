#ifndef KPD_PRT_H
#define KPD_PRT_H

#include <stdio.h>

#include "wind_pk.h"

extern FILE *ekpd_fp;
extern FILE *pkpd_fp;
extern FILE *ekpd_raw_fp;
extern FILE *pkpd_raw_fp;
extern FILE *kpd_raw_fp;

int print_kpd_packet(packet *pk);
int print_kpd_raw(FILE *fp,packet *pk);


#endif
