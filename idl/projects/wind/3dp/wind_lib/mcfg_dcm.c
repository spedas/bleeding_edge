#include "mcfg_dcm.h"

#include "mem_dcm.h"




#define NULLNV ((nvector)0)



uchar current_main_config_data[]= {
0x84,0x80,0x2e,0x00,0x02,0xd0,0xf7,0xd0,0xf0,0xd0,0xf6,0xd0,0x58,0xd1,0x1d,0xd9,
0x00,0x00,0x0c,0x7e,0x5e,0xd1,0x3f,0x3f,0xf4,0xd1,0x3f,0x00,0x71,0xc7,0x00,0x00,
0x00,0x00,0x00,0x00,0x07,0x08,0x07,0x07,0x08,0x08,0x07,0x07,0x05,0x05,0x08,0x08,
0x08,0x09,0x66,0x00,0x00,0x03,0x06,0x0a,0xff,0x00,0xfb,0xff,0x7e,0x02,0xc1,0x02,
0x00,0xf2,0x19,0xf2,0x32,0xf2,0xa0,0xf2,0x8f,0xf2,0x7e,0xf2,0x6d,0xf2,0x5c,0xf2,
0x4b,0xf2,0xb8,0xf1,0xc4,0xf1,0x8c,0xf1,0x8c,0xc8,0x9c,0xf1,0xc6,0xf2,0x07,0x08,
0x07,0x00,0x08,0x08,0x07,0x07,0x05,0x05,0x08,0x08,0x08,0x09,0x66,0x00 
};

/*  #define MCONFIG_SIZE sizeof(current_main_config_data)  */





int decom_mconfig(packet *pk,Mconfig *mcfg)
{
	uchar *u;
	uint2 crc0=96;
	int i;

	if(pk==0){
		u = current_main_config_data;  /* default configuration */
		mcfg->valid = 0;
	}
	else{
		u = pk->data;
		mcfg->valid =1;
	}

	mcfg->time = pk->time;

	mcfg->sst_mode_cmnd = u[0x1f];
	mcfg->sst_tst_cmnd = u[0x20];
	mcfg->sst_t_lut = u[0x21];
	mcfg->sst_o_lut = u[0x22];
	mcfg->sst_f_lut = u[0x23];
	mcfg->sst_thrf1 = u[0x24]+u[0x34];
	mcfg->sst_thrf5 = u[0x25]+u[0x34];
	mcfg->sst_thrf4 = u[0x26]+u[0x34];
	mcfg->sst_thrf3 = u[0x27]+u[0x34];
	mcfg->sst_thro1 = u[0x28]+u[0x34];
	mcfg->sst_thro5 = u[0x29]+u[0x34];
	mcfg->sst_thro4 = u[0x2a]+u[0x34];
	mcfg->sst_thro3 = u[0x2b]+u[0x34];
	mcfg->sst_thrf2 = u[0x2c]+u[0x34];
	mcfg->sst_thrf6 = u[0x2d]+u[0x34];
	mcfg->sst_thro2 = u[0x2e]+u[0x34];
	mcfg->sst_thro6 = u[0x2f]+u[0x34];
	mcfg->sst_thrt2 = u[0x30]+u[0x34];
	mcfg->sst_thrt6 = u[0x31]+u[0x34];
	mcfg->sst_hvref = u[0x32];
	mcfg->sst_tg_ref = u[0x33];
	mcfg->inst_crc = str_to_uint2(u + 0x5c);
	
	for(i=0;i<0x5c;i+=2)
		crc0 += str_to_uint2(u + i);

	if(mcfg->inst_crc == crc0)
			mcfg->valid = 1;
	else {
		mcfg->valid = 0;
		printf("SST Config Checksum Error at %s: expected %x: received %x\r\n",
			time_to_YMDHMS(pk->time),crc0,mcfg->inst_crc);
	}
	return(1);  
}

int4 mcfg_to_idl(int argc,void *argv[])
{
        mcfg_data *mcfg;
        Mconfig mc;
        int4 size,advance,index,*options,ok,i;
        double *time;
        static packet_selector pks;
        pklist *pkl;
        packet *pk;

        if(argc == 0)
                return( number_of_packets(M_CFG_ID, 0.,1e12) );
        if(argc != 3 && argc !=2){
                printf("Incorrect number of arguments\r\n");
                return(0);
        }
        options = (int4 *)argv[0];
        time = (double *)argv[1];
        mcfg = (mcfg_data *)argv[2];
        

        size =  options[0];
        advance = options[1];
        index   = options[2];

        if(argc ==2){
            ok = get_time_points(M_CFG_ID,size,time);
            return(ok);
        }

        if(size != sizeof(mcfg_data)){
            printf("Incorrect structure size %d (should be %d).  Aborting.\r\n",size,sizeof(mcfg_data));
            return(0);
        }
	
        if (advance ) {
            SET_PKS_BY_INDEX(pks,pks.index+advance,M_CFG_ID) ;
        }
        else if (index < 0) {    /* negative index means get by time*/
            SET_PKS_BY_LASTT(pks,time[0],M_CFG_ID) ;
        }
        else {
            SET_PKS_BY_INDEX(pks,index,M_CFG_ID) ;
        }
	
	pk = get_packet(&pks);
	mcfg->time = pk->time;
	mcfg->index = pks.index;
	
	for (i=0; i<92; i++)
		mcfg->data[i] = pk->data[i];
	
	decom_mconfig(pk,&mc);
	
	mcfg->valid = mc.valid;

        return(1);

}

