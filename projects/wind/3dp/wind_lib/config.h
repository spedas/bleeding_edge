#define  DEFAULT_SWEEP 1


#if DEFAULT_SWEEP 
   /*  EESAL  sweep  */
#if 1   /* set to 1 for test sweep */
#define START_E_EL    8100 
#define K_SW_EL       62500
#define S1_EL         -1038
#define S2_EL         0x0300
#define M2_EL         16234
#define GSHIFT2_EL    8392
#else
#define START_E_EL    8222 
#define K_SW_EL       62500
#define S1_EL         -1038
#define S2_EL         350
#define M2_EL         16234
#define GSHIFT2_EL    8392
#endif

   /*  EESAH  sweep  */
#define START_E_EH    65535
#define K_SW_EH       62500
#define S1_EH         -304
#define S2_EH         725
#define M2_EH         34269
#define GSHIFT2_EH    1000

	/*  PESAH  sweep  */
#define START_E_PH    0xFDEF
#define K_SW_PH       0xF230
#define S1_PH         0x0210
#define S2_PH         0x05DF
#define M2_PH         0x7AE0
#define GSHIFT2_PH    0x0050

	/*  PESAL  sweep  */
#define START_E_PL    0x61A8
#define K_SW_PL       0xF618
#define S1_PL         0x020A
#define S2_PL         0x05C1
#define M2_PL         0x7B2B
#define GSHIFT2_PL    0x0116
#define GSHIFT1_PL    0x103D
#define BNDRY_PT      0x30

#else


/*  EESAH stuff  */
#define START_E_EH    1500   /* nominally 65000 */
#define K_SW_EH       63000
#define S1_EH         ((int)((DH_EH+.5)*16.))
#define S2_EH         ((int)((DL_EH+.5)*16.))
#define M2_EH         ((uint)(ML_EH/MH_EH*2048.))
#define GSHIFT2_EH     2500                        /*  might change this */

/*   EESAL stuff  */
#define START_E_EL    16000
#define K_SW_EL       63000
#define S1_EL         ((int)((DH_EL+.5)*16.))
#define S2_EL         ((int)((DL_EL+.5)*16.))
#define M2_EL         ((uint)(ML_EL/MH_EL*2048.))
#define GSHIFT2_EL     2500                        /*  might change this */


/*  pesah stuff */
#define START_E_PH    65007
#define K_SW_PH       61500
#define M2_PH         ((int)((DH_PH+.5)*16.))
#define S1_PH         ((int)((DL_PH+.5)*16.))
#define S2_PH         ((uint)(ML_PH/MH_PH*2048.))
#define GSHIFT2_PH    0x0050

/*   PESAL stuff  */
#define START_E_PL    25000
#define K_SW_PL       63000
#define S1_PL         ((int)((DH_PL+.5)*16.))
#define S2_PL         ((int)((DL_PL+.5)*16.))
#define M2_PL         ((uint)(ML_PL/MH_PL*2048.))
#define GSHIFT2_PL    0x0116
#define GSHIFT1_PL    0x103D

#endif
