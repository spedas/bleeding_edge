#ifndef WINDDEFS_H
#define WINDDEFS_H

#include "defs.h"

/* #include "filter.h"  */
extern double cur_spin_period;
#define SPIN_PERIOD cur_spin_period

#ifdef MSDOS
#define _FAR far
typedef int    Align;                   /* provides alignment restriction */
typedef char *malloc_t;
#else
#define _FAR
#define _NEAR 
#define near
#endif

typedef uint2 nvector;
typedef uint2 np_uint;
typedef uint2 np_schar;



/*  ESA  sweep definitions */
struct sweep_param_def {
             uint2 start_E;   /* starting point of full sweep table           */
             uint2 k_sw;      /* slope of sweep                               */
             int2  s1;        /* DAC offset for high gain (should be signed!) */
             int2  s2;        /* DAC offset for low gain   (signed!)          */
             uint2 m2;        /* multiplication factor for low gain           */
             uint2 gs2;       /* lower threshold point  (for high gain)       */
};
typedef struct sweep_param_def sweep_def;

/* distribution (moments) definition */
struct distribution_def {
	int2    charge;   /* integral charge */
	double mass;     /*                            eV-s^2/km^2  */
	double dens;     /* density                      1/cc       */
	double temp;     /* temperature                   eV        */
	double v[3];     /* 3 components of velocity      km/s      */
	double vv[3][3]; /* pressure tensor / dens       (km/s)^2   */
	double q[3];     /* heat flux (not used for ions)           */
};


/* general */
#define PI 3.14159265358979
#define RAD (PI/180.)

/*  particle masses:  eV/(km/s)^2  */
#define MASS_E 5.6856591e-6
#define MASS_P (1836*MASS_E)
#define MASS_HE (4*MASS_P)


/*  geometric factors  */
#define GEOM_EH   (1.01e-1/360.)        /* cm^2 - ster / degree */
#define GEOM_EL   (1.26e-2/180.)
#define GEOM_PH   (1.49e-2/360.)
#define GEOM_PL   (1.62e-4/180.)


#if 0

/* Packet ID definitions */

#define         INVALID_ID     0x00000000ul
#define 	HKP_ID         0x00010000ul
#define 	KPD_ID         0x00020000ul
#define 	FRM_INFO_ID    0x00030000ul
#define 	ESPECT_ID      0x18400000ul
#define 	PSPECT_ID      0x28400000ul
#define 	EMOM_ID        0x50400000ul
#define		FPC_D_ID       0x37700000ul
#define		FPC_P_ID       0x37300000ul
#define         FPC_DUM_ID     0x37200000ul
#define 	PMOM_ID        0x60400000ul
#define 	EHPAD_ID       0x50600000ul
#define 	E3D_UNK_ID     0x50303000ul
#define 	E3D_CUT_ID     0x50302000ul
#define 	E3D_88_ID      0x50300000ul
#define 	P3D_ID         0x60300000ul
#define 	P3D_BRST_ID    0x36300000ul
#define 	E3D_BRST_ID    0x35300000ul
#define 	EH_BRST_ID     0x35301000ul
#define 	PLSNAP_ID      0x60500000ul
#define 	M_MEM_ID       0x02000000ul
#define 	E_MEM_ID       0x12000000ul
#define 	P_MEM_ID       0x22000000ul
#define 	M_HKP_ID       0x02100000ul
#define 	E_A2D_ID       0x12100000ul
#define 	P_A2D_ID       0x22100000ul
#define 	R_MEM_ID       0x02200000ul
#define 	M_CFG_ID       0x08000000ul
#define 	E_CFG_ID       0x18000000ul
#define 	P_CFG_ID       0x28000000ul
#define 	M_XCFG_ID      0x08200000ul
#define 	E_XCFG_ID      0x18200000ul
#define 	P_XCFG_ID      0x28200000ul
#define 	S_RATE_ID      0x08800000ul
#define 	S_RATE1_ID     0x08100000ul
#define 	S_RS_BST_ID    0x34100000ul
#define 	S_RATE3_ID     0x40100000ul
#define 	S_TBRST_ID     0x34200000ul
#define 	S_T_DST_ID     0x40200000ul
#define 	S_HS_BST_ID    0x34300000ul
#define 	S_3D_O_ID      0x40400000ul
#define 	S_3D_F_ID      0x40500000ul
#define 	S_PAD_ID       0x40600000ul

#define 	P_PHA_ID       0x28600000ul
#define 	P_F_RATE_ID    0x28800000ul
#define 	P_BST_DMP_ID   0x36200000ul
#define 	P_SNAP_BST_ID  0x36800000ul
#define 	E_F_RATE_ID    0x18800000ul
#define 	E_PHA_ID       0x18600000ul
#endif

#if 1
enum {
	EESAH_INST,
	EESAL_INST,
	PESAH_INST,
	PESAL_INST,
	INVALID_INST,
	SST_INST
};
#endif




#endif
