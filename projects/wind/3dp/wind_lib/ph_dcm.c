#include <stdlib.h>
#include <math.h>
#include "ph_dcm.h"

#define MAX_30_BINS 5
#define MAX_PH_BINS 121
#define MAX_PH_SAMPLES 1890

#if 1
static double theta[24] = {    /*   -90 < theta < 90   latitude */
  -78.7500, -56.2500, -39.3750, -28.1250,
  -19.6875, -14.0625, -8.43750, -2.81250,
   2.81250,  8.43750,  14.0625,  19.6875,
   28.1250,  39.3750,  56.2500,  78.7500,
   78.7500,  56.2500,  33.7500,  11.2500, /* back half */
  -11.2500, -33.7500, -56.2500, -78.7500};
#else
static double theta[24] = {    /*   0 < theta < 180   Co-latitude */
  168.75000, 146.25000, 129.37500, 118.12500,
  109.68750, 104.06250, 98.437500, 92.812500,
  87.187500, 81.562500, 75.937500, 70.312500,
  61.875000, 50.625000, 33.750000, 11.250000,
  168.75000, 146.25000, 123.75000, 101.25000, /* back half */
  78.750000, 56.250000, 33.750000, 11.250000};
#endif

static double dtheta[24] = {22.5,22.5,11.25,11.25,5.625,5.625,5.625,5.625,
			    5.625,5.625,5.625,5.625,11.25,11.25,22.5,22.5,
			    22.5,22.5,22.5,22.5,22.5,22.5,22.5,22.5};
static double phi[32] = {
   174.37500,  163.12500,  151.87500,  140.62500,  129.37500,  118.12500,
   106.87500,  95.625000,  84.375000,  73.125000,  61.875000,  50.625000,
   39.375000,  28.125000,  16.875000,  5.6250000, -5.6250000, -16.875000,
  -28.125000, -39.375000, -50.625000, -61.875000, -73.125000, -84.375000,
  -95.625000, -106.87500, -118.12500, -129.37500, -140.62500, -151.87500,
  -163.12500, -174.37500 };
static double dphi = 11.25;
static double domegas[24] = {
  0.014946219,  0.042563230,  0.029754132,  0.033946244,
  0.018142453,  0.018691368,  0.019060275,  0.019245620,
  0.019245620,  0.019060275,  0.018691368,  0.018142453,
  0.033946244,  0.029754132,  0.042563230,  0.014946219,
  0.014946219,  0.042563230,  0.063700375,  0.075139715, /* back half.  added by fvm */
  0.075139715,  0.063700375,  0.042563230,  0.014946219};
static float geom_area_ph[24] = {4,4,2,2,1,1,1,1,1,1,1,1,2,2,4,4,4,4,4,4,4,4,4,4};
static int tsect[32] = {0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 3, 3, 4, 5, 6, 7,
                        8, 9,10,11,12,12,13,13,14,14,14,14,15,15,15,15};

static int no_blank[32]   = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
static int all_blank[32]  = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
			     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};
static int back_blank[24] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			     1,1,1,1,1,1,1,1}; /*back half of detector blanked*/


int get_ph_mapcode_idl(int argc,void *argv[])
{
  idl_ph_pk_data idl;
  static data_map_3d map;                 
  packet_selector *pksp;
  static packet_selector pks_ph;
  uint4 id;
  static uint2 spin;                      
  packet *pk;

  idl.options = (int4   *)argv[0];  /* get input args */
  idl.time    = (double *)argv[1];
  idl.advance = (int2   *)argv[2];
  idl.mapcode = (int4   *)argv[3];
  idl.idtype  = (uint2  *)argv[4];
  idl.instseq = (uint2  *)argv[5];

  pksp = &pks_ph;    
  id = P3D_ID;

  /* negitive option[1] means get by time*/
  if     (*idl.advance)    {SET_PKS_BY_INDEX(*pksp,pksp->index+*idl.advance,id);}
  else if(idl.options[1]<0){SET_PKS_BY_TIME (*pksp,idl.time[0],id);             }
  else                     {SET_PKS_BY_INDEX(*pksp,idl.options[1],id);          }

  pk = get_packet(pksp);             
  if (pk==NULL) return(0);

  *idl.time    = pk->time;
  *idl.idtype  = pk->idtype;
  *idl.instseq = pk->instseq;

  idl.mapcode[0] = get_ph_map_code(pk);
 
  return(1);
}

int get_phb_mapcode_idl(int argc,void *argv[])
{
  idl_ph_pk_data idl;
  static data_map_3d map;                 
  packet_selector *pksp;
  static packet_selector pks_ph;
  uint4 id;
  static uint2 spin;                      
  packet *pk;

  idl.options = (int4   *)argv[0];  /* get input args */
  idl.time    = (double *)argv[1];
  idl.advance = (int2   *)argv[2];
  idl.mapcode = (int4   *)argv[3];
  idl.idtype  = (uint2  *)argv[4];
  idl.instseq = (uint2  *)argv[5];

  pksp = &pks_ph;    
  id = P3D_BRST_ID;

  /* negitive option[1] means get by time*/
  if     (*idl.advance)    {SET_PKS_BY_INDEX(*pksp,pksp->index+*idl.advance,id);}
  else if(idl.options[1]<0){SET_PKS_BY_TIME (*pksp,idl.time[0],id);             }
  else                     {SET_PKS_BY_INDEX(*pksp,idl.options[1],id);          }

  pk = get_packet(pksp);             
  if (pk==NULL) return(0);

  *idl.time    = pk->time;
  *idl.idtype  = pk->idtype;
  *idl.instseq = pk->instseq;

  idl.mapcode[0] = get_ph_map_code(pk); 
  return(1);
}

int get_next_ph5_struct(packet_selector *pks, idl_ph5 *dat5){

  static uint2 spin;
  packet *pk;
  pk = get_packet(pks);
  
  if(pk) spin = pk->spin;
  
  /* gather all packets of this type in this spin */
  while(pk){
    if(pk->quality & (~pkquality)){
	dat5->time = pk->time;
	return(0);
    }
    decom_map_ph5(pk,dat5);
    spin = pk->spin;
    if (!pk->next || spin != (pk->next)->spin) break ;
    pk = pk->next;
  }
  return(pk ? 1 : 0);  
}
    
int get_next_ph97_struct(packet_selector *pks, idl_ph97 *dat97)
{
  static uint2 spin;
  packet *pk;
  pk = get_packet(pks);
  
  if(pk) spin = pk->spin;
  /* gather all packets of this type in this spin */

  while(pk){
    if(pk->quality & (~pkquality)){
	dat97->time = pk->time;
	return(0);
    }
    decom_map_ph97(pk,dat97);
    spin = pk->spin;
    if (!pk->next || spin != (pk->next)->spin) break ;
    pk = pk->next;
  }
  return(pk ? 1 : 0);
}

int get_next_ph121_struct(packet_selector *pks, idl_ph121 *dat121){

  static uint2 spin;
  packet *pk;
  pk = get_packet(pks);
 
  if(pk) spin = pk->spin;
  
  /* gather all packets of this type in this spin */
  while(pk){
    if(pk->quality & (~pkquality)){
	dat121->time = pk->time;
	dat121->valid = 0;
	return(0);
    }
    decom_map_ph121(pk,dat121);
    spin = pk->spin;
    if (!pk->next || spin != (pk->next)->spin) break ;
    pk = pk->next;
  }
  return(pk ? 1 : 0);  
}

int get_next_ph56_struct(packet_selector *pks, idl_ph56 *dat56)
{
  static uint2 spin;
  packet *pk;
  pk = get_packet(pks);
  
  if(pk) spin = pk->spin;
  /* gather all packets of this type in this spin */

  while(pk){
    if(pk->quality & (~pkquality)){
	dat56->time = pk->time;
	return(0);
    }
    decom_map_ph56(pk,dat56);
    spin = pk->spin;
    if (!pk->next || spin != (pk->next)->spin) break ;
    pk = pk->next;
  }
  return(pk ? 1 : 0);
}

int get_next_ph65_struct(packet_selector *pks, idl_ph65 *dat65)
{
  static uint2 spin;
  packet *pk;
  pk = get_packet(pks);
  
  if(pk) spin = pk->spin;
  /* gather all packets of this type in this spin */

  while(pk){
    if(pk->quality & (~pkquality)){
	dat65->time = pk->time;
	return(0);
    }
    decom_map_ph65(pk,dat65);
    spin = pk->spin;
    if (!pk->next || spin != (pk->next)->spin) break ;
    pk = pk->next;
  }
  return(pk ? 1 : 0);
}

int get_next_ph88_struct(packet_selector *pks, idl_ph88 *dat88)
{
  static uint2 spin;
  packet *pk;
  pk = get_packet(pks);
  
  if(pk) spin = pk->spin;
  /* gather all packets of this type in this spin */

  while(pk){
    if(pk->quality & (~pkquality)){
	dat88->time = pk->time;
	return(0);
    }
    decom_map_ph88(pk,dat88);
    spin = pk->spin;
    if (!pk->next || spin != (pk->next)->spin) break ;
    pk = pk->next;
  }
  return(pk ? 1 : 0);
}

/* This subroutine will sort an uint array of length arraylength
   It is not the fastest way, but with typically 5 elements to sort,
   it is fairly quick */
void bubble_sort(uint array[], int arraylength){ /*modified bubble sort*/
  int i,j,swap;
  uint temp;
  for(i=arraylength-1;i>=0;--i){
    swap=0;
    for(j=0;j<i;j++){
      if(array[j]>array[j+1]){
	temp       = array[j];
	array[j]   = array[j+1];
	array[j+1] = temp;
	swap=1;
      }
    }
    if(!swap) return;
  }
  return;
}

/* This subroutine searches the ptmap for the bins in ptmap
   which have 30 energy steps. */
int find_ph_e30bins(uint ptmap[32*32],uint e30bins[MAX_30_BINS]){
  int i,e30,e30b,got_it,nfound;
  i=e30=e30b=got_it=nfound=0;

  while(nfound<MAX_30_BINS){
    /* find next e30 bin, or quit when entire array searched */
    while((ptmap[i] & 0xc000) != E30) { if(++i==24*32) break; }  
    e30b=(ptmap[i++] & 0x3fff);                 /*get the bin number*/
    if (nfound==0) {                            /*if first e30 bin*/
      e30bins[nfound++]=e30b;                     /*save the bin number*/
    } else {                                    /*else*/
      got_it=0;
      for(e30=0;e30<nfound;e30++)                 /*see if bin found already*/
	if (e30bins[e30]==e30b) got_it++;
      if(!got_it) e30bins[nfound++]=e30b;         /*if not found, save it */
    }
    if (nfound==MAX_30_BINS) break;
  }
  bubble_sort(e30bins,MAX_30_BINS);           /*sort the bin array*/
  return(nfound);
}

/* this subroutine fills the 30 energy step bin data structures
   for a (non-burst) ph map. */
int decom_map_ph5(packet *pk, idl_ph5 *map){
  int i,offset,seq;
  static int status,nsamples,npackets;
  int ndata,max_bytes_per_packet=390;
  uchar shift,*data;
  int b,b30,e,p,t;
  static BinRange bin[MAX_30_BINS]; 
  static float alldata[MAX_30_BINS*30];
  double dt,nrg[30],dnrg[30];
  static uint *ptmap, e30bins[MAX_30_BINS];
  uchar p0=28;
  static int num_phi[MAX_30_BINS];  /* moved up from next block */

  i=offset=seq=b=b30=e=p=t=shift=ndata=npackets=0;

  if(pk->spin != map->spin || status<=0){
    /* This is executed only on the first of "npackets" calls.
       It gets all of the angular and energy information, and 
       sets things such as the time and spin. */
    PCFG *pcfg;   
    static int theta_slots[32][MAX_30_BINS];
    static int phi_slots[24/*16*/][MAX_30_BINS];
    static int num_theta[MAX_30_BINS];

    /* set to NaN instead of 0 because the last bin may be turned off
       this way the data will be ignored instead of falsly represented as 0 */
    for (i=0;i<MAX_30_BINS*30;i++) alldata[i] = NaN;

    switch(map->mapcode){
    case(MAP11d):  nsamples=1890;  npackets = 5;  ptmap=ptmap_5;    break;
    case(MAP11b):  nsamples=1530;  npackets = 4;  ptmap=ptmap_11b;  break;
    default:
      printf("decom_map_ph5 (in ph_dcm.c): unknown mapcode: %d\n\r",
	     map->mapcode);
      return(0);
    }
    find_ph_e30bins(ptmap,e30bins); /*find the bins with 30 energy steps*/
                                    /*eg: for MAP11d: e30bins={0,16,35,51,120}*/
    pcfg = get_PCFG(pk->time);

    map->time        = pk->time;
    map->integ_t     = get_3d_integ_t(pk) * pcfg->spin_period;
    map->delta_t     = get_3d_delta_t(pk) * pcfg->spin_period;
    map->end_time    = map->time + map->integ_t;
    map->geom_factor = pcfg->ph_geom;
    map->spin        = pk->spin;
    /* these are set in idl
    map->mass        = 1836*5.6856591e-6;
    map->nbins       = MAX_30_BINS;
    map->nenergy     = 30; */

    dt       = map->integ_t / 32 / 32; /* nspins*spin period/nphis/nenergies */
    shift    = (pk->instseq >> 3) & 0x1f;
    map->shift = shift;
    status   = npackets;  /*decrement variable, counts packets left to gather*/

    for(i=0;i<30*4;i++){
      map->dac_code[i] = pcfg->phdac_tbl[i];
      map->volts[i]    = pcfg->ph_volts_tbl[i];
    }
    
    for(b=0;b<map->nbins;b++){  /* zero the static struct "bin" */
      bin[b].ne      = 0;       /* and a few other binning aids */
      bin[b].offset  = 0;
      bin[b].geom    = 0.;
      bin[b].theta   = 0.;
      bin[b].dtheta  = 0.;
      bin[b].dphi    = 0.;
      bin[b].domega  = 0;
      num_theta  [b] = 0;
      num_phi    [b] = 0;
      map->domega[b] = 0.;
      for(e=0;e<map->nenergy;e++){
        map->dtheta[b][e] = 0.;
        map->dphi  [b][e] = 0.;
	map->nrg  [b][e] = 0.;
	map->dnrg [b][e] = 0.;
	map->theta[b][e] = 0.;
	map->phi  [b][e] = 0.;
	map->flux [b][e] = 0.;
	map->gf   [b][e] = 0.;
	map->dt   [b][e] = 0.;
      }
      for (e=0; e<30; e++) bin[b].phi[e]     = 0.;
      for (p=0; p<32; p++) theta_slots[p][b] = 0;
      for (t=0; t<24; t++) phi_slots[t][b]   = 0;
    }
    
    for(p=0;p<32;p++){
      for(t=0;t<24;t++){
	
	b = ptmap[t*32+p];        /* get the bin number for a phi/theta pair */
	if ((b & 0xc000) != E30) continue;     /*we only want high res. bins */
	b &= 0x3fff;                       /* chop off the energy steps info */
	
	b30=0;
	while (b30<MAX_30_BINS)        /* find b30 such that b==e30bins[b30] */
	  if (b==e30bins[b30]) break; else b30++;

	if(b30 > map->nbins){                     
	  fprintf(stderr,"3D bin error\n\r");
	  return(0);
	}

	bin[b30].ne=30;

	/*if(t<16){*/
	bin[b30].phi[0]     += phi[p];
	bin[b30].theta      += theta[t] * dtheta[t];
	bin[b30].dphi       += dphi;
	bin[b30].dtheta     += dtheta[t];
	bin[b30].domega     += domegas[t];
	bin[b30].offset     += 1;
	theta_slots[p][b30] += 1;
	phi_slots[t][b30]   += 1;
	/*}*/
	bin[b30].geom       += geom_area_ph[t];
      }
    }
    for(b=0;b<map->nbins;b++){
      float phi0 = bin[b].phi[0];
      for (p=0; p<32; p++)
	if (num_theta[b] < theta_slots[p][b])
	  num_theta[b] = theta_slots[p][b];
      for (t=0; t<24/*16*/; t++)
	if (num_phi[b] < phi_slots[t][b])
	  num_phi[b] = phi_slots[t][b];
      if(bin[b].offset ==0){
	/*fprintf(stderr,"Invalid bin #%d\n\r",b); */
	continue;
      }
      /*printf("bin[%1d].offset: %4d\n\r",b,bin[b].offset);*/
      bin[b].theta /= bin[b].dtheta;
      phi0   /= bin[b].offset;
      phi0   += ((float)shift + (float)p0) * 360./32.;
      if(phi0 < 0.)
	phi0 +=360.;
      if(phi0 >= 360.)
	phi0 -=360.;
      bin[b].dtheta /= num_phi[b];
      bin[b].dphi   /= num_theta[b];
      bin[b].geom   /= num_phi[b];    
      
      /* build up phi across energy bins */
      for (e=0; e<bin[b].ne; e++)
	bin[b].phi[e] = phi0 +	(.5 - (e+.5)/bin[b].ne)*dphi;
    }
 
/* this may need fixing.  the question is do i make it compatible with
   maps that have ne=0 bins?  that would add another subroutine or make
   this block considerably larger.  currently, no ph maps have bins with ne=0*/
    /* the following solution is not compatible with ne=0 bins in ptmap*/
    offset=0;
    for(b=0;b<map->nbins;b++){
      if (b==0) bin[b].offset=e30bins[0]*15;
      else      bin[b].offset=bin[b-1].offset+(e30bins[b]-e30bins[b-1]-1)*15+30;
    }

    get_esteps_ph(nrg,map->nenergy,MIDDLE,pcfg);
    get_esteps_ph(dnrg,map->nenergy,WIDTH,pcfg);

  }

  seq    = pk->instseq & 0x07;
  ndata  = max_bytes_per_packet;
  offset = seq * ndata;
  if (ndata>(int)pk->dsize) ndata = pk->dsize;
  data   = pk->data;


  for(b=0;b<map->nbins;b++){
    if(bin[b].offset <  offset)          continue;  /*data is in earlier pk*/
    if(bin[b].offset >  ndata+offset-30) break;     /*data is in later   pk*/
    if(bin[b].offset >  nsamples-30){               /*offset too large     */
      char instStr[12]="PESA HIGH";
      fprintf(stderr,"3D binning error: offset(%d) >= nsamples(%d)\n\r",
	      bin[b].offset+30,nsamples);
      fprintf(stderr,"    ndata: %d, map type: %s\n\r", ndata, instStr);
    } else {
      for(e=0;e<30;e++) 
	alldata[b*30+e]=decomp19_8(*(data+bin[b].offset-offset+e));
    }
  }
  status--;
  
  if(status == 0){   /* if all packets received, fill the data structure */
    for(b=0;b<map->nbins;b++){
      map->domega[b] = bin[b].domega;
      for(e=0;e<map->nenergy;e++){
        map->dtheta[b][e] = bin[b].dtheta;
        map->dphi  [b][e] = bin[b].dphi;
	map->nrg  [b][e] = nrg[e];
	map->dnrg [b][e] = dnrg[e];
	map->theta[b][e] = bin[b].theta;
	map->phi  [b][e] = bin[b].phi[e];
	map->gf   [b][e] = bin[b].geom;
	map->dt   [b][e] = num_phi[b] * dt;
	map->flux [b][e] = alldata[b*30+e];
	/*printf("bin: %d: e: %d, ne: %d, offset: %d, data: %f\n\r",
	       b,e,bin[b].ne,b*30+e,alldata[b*30+e]);*/
      }
    }

    map->valid=1;
  }
  return(1);  
}

/* This subroutine gets the angular information for the low res data structures
   for decom_map_ph{97,121} (others may be added with minimal effort) */
int make_ph_ptmap(PCFG *pcfg,uchar shift,int4 mapcode,int num_phi[MAX_PH_BINS],
		 uint ptmap[32*32],BinRange bin[]){
  int b,e,offset,ne,p,t,nsamples,nbins;
  int *t_blank, *p_blank;
  static int first_call=1;
  uint *local_ptmap,ps=0;
  uchar p0=28;
  static int theta_slots[32][MAX_PH_BINS],phi_slots[16][MAX_PH_BINS];
  static int num_theta[MAX_PH_BINS];
  /*static int num_phi[MAX_PH_BINS]; made into function argument,
    used by calling functions*/
  
  static struct {     /* if any of these value change, must recalculate map */
    uchar   shift;                      /* shift between p and phi in ptmap */
    int4    mapcode;                                            /* data map */
    nvector esa_swp_select;                        /* ummm, not really sure */
    uint2   select_sector;                                         /* ditto */
    uchar   esa_pha_basech;                                        /* ditto */
    nvector bts_c_val;                                             /* ditto */
  } prev_mapinfo, mapinfo;            /* intial values are bogus */

  mapinfo.shift          = shift;
  mapinfo.mapcode        = mapcode;
  mapinfo.esa_swp_select = pcfg->norm_cfg.esa_swp_select;
  mapinfo.select_sector  = pcfg->norm_cfg.select_sector; 
  mapinfo.esa_pha_basech = pcfg->norm_cfg.esa_pha_basech;
  mapinfo.bts_c_val      = pcfg->norm_cfg.bts_c_val;
	    
/*What are the nec. and suf. conditions such that all of 
  the angular info will be the same this time as last call?
  0: make_ph_ptmap                   must not be first call to make_ph_ptmap
  1: mapcode                         must be the same
  2: shift                           must be the same 
  4: pk->time and last_ph_time are on different sides of PH_BACK_OFF_TIME */
	
  if (!first_call) 
    if (memcmp(&prev_mapinfo,&mapinfo,sizeof(mapinfo))==0)
      return(1);  /* packet info is the same. use old angular info */
  
  first_call=0;

  switch (mapinfo.bts_c_val >> 14) {
  case 3:
    t_blank = no_blank;
    p_blank = no_blank;
    break;
  case 2:
    t_blank = back_blank;  /* blank all phis/theta pairs */
    p_blank = all_blank;   /* with back facing thetas */
    break;
  default:
    printf("make_ph_ptmap: bts_c_val unknown: %x\r\n",mapinfo.bts_c_val);
    return(0);
  }
	

  switch(mapcode){
  case(MAP11d): nbins=121;  nsamples=1890;  local_ptmap=ptmap_5;    break;
  case(MAP11b): nbins= 97;  nsamples=1530;  local_ptmap=ptmap_11b;  break;
  case(MAP_8):  nbins= 56;  nsamples= 960;  local_ptmap=ptmap_8;    break;
  case(MAP_0):  nbins= 65;  nsamples=1050;  local_ptmap=ptmap_0;    break;
  case(MAP22d): nbins= 88;  nsamples=1380;  local_ptmap=ptmap_22d;   break;
  default:
    printf("make_ph_ptmap: map index unknown: %d\n",mapcode);
    return(0);
  }
  
  for(b=0;b<nbins;b++){  /* zero the static struct "bin" */
    bin[b].ne      = 0;       /* and a few other binning aids */
    bin[b].offset  = 0;
    bin[b].geom    = 0.;
    bin[b].theta   = 0.;
    bin[b].dtheta  = 0.;
    bin[b].dphi    = 0.;
    bin[b].domega  = 0;
    num_theta  [b] = 0;
    num_phi    [b] = 0;
    for (e=0; e<30; e++) bin[b].phi[e]     = 0.;
    for (p=0; p<32; p++) theta_slots[p][b] = 0;
    for (t=0; t<16; t++) phi_slots  [t][b] = 0;
  }
  
  for(p=0;p<32;p++){
    for(t=0;t<24;t++){
      b = local_ptmap[t*32+p]; /*get the bin number for a phi/theta pair*/

      switch (b & 0xc000) {    /*get the # of energy steps for this bin */ 
      case E30:  ne = 30;  break;
      case E0:   ne =  0;  break;
      default:   ne = 15;  break;
      }
      
      b &= 0x3fff;           /* chop off the energy steps info */
      
      if(b > nbins && ne ){  /* check order of operations */
	fprintf(stderr,"3D bin error\n\r");
	return(0);
      }
      
      ps = (p - shift) & 0x1f;
      ptmap[t*32+ps] = (ne == 0) ? -1 : b;
      if(ne == 0)
	continue;
      if (b < nbins ) bin[b].ne = ne;
      
      if(t<16){
	bin[b].phi[0]     += phi[p];
	bin[b].theta      += theta[t] * dtheta[t];
	bin[b].dphi       += dphi;
	bin[b].dtheta     += dtheta[t];
	bin[b].domega     += domegas[t];
	bin[b].offset     += 1;
	theta_slots[p][b] += 1;
	phi_slots[t][b]   += 1;
      }
      if(p_blank[p] & t_blank[t])
	continue;     /* skip blanked anodes */
      bin[b].geom += geom_area_ph[t];
    }
  }

  for(b=0;b<nbins;b++){
    float phi0 = bin[b].phi[0];
    for (p=0; p<32; p++)
      if (num_theta[b] < theta_slots[p][b]) num_theta[b] = theta_slots[p][b];
    for (t=0; t<16; t++)
      if (num_phi[b]   < phi_slots[t][b])   num_phi[b]   = phi_slots[t][b];
    if(bin[b].offset==0){
      /*fprintf(stderr,"Invalid bin #%d\n\r",b); */
      continue;
    }

    bin[b].theta /= bin[b].dtheta;
    phi0   /= bin[b].offset;
    phi0   += ((float)shift + (float)p0) * 360./32.;
    if(phi0 < 0.)
      phi0 +=360.;
    if(phi0 >= 360.)
      phi0 -=360.;
    bin[b].dtheta /= num_phi[b];
    bin[b].dphi   /= num_theta[b];
    bin[b].geom   /= num_phi[b];    
    /* build up phi across energy bins */
    for (e=0; e<bin[b].ne; e++)
      bin[b].phi[e] = phi0 +	(.5 - (e+.5)/bin[b].ne)*dphi;
  }

  offset = 0;
  for(b=0;b<nbins;b++){
    bin[b].offset = offset;
    offset += bin[b].ne;
  }
  if(offset != nsamples)
    fprintf(stderr,"3d Initialization error, offset: %d, nsamples: %d\n\r",
	    offset, nsamples);
  
  memcpy(&prev_mapinfo,&mapinfo,sizeof(mapinfo));
  return(1);
}

int decom_map_ph97(packet *pk, idl_ph97 *map){
  int b,e,i,p,t;
  int seq,offset,ndata,nsamples,npackets,max_bytes_per_packet=390;
  static int status, double_sweep, num_phi[MAX_PH_BINS];
  static float alldata[1530];
  double dt,nrg[15],dnrg[15];
  uint    ps=0;
  static  uint ptmap[32*32];
  static BinRange bin[97]; 
  uchar *data,shift,p0=28;
  float flux,n0,phi;
  packet dpk;

  i=offset=seq=b=e=p=t=flux=ndata=npackets=0;
  nsamples=1530;

  decompress_burst_packet(&dpk,pk);
  pk = &dpk;

  if(pk->spin != map->spin || status<=0){
    /* This is executed only on the first of "npackets" calls.
       It gets all of the angular and energy information, and 
       sets things such as the time and spin. */
    PCFG *pcfg;   

    for (i=0;i<nsamples;i++) alldata[i]=0.;

    pcfg = get_PCFG(pk->time);

    if((pcfg->norm_cfg.esa_swp_select==0x7780) &&    
       (pcfg->norm_cfg.select_sector ==0x0343)  &&
       (pcfg->norm_cfg.esa_pha_basech==0x0040)){
      double_sweep=1;
      /* this marks the weird double sweep of the top half energy channels */
    } else {
      double_sweep=0;
    }

#ifdef PH_DEBUG
    printf("esa_swp_select: %04x\n\r",pcfg->norm_cfg.esa_swp_select);
    printf("select_sector : %04x\n\r",pcfg->norm_cfg.select_sector );
    printf("esa_pha_basech: %04x\n\r",pcfg->norm_cfg.esa_pha_basech);
    printf("bts_c_val     : %04x\n\r",pcfg->norm_cfg.bts_c_val);
    printf("double_sweep  : %4d\n\r",double_sweep);
#endif

    map->time        = pk->time;
    /* get_3d_integ_t(pk): number of summed spins */
    map->integ_t     = get_3d_integ_t(pk) * pcfg->spin_period;
    map->delta_t     = get_3d_delta_t(pk) * pcfg->spin_period;
    map->end_time    = map->time + map->integ_t;
    map->geom_factor = pcfg->ph_geom;
    map->double_sweep = (uchar) double_sweep;
    map->spin        = pk->spin;
    /* these are set in idl
    map->mass        = 1836*5.6856591e-6;
    map->nbins       = 97;
    map->nenergy     = 15; */

    dt       = map->integ_t / 32 / 16; /* nspins*spin period/nphis/nenergies */
    shift    = (pk->instseq >> 3) & 0x1f;
    map->shift = shift;
    npackets = 4;   
    status   = npackets;  /*decrement variable, counts packets left to gather*/
      
    for(i=0;i<30*4;i++){
      map->dac_code[i] = pcfg->phdac_tbl[i];
      map->volts[i]    = pcfg->ph_volts_tbl[i]; 
    }
    
    make_ph_ptmap(pcfg,shift,map->mapcode,num_phi,ptmap,bin);

    for(b=0;b<map->nbins;b++){  /* initalize data structure */
      map->domega[b] = 0.;
      for(e=0;e<map->nenergy;e++){
	map->nrg  [b][e] = 0.;
	map->dnrg [b][e] = 0.;
	map->theta[b][e] = 0.;
	map->phi  [b][e] = 0.;
	map->dtheta[b][e] = 0.;
        map->dphi  [b][e] = 0.;
	map->flux [b][e] = 0.;
	map->gf   [b][e] = 0.;
	map->dt   [b][e] = 0.;
      }
    }
    
    get_esteps_ph(nrg,map->nenergy,MIDDLE,pcfg);
    get_esteps_ph(dnrg,map->nenergy,WIDTH,pcfg);

  }

  /* this is the *start* of the section executed on each call */
  seq    = pk->instseq & 0x07;
  ndata  = max_bytes_per_packet;
  offset = seq * ndata;
  if (ndata>(int)pk->dsize) ndata = pk->dsize;
  data   = pk->data;

  for(i=0;i<ndata;i++){
    /*if(offset >= nsamples){ */
      if(offset >= (nsamples + 5))  {   /*The previous line should work */
      char instStr[12];
      strcpy (instStr, "PESA HIGH");
      fprintf(stderr,"3D binning error: offset(%d) >= nsamples(%d)\n\r",
	      offset, nsamples);
      fprintf(stderr,"    ndata: %d, map type: %s\n\r", ndata, instStr);
    } else {
      if(offset < nsamples)
	alldata[offset++] = decomp19_8(*data++);
    }
  }
  status--;
  /* this is the **end** of the section executed on each call */
  
  if (status == 0) {   /* if all packets received, fill the data structure */

    uint ts=0;
    for(t=0;t<32;t++){ /* fill the phi-theta map */
      ts = tsect[t];
      for(p=0;p<32;p++){
        if(t<24)
        	map->pt_map[t*32+p] = ptmap[t*32+p];
	b = ptmap[ts*32+p];
	ps = (p - p0) & 0x1f;
	if (b > 97) 
	  printf("invalid map entry: t: %d, p: %d, ts: %d, ps: %d, t*32+ps: %d, b: %d\n\r",
		 t,p,ts,ps,t*32+ps,b);
      }
    }
    
    for(b=0;b<map->nbins;b++){
      offset         = bin[b].offset;
      map->domega[b] = bin[b].domega;
      for(e=0;e<map->nenergy;e++){
	map->nrg  [b][e] = nrg[e];
	map->dnrg [b][e] = dnrg[e];
	map->theta[b][e] = bin[b].theta;
	map->phi  [b][e] = bin[b].phi[e];
        map->dtheta[b][e] = bin[b].dtheta;
        map->dphi  [b][e] = bin[b].dphi;
	map->gf   [b][e] = bin[b].geom;
	map->dt   [b][e] = num_phi[b] * dt;
	map->dvolume[b][e] = dnrg[e]/nrg[e]*map->domega[b];
	if (map->nenergy==bin[b].ne) {
	  flux  = alldata[offset+e];
	  phi 	= bin[b].phi[e];
	} else if (map->nenergy==bin[b].ne/2) {
	  flux  = alldata[offset+2*e];
	  flux += alldata[offset+2*e+1];
	  phi	= bin[b].phi[2*e];
	  phi  += bin[b].phi[2*e+1];
	  phi	= phi/2.;
	} else {
	  flux  = 0;
	  /*printf("bin: %d: energy steps=%d, should be %d or %d\n\r",
		 b,bin[b].ne,map->nenergy,2*map->nenergy);*/
	}
	map->flux[b][e]  = flux;
	map->phi[b][e] = phi;
      }
    }

    if(double_sweep){
      int dsbins[4];
      int midbin;                       /* ramping bin between double sweeps */

      midbin=(map->nenergy-2+map->nenergy%2)/2;

      for(t=0;t<16;t++){
        dsbins[0] = ptmap[t*32+26];
        dsbins[1] = ptmap[t*32+27];
        dsbins[2] = ptmap[t*32+28];
        dsbins[3] = ptmap[t*32+29];
        if((dsbins[0] == dsbins[1]) || (dsbins[1] == dsbins[3]))
          for(i=0;i<6;i++)
	  for(e=midbin;e<map->nenergy;e++) {
	    map->flux[dsbins[1]][e] = NaN;        /* blank corrupted bins */
	    map->bins[dsbins[1]][e] = 0;
	  }
	else
	  for(i=0;i<16;i++){
	    map->nrg[dsbins[1]][midbin] = NaN;
	    map->dnrg[dsbins[1]][midbin] = NaN;
	    map->bins[dsbins[1]][midbin] = 0;
	    for(e=midbin+1;e<map->nenergy;e++){ /*e=7or14;e<15or30*/
	      map->nrg [dsbins[1]][e] = map->nrg [dsbins[1]][e-midbin-1]; /*fix  e */
	      map->dnrg[dsbins[1]][e] = map->dnrg[dsbins[1]][e-midbin-1]; /*fix de */
	    }
	  }
        if(dsbins[1] != dsbins[2]) {
          if((dsbins[0] == dsbins[2]) || (dsbins[2] == dsbins[3]))
            for(i=0;i<6;i++)
  	    for(e=midbin;e<map->nenergy;e++) {
	      map->flux[dsbins[2]][e] = NaN;        /* blank corrupted bins */
	      map->bins[dsbins[2]][e] = 0;
	    }
	  else
	    for(i=0;i<16;i++){
	      map->nrg[dsbins[2]][midbin] = NaN;
	      map->dnrg[dsbins[2]][midbin] = NaN;
	      map->bins[dsbins[2]][midbin] = 0;
	      for(e=midbin+1;e<map->nenergy;e++){ /*e=7or14;e<15or30*/
	        map->nrg [dsbins[2]][e] = map->nrg [dsbins[2]][e-midbin-1]; /*fix  e */
	        map->dnrg[dsbins[2]][e] = map->dnrg[dsbins[2]][e-midbin-1]; /*fix de */
	      }
	    }
	}
      }
    }
  
    map->valid=1;
  }

  return(1);  
}

int decom_map_ph121(packet *pk, idl_ph121 *map){
  int     b,e,i,p,t;
  int     seq,offset,ndata,nsamples,npackets,max_bytes_per_packet=390;
  static  int      status, double_sweep, num_phi[MAX_PH_BINS];
  static  float    alldata[1890];
  double  dt,nrg[15],dnrg[15];
  uint    ps=0;
  static  uint ptmap[32*32];
  static  BinRange bin[121]; 
  uchar  *data,shift,p0=28;
  float   flux,n0,phi;
  packet  dpk;

  i=offset=seq=b=e=p=t=flux=ndata=npackets=0;
  nsamples=1890;

  decompress_burst_packet(&dpk,pk);
  pk = &dpk;

  if(pk->spin != map->spin || status<=0){
    /* This is executed only on the first of "npackets" calls.
       It gets all of the angular and energy information, and 
       sets things such as the time and spin. */
    PCFG *pcfg;   

    for (i=0;i<nsamples;i++) alldata[i]=0.;

    pcfg = get_PCFG(pk->time);
  
    if((pcfg->norm_cfg.esa_swp_select==0x7780) &&    
       (pcfg->norm_cfg.select_sector ==0x0343)  &&
       (pcfg->norm_cfg.esa_pha_basech==0x0040)){
      double_sweep=1;
      /* this marks the weird double sweep of the top half energy channels */
    } else {
      double_sweep=0;
    }

#ifdef PH_DEBUG
    printf("esa_swp_select: %04x\n\r",pcfg->norm_cfg.esa_swp_select);
    printf("select_sector : %04x\n\r",pcfg->norm_cfg.select_sector );
    printf("esa_pha_basech: %04x\n\r",pcfg->norm_cfg.esa_pha_basech);
    printf("bts_c_val     : %04x\n\r",pcfg->norm_cfg.bts_c_val);
    printf("double_sweep  : %4d\n\r",double_sweep);
#endif 
  
    map->time        = pk->time;
    /* get_3d_integ_t(pk): number of summed spins */
    map->integ_t     = get_3d_integ_t(pk) * pcfg->spin_period;
    map->delta_t     = get_3d_delta_t(pk) * pcfg->spin_period;
    map->end_time    = map->time + map->integ_t;
    map->geom_factor = pcfg->ph_geom;
    map->double_sweep = (uchar) double_sweep;
    map->spin        = pk->spin;
    /* these are set in idl
    map->mass        = 1836*5.6856591e-6;
    map->nbins       = 121;
    map->nenergy     = 15; */

    dt       = map->integ_t / 32 / 16; /* nspins*spin period/nphis/nenergies */
    shift    = (pk->instseq >> 3) & 0x1f;
    map->shift = shift;
    npackets = 5;   
    status   = npackets; /*decrement variable, counts packets left to gather */
    
    for(i=0;i<30*4;i++){
      map->dac_code[i] = pcfg->phdac_tbl[i];
      map->volts[i]    = pcfg->ph_volts_tbl[i]; 
    }
    
    make_ph_ptmap(pcfg,shift,map->mapcode,num_phi,ptmap,bin);

    for(b=0;b<map->nbins;b++){  /* initalize data structure */ 
      map->domega[b] = 0.;
      for(e=0;e<map->nenergy;e++){
	map->nrg  [b][e] = 0.;
	map->dnrg [b][e] = 0.;
	map->theta[b][e] = 0.;
	map->phi  [b][e] = 0.;
        map->dtheta[b][e] = 0.;
        map->dphi  [b][e] = 0.;
	map->flux [b][e] = 0.;  /* Nan ? */
	map->gf   [b][e] = 0.;
	map->dt   [b][e] = 0.;
      }
    }

    get_esteps_ph(nrg,map->nenergy,MIDDLE,pcfg);
    get_esteps_ph(dnrg,map->nenergy,WIDTH,pcfg);

  }

  /* this is the *start* of the section executed on each call */
  seq    = pk->instseq & 0x07;
  ndata  = max_bytes_per_packet;
  offset = seq * ndata;
  if (ndata>(int)pk->dsize) ndata = pk->dsize;
  data   = pk->data;

  for(i=0;i<ndata;i++){
    /*if(offset >= nsamples){ */
      if(offset >= (nsamples + 5))  {   /* The previous line should work */
      char instStr[12];
      strcpy (instStr, "PESA HIGH");
      fprintf(stderr,"3D binning error: offset(%d) >= nsamples(%d)\n\r",
	      offset, nsamples);
      fprintf(stderr,"    ndata: %d, map type: %s\n\r", ndata, instStr);
    } else {
      if(offset < nsamples)
	alldata[offset++] = decomp19_8(*data++);
    }
  }
  status--;
  /* this is the **end** of the section executed on each call */
  
  if (status == 0) {   /* if all packets received, fill the data structure */

    uint ts=0;
    for(t=0;t<32;t++){ /* fill the phi-theta map */
      ts = tsect[t];
      for(p=0;p<32;p++){
        if(t<24)
        	map->pt_map[t*32+p] = ptmap[t*32+p];
	b = ptmap[ts*32+p];
	ps = (p - p0) & 0x1f;
      }
    }
    
    for(b=0;b<map->nbins;b++){
      offset         = bin[b].offset;
      map->domega[b] = bin[b].domega;
      for(e=0;e<map->nenergy;e++){
	map->nrg  [b][e] = nrg[e];
	map->dnrg [b][e] = dnrg[e];
	map->theta[b][e] = bin[b].theta;
        map->dphi  [b][e] = bin[b].dphi;
        map->dtheta[b][e] = bin[b].dtheta;
	map->gf   [b][e] = bin[b].geom;
	if(b==120)
		map->dt[b][e] = 8 * dt;
	else
		map->dt[b][e] = num_phi[b] * dt;
	map->dvolume[b][e] = dnrg[e]/nrg[e]*map->domega[b];
	if (map->nenergy==bin[b].ne) {
	  flux  = alldata[offset+e];  
	  phi 	= bin[b].phi[e];
	} else if (map->nenergy==bin[b].ne/2) {
	  flux  = alldata[offset+2*e];
	  flux += alldata[offset+2*e+1];
	  phi	= bin[b].phi[2*e];
	  phi  += bin[b].phi[2*e+1];
	  phi	= phi/2.;
	} else {
	  flux  = 0;
	  /*printf("bin: %d: energy steps=%d, should be %d or %d\n\r",
		 b,bin[b].ne,map->nenergy,2*map->nenergy);*/
	}
	map->flux[b][e]  = flux;
 	map->phi[b][e] = phi;
     }
    }

    if(double_sweep){
      int dsbins[4];
      int midbin;                       /* ramping bin between double sweeps */

      midbin=(map->nenergy-2+map->nenergy%2)/2;

      for(t=0;t<16;t++){
        dsbins[0] = ptmap[t*32+26];
        dsbins[1] = ptmap[t*32+27];
        dsbins[2] = ptmap[t*32+28];
        dsbins[3] = ptmap[t*32+29];
        if((dsbins[0] == dsbins[1]) || (dsbins[1] == dsbins[3]))
          for(i=0;i<6;i++)
	  for(e=midbin;e<map->nenergy;e++) {
	    map->flux[dsbins[1]][e] = NaN;        /* blank corrupted bins */
	    map->bins[dsbins[1]][e] = 0;        /* blank corrupted bins */
	  }
	else
	  for(i=0;i<16;i++){
	    map->nrg[dsbins[1]][midbin] = NaN;
	    map->dnrg[dsbins[1]][midbin] = NaN;
	    map->bins[dsbins[1]][midbin] = 0;        /* blank corrupted bins */
	    for(e=midbin+1;e<map->nenergy;e++){ /*e=7or14;e<15or30*/
	      map->nrg [dsbins[1]][e] = map->nrg [dsbins[1]][e-midbin-1]; /*fix  e */
	      map->dnrg[dsbins[1]][e] = map->dnrg[dsbins[1]][e-midbin-1]; /*fix de */
	    }
	  }
        if(dsbins[1] != dsbins[2]) {
          if((dsbins[0] == dsbins[2]) || (dsbins[2] == dsbins[3]))
            for(i=0;i<6;i++)
  	    for(e=midbin;e<map->nenergy;e++) {
	      map->flux[dsbins[2]][e] = NaN;        /* blank corrupted bins */
	      map->bins[dsbins[2]][e] = 0;        /* blank corrupted bins */
	    }
	  else
	    for(i=0;i<16;i++){
	      map->nrg[dsbins[2]][midbin] = NaN;
	      map->dnrg[dsbins[2]][midbin] = NaN;
	      map->bins[dsbins[2]][midbin] = 0;        /* blank corrupted bins */
	      for(e=midbin+1;e<map->nenergy;e++){ /*e=7or14;e<15or30*/
	        map->nrg [dsbins[2]][e] = map->nrg [dsbins[2]][e-midbin-1]; /*fix  e */
	        map->dnrg[dsbins[2]][e] = map->dnrg[dsbins[2]][e-midbin-1]; /*fix de */
	      }
	    }
	}
      }
    }

    map->valid=1;
  }

  return(1);  
}

int decom_map_ph56(packet *pk, idl_ph56 *map){
  int b,e,i,p,t;
  int seq,offset,ndata,nsamples,npackets,max_bytes_per_packet=390;
  static int status, double_sweep, num_phi[MAX_PH_BINS];
  static float alldata[960];
  double dt,nrg[15],dnrg[15];
  uint    ps=0;
  static  uint ptmap[32*32];
  static BinRange bin[56]; 
  uchar *data,shift,p0=28;
  float flux,n0,phi;
  packet dpk;

  i=offset=seq=b=e=p=t=flux=ndata=npackets=0;
  nsamples=960;

  decompress_burst_packet(&dpk,pk);
  pk = &dpk;

  if(pk->spin != map->spin || status<=0){
    /* This is executed only on the first of "npackets" calls.
       It gets all of the angular and energy information, and 
       sets things such as the time and spin. */
    PCFG *pcfg;   

    for (i=0;i<nsamples;i++) alldata[i]=0.;

    pcfg = get_PCFG(pk->time);

    if((pcfg->norm_cfg.esa_swp_select==0x7780) &&    
       (pcfg->norm_cfg.select_sector ==0x0343)  &&
       (pcfg->norm_cfg.esa_pha_basech==0x0040)){
      double_sweep=1;
      /* this marks the weird double sweep of the top half energy channels */
    } else {
      double_sweep=0;
    }

#ifdef PH_DEBUG
    printf("esa_swp_select: %04x\n\r",pcfg->norm_cfg.esa_swp_select);
    printf("select_sector : %04x\n\r",pcfg->norm_cfg.select_sector );
    printf("esa_pha_basech: %04x\n\r",pcfg->norm_cfg.esa_pha_basech);
    printf("bts_c_val     : %04x\n\r",pcfg->norm_cfg.bts_c_val);
    printf("double_sweep  : %4d\n\r",double_sweep);
#endif

    map->time        = pk->time;
    /* get_3d_integ_t(pk): number of summed spins */
    map->integ_t     = get_3d_integ_t(pk) * pcfg->spin_period;
    map->delta_t     = get_3d_delta_t(pk) * pcfg->spin_period;
    map->end_time    = map->time + map->integ_t;
    map->geom_factor = pcfg->ph_geom;
    map->double_sweep = (uchar) double_sweep;
    map->spin        = pk->spin;
    /* these are set in idl
    map->mass        = 1836*5.6856591e-6;
    map->nbins       = 56;
    map->nenergy     = 15; */

    dt       = map->integ_t / 32 / 16; /* nspins*spin period/nphis/nenergies */
    shift    = (pk->instseq >> 3) & 0x1f;
    map->shift = shift;
    npackets = 3;   
    status   = npackets;  /*decrement variable, counts packets left to gather*/
      
    for(i=0;i<30*4;i++){
      map->dac_code[i] = pcfg->phdac_tbl[i];
      map->volts[i]    = pcfg->ph_volts_tbl[i]; 
    }
    
    make_ph_ptmap(pcfg,shift,map->mapcode,num_phi,ptmap,bin);

    for(b=0;b<map->nbins;b++){  /* initalize data structure */
      map->domega[b] = 0.;
      for(e=0;e<map->nenergy;e++){
	map->nrg  [b][e] = 0.;
	map->dnrg [b][e] = 0.;
	map->theta[b][e] = 0.;
	map->phi  [b][e] = 0.;
        map->dtheta[b][e] = 0.;
        map->dphi  [b][e] = 0.;
	map->flux [b][e] = 0.;
	map->gf   [b][e] = 0.;
	map->dt   [b][e] = 0.;
      }
    }
    
    get_esteps_ph(nrg,map->nenergy,MIDDLE,pcfg);
    get_esteps_ph(dnrg,map->nenergy,WIDTH,pcfg);

  }

  /* this is the *start* of the section executed on each call */
  seq    = pk->instseq & 0x07;
  ndata  = max_bytes_per_packet;
  offset = seq * ndata;
  if (ndata>(int)pk->dsize) ndata = pk->dsize;
  data   = pk->data;

  for(i=0;i<ndata;i++){
    /*if(offset >= nsamples){*/
      if(offset >= (nsamples + 5))  {   /* The previous line should work */
      char instStr[12];
      strcpy (instStr, "PESA HIGH");
      fprintf(stderr,"3D binning error: offset(%d) >= nsamples(%d)\n\r",
	      offset, nsamples);
      fprintf(stderr,"    ndata: %d, map type: %s\n\r", ndata, instStr);
    } else {
      if(offset < nsamples)
	alldata[offset++] = decomp19_8(*data++);
    }
  }
  status--;
  /* this is the **end** of the section executed on each call */
  
  if (status == 0) {   /* if all packets received, fill the data structure */

    uint ts=0;
    for(t=0;t<32;t++){ /* fill the phi-theta map */
      ts = tsect[t];
      for(p=0;p<32;p++){
        if(t<24)
        	map->pt_map[t*32+p] = ptmap[t*32+p];
	b = ptmap[ts*32+p];
	ps = (p - p0) & 0x1f;
	if (b > 56) 
	  printf("invalid map entry: t: %d, p: %d, ts: %d, ps: %d, t*32+ps: %d, b: %d\n\r",
		 t,p,ts,ps,t*32+ps,b);
      }
    }
    
    for(b=0;b<map->nbins;b++){
      offset         = bin[b].offset;
      map->domega[b] = bin[b].domega;
      for(e=0;e<map->nenergy;e++){
	map->nrg  [b][e] = nrg[e];
	map->dnrg [b][e] = dnrg[e];
	map->theta[b][e] = bin[b].theta;
        map->dtheta[b][e] = bin[b].dtheta;
        map->dphi  [b][e] = bin[b].dphi;
	map->gf   [b][e] = bin[b].geom;
	map->dt   [b][e] = num_phi[b] * dt;
	map->dvolume[b][e] = dnrg[e]/nrg[e]*map->domega[b];
	if (map->nenergy==bin[b].ne) {
	  flux  = alldata[offset+e];  
	  phi 	= bin[b].phi[e];
	} else if (map->nenergy==bin[b].ne/2) {
	  flux  = alldata[offset+2*e];
	  flux += alldata[offset+2*e+1];
	  phi	= bin[b].phi[2*e];
	  phi  += bin[b].phi[2*e+1];
	  phi	= phi/2.;
	} else {
	  flux  = 0;
	  /*printf("bin: %d: energy steps=%d, should be %d or %d\n\r",
		 b,bin[b].ne,map->nenergy,2*map->nenergy);*/
	}
	map->flux[b][e]  = flux;
	map->phi[b][e] = phi;
      }
    }

    if(double_sweep){
      int dsbins[4];
      int midbin;                       /* ramping bin between double sweeps */

      midbin=(map->nenergy-2+map->nenergy%2)/2;

      for(t=0;t<16;t++){
        dsbins[0] = ptmap[t*32+26];
        dsbins[1] = ptmap[t*32+27];
        dsbins[2] = ptmap[t*32+28];
        dsbins[3] = ptmap[t*32+29];
        if((dsbins[0] == dsbins[1]) || (dsbins[1] == dsbins[3]))
          for(i=0;i<6;i++)
	  for(e=midbin;e<map->nenergy;e++) {
	    map->flux[dsbins[1]][e] = NaN;        /* blank corrupted bins */
	    map->bins[dsbins[1]][e] = 0;        /* blank corrupted bins */
	  }
	else
	  for(i=0;i<16;i++){
	    map->nrg[dsbins[1]][midbin] = NaN;
	    map->dnrg[dsbins[1]][midbin] = NaN;
	    map->bins[dsbins[1]][midbin] = 0;        /* blank corrupted bins */
	    for(e=midbin+1;e<map->nenergy;e++){ /*e=7or14;e<15or30*/
	      map->nrg [dsbins[1]][e] = map->nrg [dsbins[1]][e-midbin-1]; /*fix  e */
	      map->dnrg[dsbins[1]][e] = map->dnrg[dsbins[1]][e-midbin-1]; /*fix de */
	    }
	  }
        if(dsbins[1] != dsbins[2]) {
          if((dsbins[0] == dsbins[2]) || (dsbins[2] == dsbins[3]))
            for(i=0;i<6;i++)
  	    for(e=midbin;e<map->nenergy;e++) {
	      map->flux[dsbins[2]][e] = NaN;        /* blank corrupted bins */
	      map->bins[dsbins[2]][e] = 0;        /* blank corrupted bins */
	    }
	  else
	    for(i=0;i<16;i++){
	      map->nrg[dsbins[2]][midbin] = NaN;
	      map->dnrg[dsbins[2]][midbin] = NaN;
	      map->bins[dsbins[2]][midbin] = 0;        /* blank corrupted bins */
	      for(e=midbin+1;e<map->nenergy;e++){ /*e=7or14;e<15or30*/
	        map->nrg [dsbins[2]][e] = map->nrg [dsbins[2]][e-midbin-1]; /*fix  e */
	        map->dnrg[dsbins[2]][e] = map->dnrg[dsbins[2]][e-midbin-1]; /*fix de */
	      }
	    }
	}
      }
    }

    map->valid=1;
  }

  return(1);  
}

int decom_map_ph65(packet *pk, idl_ph65 *map){
  int b,e,i,p,t;
  int seq,offset,ndata,nsamples,npackets,max_bytes_per_packet=390;
  static int status, double_sweep, num_phi[MAX_PH_BINS];
  static float alldata[1050];
  double dt,nrg[15],dnrg[15];
  uint    ps=0;
  static  uint ptmap[32*32];
  static BinRange bin[65]; 
  uchar *data,shift,p0=28;
  float flux,n0,phi;
  packet dpk;

  i=offset=seq=b=e=p=t=flux=ndata=npackets=0;
  nsamples=1050;

  decompress_burst_packet(&dpk,pk);
  pk = &dpk;

  if(pk->spin != map->spin || status<=0){
    /* This is executed only on the first of "npackets" calls.
       It gets all of the angular and energy information, and 
       sets things such as the time and spin. */
    PCFG *pcfg;   

    for (i=0;i<nsamples;i++) alldata[i]=0.;

    pcfg = get_PCFG(pk->time);

    if((pcfg->norm_cfg.esa_swp_select==0x7780) &&    
       (pcfg->norm_cfg.select_sector ==0x0343)  &&
       (pcfg->norm_cfg.esa_pha_basech==0x0040)){
      double_sweep=1;
      /* this marks the weird double sweep of the top half energy channels */
    } else {
      double_sweep=0;
    }

#ifdef PH_DEBUG
    printf("esa_swp_select: %04x\n\r",pcfg->norm_cfg.esa_swp_select);
    printf("select_sector : %04x\n\r",pcfg->norm_cfg.select_sector );
    printf("esa_pha_basech: %04x\n\r",pcfg->norm_cfg.esa_pha_basech);
    printf("bts_c_val     : %04x\n\r",pcfg->norm_cfg.bts_c_val);
    printf("double_sweep  : %4d\n\r",double_sweep);
#endif

    map->time        = pk->time;
    /* get_3d_integ_t(pk): number of summed spins */
    map->integ_t     = get_3d_integ_t(pk) * pcfg->spin_period;
    map->delta_t     = get_3d_delta_t(pk) * pcfg->spin_period;
    map->end_time    = map->time + map->integ_t;
    map->geom_factor = pcfg->ph_geom;
    map->double_sweep = (uchar) double_sweep;
    map->spin        = pk->spin;
    /* these are set in idl
    map->mass        = 1836*5.6856591e-6;
    map->nbins       = 65;
    map->nenergy     = 15; */

    dt       = map->integ_t / 32 / 16; /* nspins*spin period/nphis/nenergies */
    shift    = (pk->instseq >> 3) & 0x1f;
    map->shift = shift;
    npackets = 3;   
    status   = npackets;  /*decrement variable, counts packets left to gather*/
      
    for(i=0;i<30*4;i++){
      map->dac_code[i] = pcfg->phdac_tbl[i];
      map->volts[i]    = pcfg->ph_volts_tbl[i]; 
    }
    
    make_ph_ptmap(pcfg,shift,map->mapcode,num_phi,ptmap,bin);

    for(b=0;b<map->nbins;b++){  /* initalize data structure */
      map->domega[b] = 0.;
      for(e=0;e<map->nenergy;e++){
	map->nrg  [b][e] = 0.;
	map->dnrg [b][e] = 0.;
	map->theta[b][e] = 0.;
	map->phi  [b][e] = 0.;
        map->dtheta[b][e] = 0.;
        map->dphi  [b][e] = 0.;
	map->flux [b][e] = 0.;
	map->gf   [b][e] = 0.;
	map->dt   [b][e] = 0.;
      }
    }
    
    get_esteps_ph(nrg,map->nenergy,MIDDLE,pcfg);
    get_esteps_ph(dnrg,map->nenergy,WIDTH,pcfg);

  }

  /* this is the *start* of the section executed on each call */
  seq    = pk->instseq & 0x07;
  ndata  = max_bytes_per_packet;
  offset = seq * ndata;
  if (ndata>(int)pk->dsize) ndata = pk->dsize;
  data   = pk->data;

  for(i=0;i<ndata;i++){
    /*if(offset >= nsamples){ */
      if(offset >= (nsamples + 5))  {   /* The previous line should work */
      char instStr[12];
      strcpy (instStr, "PESA HIGH");
      fprintf(stderr,"3D binning error: offset(%d) >= nsamples(%d)\n\r",
	      offset, nsamples);
      fprintf(stderr,"    ndata: %d, map type: %s\n\r", ndata, instStr);
    } else {
      if(offset < nsamples)
	alldata[offset++] = decomp19_8(*data++);
    }
  }
  status--;
  /* this is the **end** of the section executed on each call */
  
  if (status == 0) {   /* if all packets received, fill the data structure */

    uint ts=0;
    for(t=0;t<32;t++){ /* fill the phi-theta map */
      ts = tsect[t];
      for(p=0;p<32;p++){
        if(t<24)
        	map->pt_map[t*32+p] = ptmap[t*32+p];
	b = ptmap[ts*32+p];
	ps = (p - p0) & 0x1f;
	if (b > 65) 
	  printf("invalid map entry: t: %d, p: %d, ts: %d, ps: %d, t*32+ps: %d, b: %d\n\r",
		 t,p,ts,ps,t*32+ps,b);
      }
    }
    
    for(b=0;b<map->nbins;b++){
      offset         = bin[b].offset;
      map->domega[b] = bin[b].domega;
      for(e=0;e<map->nenergy;e++){
	map->nrg  [b][e] = nrg[e];
	map->dnrg [b][e] = dnrg[e];
	map->theta[b][e] = bin[b].theta;
        map->dtheta[b][e] = bin[b].dtheta;
        map->dphi  [b][e] = bin[b].dphi;
	map->gf   [b][e] = bin[b].geom;
	map->dt   [b][e] = num_phi[b] * dt;
	map->dvolume[b][e] = dnrg[e]/nrg[e]*map->domega[b];
	if (map->nenergy==bin[b].ne) {
	  flux  = alldata[offset+e];  
	  phi 	= bin[b].phi[e];
	} else if (map->nenergy==bin[b].ne/2) {
	  flux  = alldata[offset+2*e];
	  flux += alldata[offset+2*e+1];
	  phi	= bin[b].phi[2*e];
	  phi  += bin[b].phi[2*e+1];
	  phi	= phi/2.;
	} else {
	  flux  = 0;
	  /*printf("bin: %d: energy steps=%d, should be %d or %d\n\r",
		 b,bin[b].ne,map->nenergy,2*map->nenergy);*/
	}
	map->flux[b][e]  = flux;
	map->phi[b][e] = phi;
      }
    }

    if(double_sweep){
      int dsbins[4];
      int midbin;                       /* ramping bin between double sweeps */

      midbin=(map->nenergy-2+map->nenergy%2)/2;

      for(t=0;t<16;t++){
        dsbins[0] = ptmap[t*32+26];
        dsbins[1] = ptmap[t*32+27];
        dsbins[2] = ptmap[t*32+28];
        dsbins[3] = ptmap[t*32+29];
        if((dsbins[0] == dsbins[1]) || (dsbins[1] == dsbins[3]))
          for(i=0;i<6;i++)
	  for(e=midbin;e<map->nenergy;e++) {
	    map->flux[dsbins[1]][e] = NaN;        /* blank corrupted bins */
	    map->bins[dsbins[1]][e] = 0;        /* blank corrupted bins */
	  }
	else
	  for(i=0;i<16;i++){
	    map->nrg[dsbins[1]][midbin] = NaN;
	    map->dnrg[dsbins[1]][midbin] = NaN;
	    map->bins[dsbins[1]][midbin] = 0;        /* blank corrupted bins */
	    for(e=midbin+1;e<map->nenergy;e++){ /*e=7or14;e<15or30*/
	      map->nrg [dsbins[1]][e] = map->nrg [dsbins[1]][e-midbin-1]; /*fix  e */
	      map->dnrg[dsbins[1]][e] = map->dnrg[dsbins[1]][e-midbin-1]; /*fix de */
	    }
	  }
        if(dsbins[1] != dsbins[2]) {
          if((dsbins[0] == dsbins[2]) || (dsbins[2] == dsbins[3]))
            for(i=0;i<6;i++)
  	    for(e=midbin;e<map->nenergy;e++) {
	      map->flux[dsbins[2]][e] = NaN;        /* blank corrupted bins */
	      map->bins[dsbins[2]][e] = 0;        /* blank corrupted bins */
	    }
	  else
	    for(i=0;i<16;i++){
	      map->nrg[dsbins[2]][midbin] = NaN;
	      map->dnrg[dsbins[2]][midbin] = NaN;
	      map->bins[dsbins[2]][midbin] = 0;        /* blank corrupted bins */
	      for(e=midbin+1;e<map->nenergy;e++){ /*e=7or14;e<15or30*/
	        map->nrg [dsbins[2]][e] = map->nrg [dsbins[2]][e-midbin-1]; /*fix  e */
	        map->dnrg[dsbins[2]][e] = map->dnrg[dsbins[2]][e-midbin-1]; /*fix de */
	      }
	    }
	}
      }
    }

    map->valid=1;
  }

  return(1);  
}



int decom_map_ph88(packet *pk, idl_ph88 *map){
  int b,e,i,p,t;
  int seq,offset,ndata,nsamples,npackets,max_bytes_per_packet=390;
  static int status, double_sweep, num_phi[MAX_PH_BINS];
  static float alldata[1380];
  double dt,nrg[15],dnrg[15];
  uint    ps=0;
  static  uint ptmap[32*32];
  static BinRange bin[88]; 
  uchar *data,shift,p0=28;
  float flux,n0,phi;
  packet dpk;

  i=offset=seq=b=e=p=t=flux=ndata=npackets=0;
  nsamples=1380;		/* this and alldata may be 1470 */

  decompress_burst_packet(&dpk,pk);
  pk = &dpk;

  if(pk->spin != map->spin || status<=0){
    /* This is executed only on the first of "npackets" calls.
       It gets all of the angular and energy information, and 
       sets things such as the time and spin. */
    PCFG *pcfg;   

    for (i=0;i<nsamples;i++) alldata[i]=0.;

    pcfg = get_PCFG(pk->time);

    if((pcfg->norm_cfg.esa_swp_select==0x7780) &&    
       (pcfg->norm_cfg.select_sector ==0x0343)  &&
       (pcfg->norm_cfg.esa_pha_basech==0x0040)){
      double_sweep=1;
      /* this marks the weird double sweep of the top half energy channels */
    } else {
      double_sweep=0;
    }

#ifdef PH_DEBUG
    printf("esa_swp_select: %04x\n\r",pcfg->norm_cfg.esa_swp_select);
    printf("select_sector : %04x\n\r",pcfg->norm_cfg.select_sector );
    printf("esa_pha_basech: %04x\n\r",pcfg->norm_cfg.esa_pha_basech);
    printf("bts_c_val     : %04x\n\r",pcfg->norm_cfg.bts_c_val);
    printf("double_sweep  : %4d\n\r",double_sweep);
#endif

    map->time        = pk->time;
    /* get_3d_integ_t(pk): number of summed spins */
    map->integ_t     = get_3d_integ_t(pk) * pcfg->spin_period;
    map->delta_t     = get_3d_delta_t(pk) * pcfg->spin_period;
    map->end_time    = map->time + map->integ_t;
    map->geom_factor = pcfg->ph_geom;
    map->double_sweep = (uchar) double_sweep;
    map->spin        = pk->spin;
    /* these are set in idl
    map->mass        = 1836*5.6856591e-6;
    map->nbins       = 88;
    map->nenergy     = 15; */

    dt       = map->integ_t / 32 / 16; /* nspins*spin period/nphis/nenergies */
    shift    = (pk->instseq >> 3) & 0x1f;
    map->shift = shift;
    npackets = 4;   
    status   = npackets;  /*decrement variable, counts packets left to gather*/
      
    for(i=0;i<30*4;i++){
      map->dac_code[i] = pcfg->phdac_tbl[i];
      map->volts[i]    = pcfg->ph_volts_tbl[i]; 
    }
    
    make_ph_ptmap(pcfg,shift,map->mapcode,num_phi,ptmap,bin);

    for(b=0;b<map->nbins;b++){  /* initalize data structure */
      map->domega[b] = 0.;
      for(e=0;e<map->nenergy;e++){
	map->nrg  [b][e] = 0.;
	map->dnrg [b][e] = 0.;
	map->theta[b][e] = 0.;
	map->phi  [b][e] = 0.;
        map->dtheta[b][e] = 0.;
        map->dphi  [b][e] = 0.;
	map->flux [b][e] = 0.;
	map->gf   [b][e] = 0.;
	map->dt   [b][e] = 0.;
      }
    }
    
    get_esteps_ph(nrg,map->nenergy,MIDDLE,pcfg);
    get_esteps_ph(dnrg,map->nenergy,WIDTH,pcfg);

  }

  /* this is the *start* of the section executed on each call */
  seq    = pk->instseq & 0x07;
  ndata  = max_bytes_per_packet;
  offset = seq * ndata;
  if (ndata>(int)pk->dsize) ndata = pk->dsize;
  data   = pk->data;

  for(i=0;i<ndata;i++){
    /*if(offset >= nsamples){ */
      if(offset >= (nsamples + 5))  {   /* The previous line should work */
      char instStr[12];
      strcpy (instStr, "PESA HIGH");
      fprintf(stderr,"3D binning error: offset(%d) >= nsamples(%d)\n\r",
	      offset, nsamples);
      fprintf(stderr,"    ndata: %d, map type: %s\n\r", ndata, instStr);
    } else {
      if(offset < nsamples)
	alldata[offset++] = decomp19_8(*data++);
    }
  }
  status--;
  /* this is the **end** of the section executed on each call */
  
  if (status == 0) {   /* if all packets received, fill the data structure */

    uint ts=0;
    for(t=0;t<32;t++){ /* fill the phi-theta map */
      ts = tsect[t];
      for(p=0;p<32;p++){
        if(t<24)
        	map->pt_map[t*32+p] = ptmap[t*32+p];
	b = ptmap[ts*32+p];
	ps = (p - p0) & 0x1f;
	if (b > 87) 
	  printf("invalid map entry: t: %d, p: %d, ts: %d, ps: %d, t*32+ps: %d, b: %d\n\r",
		 t,p,ts,ps,t*32+ps,b);
      }
    }
    
    for(b=0;b<map->nbins;b++){
      offset         = bin[b].offset;
      map->domega[b] = bin[b].domega;
      for(e=0;e<map->nenergy;e++){
	map->nrg  [b][e] = nrg[e];
	map->dnrg [b][e] = dnrg[e];
	map->theta[b][e] = bin[b].theta;
        map->dtheta[b][e] = bin[b].dtheta;
        map->dphi  [b][e] = bin[b].dphi;
	map->gf   [b][e] = bin[b].geom;
	map->dt   [b][e] = num_phi[b] * dt;
	map->dvolume[b][e] = dnrg[e]/nrg[e]*map->domega[b];
	if (map->nenergy==bin[b].ne) {
	  flux  = alldata[offset+e];  
	  phi 	= bin[b].phi[e];
	} else if (map->nenergy==bin[b].ne/2) {
	  flux  = alldata[offset+2*e];
	  flux += alldata[offset+2*e+1];
	  phi	= bin[b].phi[2*e];
	  phi  += bin[b].phi[2*e+1];
	  phi	= phi/2.;
	} else {
	  flux  = 0;
	  /*printf("bin: %d: energy steps=%d, should be %d or %d\n\r",
		 b,bin[b].ne,map->nenergy,2*map->nenergy);*/
	}
	map->flux[b][e]  = flux;      }
 	map->phi[b][e] = phi;
   }

    if(double_sweep){
      int dsbins[4];
      int midbin;                       /* ramping bin between double sweeps */

      midbin=(map->nenergy-2+map->nenergy%2)/2;

      for(t=0;t<16;t++){
        dsbins[0] = ptmap[t*32+26];
        dsbins[1] = ptmap[t*32+27];
        dsbins[2] = ptmap[t*32+28];
        dsbins[3] = ptmap[t*32+29];
        if((dsbins[0] == dsbins[1]) || (dsbins[1] == dsbins[3]))
          for(i=0;i<6;i++)
	  for(e=midbin;e<map->nenergy;e++) {
	    map->flux[dsbins[1]][e] = NaN;        /* blank corrupted bins */
	    map->bins[dsbins[1]][e] = 0;        /* blank corrupted bins */
	  }
	else
	  for(i=0;i<16;i++){
	    map->nrg[dsbins[1]][midbin] = NaN;
	    map->dnrg[dsbins[1]][midbin] = NaN;
	    map->bins[dsbins[1]][midbin] = 0;        /* blank corrupted bins */
	    for(e=midbin+1;e<map->nenergy;e++){ /*e=7or14;e<15or30*/
	      map->nrg [dsbins[1]][e] = map->nrg [dsbins[1]][e-midbin-1]; /*fix  e */
	      map->dnrg[dsbins[1]][e] = map->dnrg[dsbins[1]][e-midbin-1]; /*fix de */
	    }
	  }
        if(dsbins[1] != dsbins[2]) {
          if((dsbins[0] == dsbins[2]) || (dsbins[2] == dsbins[3]))
            for(i=0;i<6;i++)
  	    for(e=midbin;e<map->nenergy;e++) {
	      map->flux[dsbins[2]][e] = NaN;        /* blank corrupted bins */
	      map->bins[dsbins[2]][e] = 0;        /* blank corrupted bins */
	    }
	  else
	    for(i=0;i<16;i++){
	      map->nrg[dsbins[2]][midbin] = NaN;
	      map->dnrg[dsbins[2]][midbin] = NaN;
	      map->bins[dsbins[2]][midbin] = 0;        /* blank corrupted bins */
	      for(e=midbin+1;e<map->nenergy;e++){ /*e=7or14;e<15or30*/
	        map->nrg [dsbins[2]][e] = map->nrg [dsbins[2]][e-midbin-1]; /*fix  e */
	        map->dnrg[dsbins[2]][e] = map->dnrg[dsbins[2]][e-midbin-1]; /*fix de */
	      }
	    }
	}
      }
    }

    map->valid=1;
  }

  return(1);  
}

int ph15_to_idl(int argc, void *argv[]){
  int4 size,advance,index,*mapcode,*options,ok=0;
  uint4 ph_size;
  double *time;
  static packet_selector pks;
  idl_ph56  *idl56;
  idl_ph65  *idl65;
  idl_ph88  *idl88;
  idl_ph97  *idl97;  
  idl_ph121 *idl121; 

  options = (int4   *)argv[0];
  time    = (double *)argv[1];
  mapcode = (int4   *)argv[2];

  size    = options[0];
  advance = options[1];
  index   = options[2];

  /* negative index means get by time*/
  if      (advance) {SET_PKS_BY_INDEX(pks,pks.index+advance,P3D_ID);}
  else if (index<0) {SET_PKS_BY_TIME (pks,time[0],P3D_ID);          } 
  else              {SET_PKS_BY_INDEX(pks,index,P3D_ID);            }
  
  switch(*mapcode){
  case MAP11d: {
    ph_size = sizeof(idl_ph121);
    if (size != ph_size) {
      printf("Incorrect input stucture size %d (should be %d).\r\n",
	     size,ph_size);
      return(0);
    }
    idl121 = (idl_ph121 *)argv[3];
    idl121->mapcode=*mapcode;
    ok = get_next_ph121_struct(&pks,idl121);
    idl121->index=pks.index;
    break; 
  }
  case MAP11b: {
    ph_size = sizeof(idl_ph97);
    if (size != ph_size) {
      printf("Incorrect input stucture size %d (should be %d).\r\n",
	     size,ph_size);
      return(0);
    }
    idl97 = (idl_ph97  *)argv[3];
    idl97->mapcode=*mapcode;
    ok = get_next_ph97_struct (&pks,idl97);
    idl97->index=pks.index;
    break;
  }
  case MAP_8: {
    ph_size = sizeof(idl_ph56);
    if (size != ph_size) {
      printf("Incorrect input stucture size %d (should be %d).\r\n",
	     size,ph_size);
      return(0);
    }
    idl56 = (idl_ph56  *)argv[3];
    idl56->mapcode=*mapcode;
    ok = get_next_ph56_struct (&pks,idl56);
    idl56->index=pks.index;
    break;
  }
  case MAP_0: {
    ph_size = sizeof(idl_ph65);
    if (size != ph_size) {
      printf("Incorrect input stucture size %d (should be %d).\r\n",
	     size,ph_size);
      return(0);
    }
    idl65 = (idl_ph65  *)argv[3];
    idl65->mapcode=*mapcode;
    ok = get_next_ph65_struct (&pks,idl65);
    idl65->index=pks.index;
    break;
  }
  case MAP22d: {
    ph_size = sizeof(idl_ph88);
    if (size != ph_size) {
      printf("Incorrect input stucture size %d (should be %d).\r\n",
	     size,ph_size);
      return(0);
    }
    idl88 = (idl_ph88  *)argv[3];
    idl88->mapcode=*mapcode;
    ok = get_next_ph88_struct (&pks,idl88);
    idl88->index=pks.index;
    break;
  }
  default:                                          
    printf("ph_dcm.c: Ph map type unknown: %d\n\r",*mapcode); /*ok=0*/
  }
  
  return(ok);
}

int ph30_to_idl(int argc, void *argv[]){ /* 30 energy steps, 5 angular bins */
  int4 size,advance,index,*mapcode,*options,ok=0;
  uint4 ph_size;
  double *time;
  static packet_selector pks;
  idl_ph5 *idl5;  

  options = (int4   *)argv[0];
  time    = (double *)argv[1];
  mapcode = (int4   *)argv[2];

  size    = options[0];
  advance = options[1];
  index   = options[2];

  /* negative index means get by time*/
  if      (advance) {SET_PKS_BY_INDEX(pks,pks.index+advance,P3D_ID);}
  else if (index<0) {SET_PKS_BY_TIME (pks,time[0],P3D_ID);          } 
  else              {SET_PKS_BY_INDEX(pks,index,P3D_ID);            }

  ph_size = sizeof(idl_ph5);
  if (size != ph_size) {
    printf("Incorrect input stucture size %d (should be %d).\r\n",
	   size,ph_size);
    return(0);
  }
  idl5 = (idl_ph5 *)argv[3];
  idl5->mapcode=*mapcode;
  ok = get_next_ph5_struct(&pks,idl5);  /* 5 angular bins, 30 energy steps */
  idl5->index=pks.index;
  
  return(ok);
}


int phb15_to_idl(int argc, void *argv[]){
  int4 size,advance,index,*mapcode,*options,ok=0;
  uint4 ph_size;
  double *time;
  static packet_selector pks;
  idl_ph56  *idl56;
  idl_ph65  *idl65;
  idl_ph88  *idl88;
  idl_ph97  *idl97;  
  idl_ph121 *idl121; 

  options = (int4   *)argv[0];
  time    = (double *)argv[1];
  mapcode = (int4   *)argv[2];

  size    = options[0];
  advance = options[1];
  index   = options[2];

  /* negative index means get by time*/
  if      (advance) {SET_PKS_BY_INDEX(pks,pks.index+advance,P3D_BRST_ID);}
  else if (index<0) {SET_PKS_BY_TIME (pks,time[0],P3D_BRST_ID);          } 
  else              {SET_PKS_BY_INDEX(pks,index,P3D_BRST_ID);            }

  switch(*mapcode){
  case MAP11d: {
    ph_size = sizeof(idl_ph121);
    if (size != ph_size) {
      printf("Incorrect input stucture size %d (should be %d).\r\n",
	     size,ph_size);
      return(0);
    }
    idl121 = (idl_ph121 *)argv[3];
    idl121->mapcode=*mapcode;
    ok = get_next_ph121_struct(&pks,idl121);
    idl121->index=pks.index;
    break; 
  }
  case MAP11b: {
    ph_size = sizeof(idl_ph97);
    if (size != ph_size) {
      printf("Incorrect input stucture size %d (should be %d).\r\n",
	     size,ph_size);
      return(0);
    }
    idl97 = (idl_ph97  *)argv[3];
    idl97->mapcode=*mapcode;
    ok = get_next_ph97_struct (&pks,idl97);
    idl97->index=pks.index;
    break;
  }
  case MAP_8: {
    ph_size = sizeof(idl_ph56);
    if (size != ph_size) {
      printf("Incorrect input stucture size %d (should be %d).\r\n",
	     size,ph_size);
      return(0);
    }
    idl56 = (idl_ph56  *)argv[3];
    idl56->mapcode=*mapcode;
    ok = get_next_ph56_struct (&pks,idl56);
    idl56->index=pks.index;
    break;
  }
  case MAP_0: {
    ph_size = sizeof(idl_ph65);
    if (size != ph_size) {
      printf("Incorrect input stucture size %d (should be %d).\r\n",
	     size,ph_size);
      return(0);
    }
    idl65 = (idl_ph65  *)argv[3];
    idl65->mapcode=*mapcode;
    ok = get_next_ph65_struct (&pks,idl65);
    idl65->index=pks.index;
    break;
  }
  case MAP22d: {
    ph_size = sizeof(idl_ph88);
    if (size != ph_size) {
      printf("Incorrect input stucture size %d (should be %d).\r\n",
	     size,ph_size);
      return(0);
    }
    idl88 = (idl_ph88  *)argv[3];
    idl88->mapcode=*mapcode;
    ok = get_next_ph88_struct (&pks,idl88);
    idl88->index=pks.index;
    break;
  }
  default:                                          
    printf("ph_dcm.c: Ph map type unknown: %d\n\r",*mapcode); /*ok=0*/
  }
  
  return(ok);
}

int4 ph15times_to_idl(int argc, void *argv[]){

  int4 size,advance,index,*mapcode,*options,ok=0;
  double *time;

  options = (int4   *)argv[0];
  time    = (double *)argv[1];

  size    = options[0];
  advance = options[1];
  index   = options[2];

  ok = get_time_points(P3D_ID,size,time);
  return(ok);
}

int4 phb15times_to_idl(int argc, void *argv[]){

  int4 size,advance,index,*mapcode,*options,ok=0;
  double *time;

  options = (int4   *)argv[0];
  time    = (double *)argv[1];

  size    = options[0];
  advance = options[1];
  index   = options[2];

  ok = get_time_points(P3D_BRST_ID,size,time);
  return(ok);
}
