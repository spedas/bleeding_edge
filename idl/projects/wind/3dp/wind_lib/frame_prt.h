#ifndef  FRAME_PRT_H
#define  FRAME_PRT_H

#include "frame_dcm.h"
#include "wind_pk.h"
#include "windmisc.h"

#include <string.h>

extern FILE *info_fp;


int print_frameinfo_packet(packet *pk);


int print_frame_struct(FILE *fp,struct frameinfo_def *frm);

char *spc_mode_str(int spc_mode);

#endif
