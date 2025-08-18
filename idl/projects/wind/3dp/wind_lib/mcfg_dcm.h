#ifndef MCFG_DCM_H
#define MCFG_DCM_H

#include "wind_pk.h"


extern uchar current_main_config_data[];
#define MCONFIG_SIZE 110 



typedef struct {
    double time;
    uchar  sst_mode_cmnd;
    uchar  sst_tst_cmnd;
    uchar  sst_t_lut;
    uchar  sst_o_lut;
    uchar  sst_f_lut;
    uchar  sst_thrf1;
    uchar  sst_thrf5;
    uchar  sst_thrf4;
    uchar  sst_thrf3;
    uchar  sst_thro1;
    uchar  sst_thro5;
    uchar  sst_thro4;
    uchar  sst_thro3;
    uchar  sst_thrf2;
    uchar  sst_thrf6;
    uchar  sst_thro2;
    uchar  sst_thro6;
    uchar  sst_thrt2;
    uchar  sst_thrt6;
    uchar  sst_hvref;
    uchar  sst_tg_ref;
    uint2  inst_crc;

    int valid;
} Mconfig;

typedef struct {
        IDL_STRING project_name;
        IDL_STRING data_name;
        double time;           /* sample time */
        int4   index;
        int2   valid;
        uchar  data[92];
} mcfg_data;


int decom_mconfig(packet *pk,Mconfig *mcfg);


#endif

