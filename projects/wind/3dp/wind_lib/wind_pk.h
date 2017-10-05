#ifndef WIND_PK_H
#define WIND_PK_H

#include "winddefs.h"
#include <stdio.h>

#define NEWFORMAT 0

#if NEWFORMAT
enum PACKET_TYPES {
	INVALID_PK,
	HKP_PK,
	KPD_PK,
	FRM_INFO_PK,
	EMOM_PK,
	EHPAD_PK,
 	ESPECT_PK,      
 	PSPECT_PK,      
	FPC_D_PK,       
	FPC_P_PK,       
	CORE_D_PK,       
 	PMOM_PK,        
 	E3D_UNK_PK,     
 	E3D_CUT_PK,     
 	E3D_88_PK,      
 	P3D_PK,         
 	P3D_BRST_PK,    
 	E3D_BRST_PK,
 	PLSNAP_PK,      
 	M_MEM_PK,       
 	E_MEM_PK,       
 	P_MEM_PK,       
 	M_HKP_PK,       
 	E_A2D_PK,       
 	P_A2D_PK,       
 	R_MEM_PK,       
 	M_CFG_PK,       
 	E_CFG_PK,       
 	P_CFG_PK,       
 	M_XCFG_PK,      
 	E_XCFG_PK,      
 	P_XCFG_PK,      
 	S_RATE_PK,      
 	S_RATE1_PK,     
 	S_RS_BST_PK,    
 	S_RATE3_PK,     
 	S_TBRST_PK,     
 	S_T_DST_PK,     
 	S_HS_BST_PK,    
 	S_3D_O_PK,      
 	S_3D_F_PK,      
 	S_PAD_PK,       

 	P_PHA_PK,       
 	P_F_RATE_PK,    
 	P_BST_DMP_PK,   
 	P_SNAP_BST_PK,  
 	E_F_RATE_PK,    
 	E_PHA_PK,
 	EH_BRST_PK

};
#endif

extern int batch_print;
extern int pkquality;


/*******    STRUCTURE  Definitions     **********/

#define MAX_PACKET_SIZE 508

/***************************************************************************
This structure provides all the necessary data from one packet of data.
Packets are stored as linked lists, so that pointers to previous and following
packets are included.
*****************************************************************************/
struct  packet_def  {
	double time;                 /* unique packet time */
	uint2 spin;                  /* spin number */
	uint2 dsize;                 /* size of data (without header) */ 
	uint2 idtype;                /* id/type */
	uint2 instseq;               /* inst/seq  */
	uint2 errors;                /* potential errors (see frame_dcm.h) */
	uint2 quality;		     /* potential packet-specific quality probs */
	struct packet_def *prev;     /* pointer to previous packet in list */
	struct packet_def *next;     /* pointer to next packet in the list */ 
	uchar data[MAX_PACKET_SIZE]; /* specifies location of start of data */ 
};
typedef struct packet_def packet;
#define PDSIZE (sizeof(packet) - MAX_PACKET_SIZE)
    /* PDSIZE defines size of header only */

typedef int (*Packet_Routine)(packet *);
    /* this is a generic routine that will do something with the packet,
       (ie. print it) when it is encountered in the data stream. */


typedef uint4 PACKET_ID;
enum SELECT_METHOD { BY_INDEX, BY_TIME };

struct packet_sel_struct {
    double 		time;
    long		index;
    PACKET_ID		id;
    int 		direction;
    packet	       *lastpk;
    int 		series;
    enum SELECT_METHOD	select_by;
};
typedef struct packet_sel_struct packet_selector;

/* the following macros are handy for filling packet_selector
 * structs
 */
#define SET_PKS_BY_TIME(p,t,d)  (p).time=(t);(p).id=(d);(p).direction=1;(p).select_by=BY_TIME
#define SET_PKS_BY_INDEX(p,i,d) (p).time=0;(p).index=(i);(p).id=(d);(p).direction=1;(p).select_by=BY_INDEX
#define SET_PKS_BY_LASTT(p,t,d) (p).time=(t);(p).id=(d);(p).direction=-1;(p).select_by=BY_TIME

#define QUALITY_FILL_INFRAME	0x0001
#define QUALITY_INVALID_NEXTP	0x0002
#define QUALITY_FILL_INPACKET   0x0004

/***************************************************************************
This structure contains all the info on one type of packet.  Packets are stored
as linked lists.  This structure provides all info necessary for one type of
packet (i.e. first packet in the list, last packet in the list etc. )
*****************************************************************************/
#if !NEWFORMAT

struct pklist_def {
	char       *name;     /* name for printing purposes */
	uint4      id;        /* identification code        */
	uint4      idmask;    /* mask for id code           */
	boolean_t  sortable;  /* tells if packet arrays are sortable */
	int        ssize;                  /* single packet data size */ 
	int        tsize;                  /* super packet (total) size */
	uint2      seqmask;                /* non-zero for super packets */
	int        store;                  /* store flag */
	int        print;                  /* print flag */
	Packet_Routine pckt_print;         /* function that prints packets */
	uint4      numtotal;  /* total number of packets observed */
	packet     *current;  /* pointer to packet (for general use) */
	uint4      numlist;   /* number of elements in list */
	packet     *first;    /* first packet in list */
	packet     *last;     /* last packet in list  */
	uint4      numarray;  /* number of elements in array */
	packet     **array;   /* if non-zero: array of pointers to packets */
};
typedef struct pklist_def pklist;

#else

struct pklist_def {
	uint4 id;
	uint4 idmask;
	uint  numtotal;
	uint  numlist;
	uint  numarray;
	packet *first;
	packet *last;
	packet **array;
};
typedef struct pklist_def pklist;

#define MAX_PACKET_TYPES  50

struct AllData_def {
	int   memory_size;
	int   memory_left;
	int   num_packet_types;
	uchar *buffptr;
	pklist packet_types[MAX_PACKET_TYPES];
	packet packets[1];                        
/* only space for one packet is allocated here, but thousands may actually be present */
/* packets are NOT stored as an array!!!! */
};
typedef struct AllData_def AllData;


#endif


/******************** function prototypes for general use *************/


extern FILE *pckt_log_fp;

pklist* packet_type_ptr(uint4 id);  
   /* Returns pointer to list type given id */

packet *search_for_packet(double time,pklist *pkl);
   /* Returns packet of list type pkl,  nearest to time. */

/* get_packet(packet_selector *pks)
 * double           pks->time: time of packet to get. Ignored if getting by index.
 * long             pks->index:    index of packet to get.  Ignored if getting by time.
 * PACKET_ID        pks->id: PACKET_ID of interest.
 * int              pks->direction:       (-1,0,+1) : (previous,nearest,next). 
 * packet          *pks->lastpk:   gives a hint of where to start search. 
 * int              pks->series:   series identifcation tag (insures that lastpk is valid.
 * SELECTION_METHOD pks->select_by:   select by index or by time.
 * usage: 
 *   if pks->time is greater than 0: 
 *       gets the packet with the given id that has: 
 *           time less than pks->time    (direction <0) 
 *           time nearest to pks->time   (direction =0) 
 *           time greater than pks->time (direction >0) 
 *   if t is 0: 
 *       gets (previous/nearest/next) packet based on value of lastpk 
 * Note:  pks->lastpk and pks->series should be stored as static variables generally 
 */

packet *get_packet(packet_selector *pks);







int number_of_packets(uint4 id,double t1,double t2);
   /* Returns number of packets with given id between t1 and t2 */





/**** function prototypes for internal use only *******/

int set_print_packet_flag(int n);

int add_packet_routine(uint4 id,Packet_Routine routine);
   /*  sets a pointer so that whenever a packet with given id is encountered */ 
   /*  the given routine will be called */
   /*  this MUST be called prior to load_data_files()  */

int4    get_packet_index(uint4 id, double time);
   /*  out dated routine that could be brought back */



int initialize_raw_memory(int size,void *buff);

void make_all_list_arrays( void );

int process_packet(double time,uint errors,uchar *ds);
              /* processes a single packet data stream */

uint2 packet_spin(uchar *p);

uint2 packet_size(uchar *p);

uint4 packet_id(uchar *p);

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
#define		E3D_ELM_ID     0x50304000ul
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


void print_packet_summary(FILE *fp);

#endif
