#ifndef PL_PRT_H
#define PL_PRT_H

#include "pl_dcm.h"
#include "wind_pk.h"

/*  Normal telemetry routines: */

int print_plsnap5x5_packet(packet *pk);
extern FILE *plsnap5x5_fp;
extern FILE *plsnap5x5_raw_fp;
extern FILE *plsnap5x5_cut_fp;


int print_plsnap5x5(FILE *fp,pl_snap_55 *pldata);
int print_plsnap5x5_cut(FILE *fp,pl_snap_55 *pldata);


/*  burst printing routines: */

int print_plsnap8x8_packet(packet *pk);
extern FILE *plsnap8x8_fp;
extern FILE *plsnap8x8_raw_fp;
extern FILE *plsnap8x8_draw_fp;

int print_plsnap8x8(FILE *fp,pl_snap_8x8 *pldata);

#endif


