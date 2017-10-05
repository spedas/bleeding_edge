#ifndef PMOM_PRT_H
#define PMOM_PRT_H

#include "pmom_dcm.h"

int print_pmom_packet(packet *pk);
extern FILE *pmom_fp;
extern FILE *pmom_raw_fp;
extern FILE *amom_fp;
extern FILE *amom_raw_fp;
extern FILE *pmom_brst_fp;
extern FILE *pmom_binary_fp;


/* printing routines */
void  print_pmom_brst(FILE *fp, pesa_mom_data *P);
void  print_pmom_raw(FILE *fp, pesa_mom_data *P);
void  print_pmom_phys(FILE *fp, pesa_mom_data *P);

#endif
