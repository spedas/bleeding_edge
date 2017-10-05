#include "fpc_dcm.h"
#include "brst_dcm.h"
#include "eesa_cfg.h"
#include "windmisc.h"

#include "string.h"    /*  (needed for memset)  */

int fpc_clear(fpc_xcorr_str *fpc)
{
	memset(fpc,0,sizeof(fpc_xcorr_str));
	return(0);
}


#if 1
#define dcm12(x) decomp12(x)
#define sdcm12(x) signdecomp12(x)
#else
#define dcm12(x) (x)
#define sdcm12(x) ((schar)x)
#endif

int fpc_xcorr_decom(packet *pk,fpc_xcorr_str *fpc)
{
    int swpnum;  /*   ranges 0 - 7    2 sweeps per packet */
    int startsweep;
    double spinperiod;
    uchar *d;
    int i,c,e,sample;
    ECFG *ecfg;
    packet pkt;  /* decompressed packet */

    if(fpc->spin != pk->spin)
        fpc_clear(fpc);

    decompress_burst_packet(&pkt,pk);
    pk = &pkt;

    fpc->time   = pk->time;
    fpc->E_step = pk->instseq >> 8;
    ecfg = get_ECFG(pk->time);
    spinperiod = ecfg->spin_period;
    fpc->spinperiod = spinperiod;
    swpnum      = (pk->instseq & 0x03u)  << 1;
    startsweep  = (pk->instseq & 0xffu)  >> 2;
    fpc->spin = pk->spin;
    fpc->E_step = pk->instseq >> 8;
    d = pk->data;
    fpc->Bq_th = *d++;
    fpc->Bq_ph = *d++;
    if(fpc->time >= 8.0935316e+08) fpc->code = *d++; else fpc->code = 255;

    sample = swpnum * 16;
    for(i=0;i<2;i++,swpnum++){
        fpc->valid |= 1<<swpnum;
        fpc->flags[swpnum] = 1;
        fpc->time_total[swpnum] = str_to_uint2(d);
        d+=2;
	for(e=0;e<16;e++){
	    if ( e != 0 ) {
		fpc->sample_time[sample] 
		    = ((startsweep+swpnum)*(16+e-1))* spinperiod/32./16.;
		for(c = 3;c>=0;c--){
		    fpc->total[c][sample] = dcm12(*d++);
		    fpc->sin_c[c][sample] = sdcm12(*d++);
		    fpc->cos_c[c][sample] = sdcm12(*d++);
		}
		fpc->freq[sample] = (*d++);
		fpc->sint[sample] = sdcm12(*d++);
		fpc->cost[sample] = sdcm12(*d++);
		fpc->wave_power[sample] = (*d++);
		sample++;
	    }
	    else {
		fpc->sample_time[sample] = NaN;
		for(c = 3;c>=0;c--){
		    fpc->total[c][sample] = NaN;
		    fpc->sin_c[c][sample] = NaN;
		    fpc->cos_c[c][sample] = NaN;
		}
		fpc->freq[sample] = NaN;
		fpc->sint[sample] = NaN;
		fpc->cost[sample] = NaN;
		fpc->wave_power[sample] = NaN;
		sample++;
	    }
	}
    }

    return(1);
}

#if 0

int fpc_slice_decom(packet *pk,fpc_slice_str *fpc)
{
    
}
#endif




int fpc_dump_decom(packet *pk,fpc_dump_str *fpc)
{
    uchar *d;
    int c,e;
    packet pkt;

    decompress_burst_packet(&pkt,pk);
    pk = &pkt;

    fpc->time = pk->time;
    fpc->spin = pk->spin;
    fpc->sweepnum = ((pk->instseq & 0xfcu) >> 1) + (pk->instseq  & 0x01);
    fpc->burstnum = pk->idtype & 0x0f;
    fpc->channel  = (pk->instseq ) >> 8;
    d = pk->data;
    for(c=0;c<3;c++)
        fpc->code[c] = *d++;
    for(e=0;e<15;e++)
        for(c=0;c<16;c++){
            fpc->counters[c][e] = str_to_uint2(d);
            d+=2;
        }
    return(1);
}



#if 1

int get_next_fpc(packet_selector *pks,fpc_xcorr_str *fpc)
{
    static int4 spin=-1;
    static packet *pk ;
    int ok;

    fpc->valid = 0;

    pk = get_packet(pks);
    while(fpc->valid != 0xff){
        if(pk==0)
            return(0);
	if(pk->quality & (~pkquality)){
	    fpc->time = pk->time;
	    return(0);
	}
        ok = fpc_xcorr_decom(pk,fpc);
        pk = pk->next;
    }
    fpc->index = pks->index;
    return( 1 );
}

#endif





#define SINAMAX 88
void init_def_table(uint2 *tbl,int *a,int n)  /* this produces an array of deflector ratios */
{
	register schar i,s;
	long r;
	for(s=0;s<SINAMAX;s++){
		r = 0;
		i = n;
		while(i){
			r = (( r + a[i]) * s) >> 6;
			i--;
		}
		tbl[s] = r + a[0];
	}	
}

#define NUM_DEF_STEPS  (10*16/2)
#if 0

void calc_def_sweep()  /*  This gives the up deflector sweeping down followed by   */
{                  /*  the down deflector sweeping up in voltage */
	register uchar phi;
	register int sina;
	register uint dac_val;

	xcomm.dfc_dac_val = 0xffff;                  /* do real deflector sweep */
	xcomm.ehc_dac_val = hdac_tbl_ptr[v.estep & 0x7f];
	if(xcomm.ehc_dac_val & 0x1000){
		err_out(" Warning! using low gain for correlator");
		v.innervolt = ((ulong)((xcomm.ehc_dac_val<<4)-scn_t.ehs2)*scn_t.ehm2 )>>19;
	}
	else
		v.innervolt = (xcomm.ehc_dac_val << 4) - scn_t.ehs1;    /* currently working for high gain only */

	v.sinth = sinb256(v.bq_th);  /* may want to multiply by scaling factor here */
	v.sinth = (27554l * v.sinth) >> 15;
	
	xcomm.c_chnl_select = corr_codes[(v.bq_th + 16)>>5];       /* change */

	for(phi=0;phi<(NUM_DEF_STEPS/2);phi++){
		sina = sinb256(phi);    /* guaranteed to be positive */
		sina = ((ulong) sina * v.sinth ) >> 23;  /* 16b unsigned x 16b unsigned ==> 16b unsigned */
		if(sina>=SINAMAX) sina=SINAMAX-1;
		     /* up deflector */
		dac_val = (((ulong) def_up_tbl_ptr[sina] * v.innervolt) >> 17) + scn.defl_up_offset;
		if(dac_val > 0x0fff)  dac_val = 0x0fff;
		if(scn.misc_bits & 0x01) dac_val |= 0x1000;
		ddac_tbl_ptr[NUM_DEF_STEPS/2-1-phi] = dac_val;
		     /* down deflector */ 
		dac_val = (((ulong) def_dn_tbl_ptr[sina] * v.innervolt) >> 17) + scn.defl_dn_offset;
		if(dac_val > 0x0fff)  dac_val = 0x0fff;
		if(!(scn.misc_bits & 0x01)) dac_val |= 0x1000;
		ddac_tbl_ptr[NUM_DEF_STEPS/2+phi] = dac_val; 
	}
}

#endif



#if 0
uchar signcomp12(int  u)   
{
	if(u<0)
		return(- (comp12( (-u) <<1 ) >> 1) );
	else
		return( comp12( u<<1 ) >> 1 );
}


#define B11 0x0800
uchar comp12(uint2 u)   /* compress 12 bit to 8 bit  */
{                 /*  please optimize for speed */
	register uchar m,e;
	if(u <= 64) return(u);
	if(u >= 4032) return(255); 
	for(e=7;!(u & B11);u<<=1,e--)
		;
	m = u >> 6;     
	m &= 0x1f;      /*  keep only 5 bits */
	e <<= 5;
	return(m+e);
}

#if MTEST
main()
{
	int a[4];
	int i;
	uint table[SINAMAX];
	while(1){
		scanf("%d %d %d %d",a,a+1,a+2,a+3);
		if(a[0] == -1) break;
		init_def_table(table,a);
		printf("`a0=%d  a1=%d  a2=%d  a3=%d \n",a[0],a[1],a[2],a[3]);
		for(i=0;i<SINAMAX;i++){
			printf("%3d %5u\n",i,table[i]);
		}
	}
}
#endif
#endif

int number_of_fpc_samples(double t1,double t2)
{
        return(number_of_packets(FPC_D_ID,t1,t2));
}

int  fpc_to_idl(int argc,void *argv[])
{
        fpc_xcorr_str *fpc_idl;
        int4 size,advance,index,*options,ok,exppk=1;
        double *time;
        static packet_selector pks;
        pklist *pkl;

        if(argc == 0)
                return( number_of_fpc_samples( 0.,1e12) );
        if(argc != 3 && argc !=2){
                printf("Incorrect number of arguments\r\n");
                return(0);
        }
        options = (int4 *)argv[0];
        time = (double *)argv[1];
        fpc_idl = (fpc_xcorr_str *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];

        if(argc ==2){
            ok = get_time_points(FPC_D_ID,size,time);
            return(ok);
        }

        if(size != sizeof(fpc_xcorr_str)){
            printf("Incorrect stucture size %d (should be %d).  Aborting.\r\n",size,sizeof(fpc_xcorr_str));
            return(0);
        }
	
        if (advance ) {
            SET_PKS_BY_INDEX(pks,pks.index+advance,FPC_D_ID) ;
        }
        else if (index < 0) {    /* negative index means get by time*/
            SET_PKS_BY_TIME(pks,time[0],FPC_D_ID) ;
        }
        else {
            SET_PKS_BY_INDEX(pks,index,FPC_D_ID) ;
        }
	
        ok = get_next_fpc(&pks, fpc_idl);
        fpc_idl->index = pks.index;

        return(ok);
}
