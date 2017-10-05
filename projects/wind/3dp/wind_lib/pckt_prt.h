#ifndef PCKT_PRT_H
#define PCKT_PRT_H

#include "wind_pk.h"
#include "mem_dcm.h"
#include <stdio.h>

extern FILE *unknown_pk_fp;

int print_unknown_packet(packet *pk);


/***  Generic printing routines ****/

int print_generic_packet(FILE *fp,packet *pk,int ncol);

void print_packet_data(FILE *fp,packet *pk,int nc,int format);

void print_packet_header(FILE *fp,packet *pk);

int  packet_log(FILE *fp,packet *pk);


#endif



