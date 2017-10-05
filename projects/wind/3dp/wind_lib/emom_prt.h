#ifndef EMOM_PRT_H
#define EMOM_PRT_H

#include "emom_dcm.h"
#include "wind_pk.h"

#include <stdio.h>



extern FILE *emom_fp;
extern FILE *emom_raw_fp;
extern FILE *emom_rraw_fp;


/* printing routines */

int print_emom_packet(packet *pk);

void print_emom_phys(FILE *fp,eesa_mom_data *Emom);
void print_emom_raw(FILE *fp,eesa_mom_data *Emom);



#endif

