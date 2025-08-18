#ifndef PADS_PRT_H
#define PADS_PRT_H

#include "wind_pk.h"
#include "pads_dcm.h"

extern FILE *pads_fp;
extern FILE *pads_spec_fp;
extern FILE *pads_raw_fp;
extern FILE *pads_log_fp;

int print_pads_packet(packet *pk);
int print_pad_structure(FILE *fp,PADdata *pad);
int print_pad_spectra(FILE *fp,PADdata *pad);


#endif

