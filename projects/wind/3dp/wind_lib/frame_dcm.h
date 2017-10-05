#ifndef FRAME_DCM_H
#define FRAME_DCM_H

#include "defs.h"
#include "wind_pk.h"

enum FILE_TYPE {
	FILE_INVALID,
	FILE_GSE_HKP,      /* no longer supported  */
	FILE_GSE_RAW,      /* Oldest supported format no thermister bytes */
	FILE_GSE_THERM,    /* Includes thermister bytes  */
	FILE_GSE_FLT,      /* Flight files */
	FILE_GSE_ENG,      /* Engineering model files (no thermister) */
	FILE_MASTER,       /* Text file containing list of data files */
	FILE_NRT_LZ = 8,
	FILE_NASA_LZ
};

enum SPC_MODE {
	SPC_MODE_INVALID,
	SPC_MODE_SCI1x,
	SPC_MODE_ENG1x,
	SPC_MODE_MAN1x,
	SPC_MODE_CON1x,
	SPC_MODE_SCI2x,
	SPC_MODE_ENG2x,
	SPC_MODE_MAN2x,
	SPC_MODE_CON2x,
	SPC_MODE_TRANS = 128,
	SPC_MODE_UNKNOWN = 256
};


#define ERROR_FRAME_GAP         0x0001
#define ERROR_OFFSET_MISMATCH   0x0002
#define ERROR_NON_CONSEC_FRAMES 0x0004
#define ERROR_ZERO_BYTES        0x0008

#define ERROR_PACKET_LENGTH     0x0010
#define ERROR_INVALID_PACKET    0x0020
#define ERROR_FRAME_SHIFT       0x0040
#define ERROR_MODE_INVALID      0x0080

#define ERROR_BAD_FRAME_SPIN    0x0100
#define ERROR_SPIN_ROLLOVER     0x0200
#define ERROR_SPIN_RESET        0x0400
#define ERROR_NEW_SPIN0_TIME    0x0800

#define ERROR_FILL_BYTES        0x1000
#define ERROR_FRAME_SYNC        0x2000
#define ERROR_DIFFERENT_MODES   0x4000
#define ERROR_GSE_TIME_CORRECT  0x8000
#define ERROR_STRING "GDSFTROSMFULZNOG"

#define ERROR_TELEM (ERROR_FILL_BYTES|ERROR_FRAME_SYNC|ERROR_DIFFERENT_MODES)

#define MAX_TELEM_TYPES	50


struct frameinfo_def {
	double   time;             /* (P) frame start time               */
	double   spin_period;      /* (P) spin period in seconds         */
	double   spin0_time;       /*     time for spin number 0          */
	double   fspin;            /* (P) spin with fractional rotation   */
	double   dspin;            /*     number of spins in prev frame   */
	double   creep;            /* (P) creep in time since last reset  */
	uint4    counter;          /*     frame_counter                   */

	uint4  errors;             /* (P)  error flags (bit-coded)        */
	uint2  npkts;              /* (P)  number of packets in frame     */
	uint2  main_packet_types;  /* (P)  packets observed (bit-coded)   */
	uint2  eesa_packet_types;  /* (P)  packets observed (bit-coded)   */
	uint2  pesa_packet_types;  /* (P)  packets observed (bit-coded)   */

/* level-zero decomutation errors:  */
	uint2  num_fill_bytes;
	uint2  num_sync_errors;
	uchar  minor_frame_quality[250];
	
/* telemetry percentages:  */
#if 0
	float  main_telem;         /* (P)  */
	float  pesa_telem;         /* (P)  */
	float  eesa_telem;         /* (P)  */
	float  fpc_telem;          /* (P)  */
#endif
	float  telem[MAX_TELEM_TYPES];
	float  used_telem;         /* (P)  Sum of above */
	float  bad_telem;          /* (P)  */
	float  unused_telem;       /* (P)  */
	float  lost_telem;         /* (P)  */

            /*  data for future statistics purposes: */	
	uint2  good;               /*   number of good bytes           */
	uint2  bad;                /*   number of bad (zero) bytes     */
	uint2  ugly;               /*   unused telemetry bytes         */
	uint2  lost;               /*   lost bytes */
	        /*  data determined from housekeeping bytes: */
	uint2  offset;             /*  position of first science data */
	int4   spin;               /*  spin number at start of frame  */
	uchar  inst_mode;          /*  instrument mode                */
	uchar  phase;              /*  spin phase at start of frame   */
	uchar  seq;                /*  sequence number                */
  /*  data used to comunicate between sort_frame() and sort_packets(): */
	uint2  nsci;           /* number of 3DP science bytes        */
	uint2  nhkp;           /* number of 3DP housekeeping bytes   */
	uint2  nkpd;           /* number of 3DP key_parameter bytes  */
	uint2  nthm;           /* number of 3DP thermister bytes     */
/*	uint2  sci_shift;      /* byte shift (determined from previous frame) */
		/* file specific data */
#if 0
/*	enum FILE_TYPE file_type; /*  ie. gsehkp gseraw gsetherm nasa */
	enum SPC_MODE  spc_mode;  /* Spacecraft mode 1:sci 2:eng 3:man 4:cont*/
#else
/*	int file_type; /* type of file  */
	uint4 spc_mode;  /* Spacecraft mode */
#endif
/*	uint2  hdr_size;       /* size of header  (in bytes)                 */
/*	uint2  rcd_size;       /* size of frame record  (header+data)        */
/*	uint2  file_hdr_size;  /* size of file header                        */
	uint2  nbytes;         /* number of data bytes per frame             */

	uint2 burst_num;       /* current burst counter value */
};
typedef struct frameinfo_def frameinfo;

#define FRAME_INFO_SIZE ((uint)(sizeof(struct frameinfo_def)))


struct file_info_def {
#if 0
	enum FILE_TYPE file_type; /*  ie. gsehkp gseraw gsetherm nasa */
#else
	int file_type; /* type of file  */
#endif
	uint2  hdr_size;       /* size of header  (in bytes)                 */
	uint2  rcd_size;       /* size of frame record  (header+data)        */
	uint2  file_hdr_size;  /* size of file header                        */
};
typedef struct file_info_def file_info;




/*****  Function Prototypes ******/


/* returns 0 if unsuccessful */
/* returns 1 if successful */
int get_next_frame_struct(packet_selector *pks, struct frameinfo_def *frm);

int number_of_frame_samples(double t1,double t2);

#endif
