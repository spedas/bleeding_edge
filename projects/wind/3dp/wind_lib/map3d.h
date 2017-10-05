#ifndef MAP3D_H
#define MAP3D_H

#include "defs.h"
#include "wind_pk.h"
#include "p3d_dcm.h"


#include <stdio.h>

#define MAP_MOM 0xD8AC   /* 88 angle map code */
#define MAP_45D 0xDA43   /* 45 degree resolution map */
#define MAP_elc 0xD9E3   /* eesa low cuts */
#define MAP45d  0xD6BB   /* pesah */
#define MAP_0   0xD400   /* pesah ? incorrect */
#define MAP11b  0xD4FE   /* pesah s1x */
#define MAP11d  0xD4A4   /* pesah */
#define MAP_8   0xD5EC   /* pesah burst.  Macro needs to be changed 
                            when we get flight code offset */
#define MAP_ehs 0x1      /* eesa high slice */
#define MAP22d  0xD65D   /* pesah 88a */



int decom_map3d(packet *pk,data_map_3d *);


/*  private functions: */
int init_data_map_3d(packet *pk,data_map_3d *);
int convert_3dmap_units(data_map_3d *map);


#endif
