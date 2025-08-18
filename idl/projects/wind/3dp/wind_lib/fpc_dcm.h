#ifndef FPC_DCM_H
#define FPC_DCM_H

#include "winddefs.h"
#include "wind_pk.h"

#define N_FPC_SAMPLES (16*8)

/* Fast particle correlator struct.  NOTE THAT THIS STRUCT
 * IS PAST IN FROM IDL, AND MUST MATCH THE IDL SIDE EXACTALLY!!
 */


typedef struct {                        /* IDL STRUCT..                                 */
    double time;                        /* time:       double                           */
    long index;                         /* index of packet: long                        */
    enum SELECT_METHOD select_by;       /* select by index (0) or time (1): long        */
    double spinperiod;                  /* spinperiod: double                           */
    int  spin;                          /* spin:       long                             */
    int  E_step;                        /* E_steps:    long                             */
    int  Bq_th;                         /* Bq_th:      long                             */
    int  Bq_ph;                         /* Bq_ph:      long                             */
    float  Energy;                      /* Energy:     float                            */
    float  B_th;                        /* B_th:       float                            */
    float  B_ph;                        /* B_ph:       float                            */
    int  code;                          /* code:       long                             */
    int  valid;                         /* valid:      long                             */
/*    int2  waves_ad[8];   */ 				       
    int2  time_total[8];                /* time_total: int  (8)                         */
    int2  flags[8];                     /* flags:      int  (8)                         */
    float  sample_time[N_FPC_SAMPLES];  /* sample_time:float(128)                       */
    float  total[4][N_FPC_SAMPLES];     /* total:      float(128,4)                     */
    float  sin_c[4][N_FPC_SAMPLES];     /* sin:        float(128,4)                     */
    float  cos_c[4][N_FPC_SAMPLES];     /* cos:        float(128,4)                     */
    float  freq[N_FPC_SAMPLES];         /* freq:       float(128)                       */
    float  sint[N_FPC_SAMPLES];         /* sint:       float(128)                       */
    float  cost[N_FPC_SAMPLES];         /* cost:       float(128)                       */
    float  wave_power[N_FPC_SAMPLES];   /* wave_ampl:  float(128)                       */
    float phi[4][N_FPC_SAMPLES];        /* phi:        float(128,4)                     */
    float theta[4][N_FPC_SAMPLES];      /* theta:      float(128,4)                     */
} fpc_xcorr_str;

typedef struct {
    double *time;
    float  *sample_time;
    int2   *misc;
    int2   *total;
    int2   *sin_c;
    int2   *cos_c;
    int2   *freq;
    int2   *sin_t;
    int2   *cos_t;
    int2   *wpower;

}  fpc_xcorr_fill_str;


typedef struct {
    double time;
    uint2 spin;
    uint2 sweepnum;
    uint2 burstnum;
    uint2 channel;
    uchar  code[4];
    uint2  counters[16][15];
}  fpc_dump_str;



int fpc_clear(fpc_xcorr_str *fpc);
int fpc_xcorr_decom(packet *pk,fpc_xcorr_str *fpc);
int fpc_dump_decom(packet *pk,fpc_dump_str *fpc);


#endif
