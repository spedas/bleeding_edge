#ifndef MEM_DCM_H
#define MEM_DCM_H

#include "wind_pk.h"

#include <stdio.h>


extern FILE *memory_dump_fp;
extern FILE *eesa_dump_fp;
int print_memory_dump_packet(packet *pk);




int print_block_memory(FILE *fp,packet *pk);
int print_eparam_memory(FILE *fp,packet *pk);

typedef struct  {
	char *name;
	uint2 size;
	char  type;
	uint2 loc;
	uint2 ig_change;
}  Parameter_Location;

int init_parameters(Parameter_Location par[]);

int print_params(FILE *fp,Parameter_Location par[],uint2 loc,uchar *d,int ndata);

extern Parameter_Location eesa_mem_par[];
extern Parameter_Location eesa_cfg_par[];
extern Parameter_Location pesa_mem_par[];


#endif
