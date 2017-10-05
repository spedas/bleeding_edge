
#include "kpd_dcm.h"
#include "windmisc.h"
#include "pesa_cfg.h"
#include "eesa_cfg.h"

int kpd_decom(packet *pk,kpd_struct *kpd)
{
	ECFG *ecfg;
	PCFG *pcfg;
	if(pk==0){
		kpd->valid = 0;
		return(0);
	}
	ecfg = get_ECFG(pk->time);   /* get eesa instrument configuration */
	pcfg = get_PCFG(pk->time);   /* get pesa instrument config */

	return(unpack_to_kpd_def(pk->data,pk->time,pk->spin,kpd,ecfg,pcfg));	
}



int unpack_to_kpd_def(uchar *s,double time,uint2 spin,kpd_struct *kpd,
     ECFG *ecfg, PCFG *pcfg)
{
	kpd->valid = s[0];  /*  data validity not checked yet */

	kpd->sst_foil_0_1   = decomp19_8(s[1]);
	kpd->sst_foil_2_3   = decomp19_8(s[2]);
	kpd->sst_foil_4     = decomp19_8(s[3]);
	kpd->sst_open_0     = decomp19_8(s[4]);
	kpd->sst_open_1     = decomp19_8(s[5]);
	kpd->sst_open_2_3   = decomp19_8(s[6]);

	kpd->Emom.time = time;
	kpd->Emom.spin = spin;
	kpd->Emom.cmom.c0 = (s[8]<<8)+s[7];
	kpd->Emom.cmom.c1 = s[9];
	kpd->Emom.cmom.c2 = s[10];
	kpd->Emom.cmom.c3 = s[11];
	kpd->Emom.cmom.c4 = 0;        /*  not provided with key parameters */
	kpd->Emom.cmom.c5 = 0;        /*  not provided with key parameters */
	kpd->Emom.cmom.c6 = 0;        /*  not provided with key parameters */
	kpd->Emom.cmom.c7 = s[12];
	kpd->Emom.cmom.c8 = s[13];
	kpd->Emom.cmom.c9 = s[14];
	kpd->Emom.cmom.c10= 0;        /*  not provided with key parameters */
	kpd->Emom.cmom.c11= 0;        /*  not provided with key parameters */
	kpd->Emom.cmom.c12= 0;        /*  not provided with key parameters */

	kpd->Emom.dist.charge = -1;
	kpd->Emom.dist.mass = MASS_E;
	calc_emom_param(&kpd->Emom,ecfg);  /* calculate physical quantities */ 

	kpd->eesa_qdotb  = signdecomp12(s[15]);  /* 8 to 12 bit signed decomp */

	kpd->eesa_flux_0   = decomp19_8(s[16]);
	kpd->eesa_flux_1   = decomp19_8(s[17]);
	kpd->eesa_flux_2   = decomp19_8(s[18]);
	kpd->eesa_flux_3   = decomp19_8(s[19]);

	kpd->Pmom.time = time;
	kpd->Pmom.spin = spin;
	kpd->Pmom.cmom.c0 = s[20];    /* N * Vx  */
	kpd->Pmom.cmom.c1 = s[21];    /*  Vx     */
	kpd->Pmom.cmom.c2 = s[22];    /*  Vy/Vx  */
	kpd->Pmom.cmom.c3 = s[23];    /*  Vz/Vx  */
	kpd->Pmom.cmom.c4 = 0;        /*  not provided with key parameters */
	kpd->Pmom.cmom.c5 = 0;        /*  not provided with key parameters */
	kpd->Pmom.cmom.c6 = 0;        /*  not provided with key parameters */
	kpd->Pmom.cmom.c7 = s[24];    /*  Px/N   */
	kpd->Pmom.cmom.c8 = s[25];    /*  Py/N   */
	kpd->Pmom.cmom.c9 = s[26];    /*  Pz/N   */
	kpd->Pmom.E_s = s[27];
	kpd->Pmom.ps  = s[28];

	kpd->Pmom.dist.charge = 1;
	kpd->Pmom.dist.mass = MASS_P;
	calc_pmom_param(&kpd->Pmom,pcfg);  /* calculate physical quantities */
	
	kpd->pesa_flux_0  = decomp19_8(s[29]);
	kpd->pesa_flux_1  = decomp19_8(s[30]);
	kpd->pesa_flux_2  = decomp19_8(s[31]);
	kpd->pesa_flux_3  = decomp19_8(s[32]);
	return(1);
}


