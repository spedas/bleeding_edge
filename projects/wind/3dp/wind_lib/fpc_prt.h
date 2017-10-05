#ifndef FPC_PRT_H
#define FPC_PRT_H

#include "wind_pk.h"
#include "fpc_dcm.h"  

extern  FILE *fpc_dump_raw_fp;
extern  FILE *fpc_dump_fp;
extern  FILE *fpc_xcorr_raw_fp;
extern  FILE *fpc_xcorr_fp;
extern  FILE *fpc_slice_raw_fp;
extern  FILE *fpc_slice_fp;


int print_fpc_dump_packet(packet *pk);
int print_fpc_xcorr_packet(packet *pk);
int print_fpc_slice_packet(packet *pk);



int print_fpc_xcorr(FILE *fp,fpc_xcorr_str *fpc);
int print_fpc_dump(FILE *fp,fpc_dump_str *fpc);



#endif
