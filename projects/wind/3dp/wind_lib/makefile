#
# Makefile for program wind To be used on UNIX!
#

# COMPLIBPATH is the pathname of the directory containing the compiler related libraries
COMPLIBPATH:sh = (ccpath=`which cc | tail -1 | sed 's%bin/cc%%'`; ls -d ${ccpath}SC*/lib)

#LIB = -L$(COMPLIBPATH) -lm -lsunmath
LIB = -L$(COMPLIBPATH) -lm -L/usr/lib

#CFLAGS  = -g -G -PIC            # big cc options
#CFLAGS  = -g -G PIC              # little cc options
CFLAGS  = -g               # gcc options
#CC = CC
CC = gcc
LDFLAGS = 

WIND_LIB.c = windmisc.c \
            wind_idl.c \
            fpc_dcm.c \
            eesa_cfg.c ecfg_dcm.c ecfg_prt.c \
            pesa_cfg.c pcfg_dcm.c pcfg_prt.c \
            main_cfg.c mcfg_dcm.c mcfg_prt.c \
            esteps.c \
            pckt_prt.c \
            brst_dcm.c \
            emom_dcm.c emom_prt.c \
            pmom_dcm.c pmom_prt.c \
            spec_dcm.c spec_prt.c \
            kpd_dcm.c  kpd_prt.c  \
            hkp_dcm.c  hkp_prt.c  \
            pl_dcm.c   pl_prt.c   \
            ph_dcm.c \
            pads_dcm.c pads_prt.c \
            fpc_prt.c \
	    eAtoD_dcm.c \
	    pAtoD_dcm.c \
            mem_dcm.c tmp_dcm.c \
            frame_dcm.c  frame_prt.c\
            filter.c \
            matrix.c \
            sweeps.c sweep_prt.c\
            sst_dcm.c  sst_prt.c \
            p3d_dcm.c  p3d_prt.c \
            map3d.c map_0.c map_11b.c map_22d.c map_5.c map_88.c map_8.c map_elc.c map_ehs.c\
            wind_pk.c \
            date.c \
            p3d_time.c 


WIND_OBJ = $(WIND_LIB.c:%.c=%.o)

WIND_H  = $(WIND_LIB.c:%.c=%.h) defs.h winddefs.h

KPDTEST.c = windmisc.c matrix.c kpd_dcm.c\
   eesa_cfg.c ecfg_dcm.c \
   pesa_cfg.c pcfg_dcm.c \
   pmom_dcm.c emom_dcm.c sweeps.c esteps.c \
   pmom_prt.c emom_prt.c make_doc.c

KPDTEST_OBJ = $(KPDTEST.c:%.c=%.o)

WINDFILE_SRC.c = frame_dcm.c windmisc.c wind_pk.c pckt_prt.c brst_dcm.c frame_prt.c date.c filter.c

WINDFILE_OBJ = $(WINDFILE_SRC.c:%.c=%.o)

KPDFILE_C = kpdfile.c cdf_time.c windmisc.c

KPDFILE_OBJ = $(KPDFILE_C:%.c=%.o)

LIBCDF_DIR  = /disks/aeolus/disk1/wind/source/wind_lib/cdf/lib
LIBCDF      = $(LIBCDF_DIR)/libcdf.a
CDFH_DIR    = /disks/aeolus/disk1/wind/source/wind_lib/cdf/include

TESTOBJ = test.o kpd_dcm.o wind_cfg.o esteps.o emom_dcm.o pmom_dcm.o windmisc.o matrix.o

all: source wind.doc wind 3dpfile wind_lib.so make_doc scan_index cdffile

source : $(WIND_LIB.c) $(WIND_H) $(KPDFILE_C)

date.o : $(WIND_LIB.c) wind.c

$(WIND_OBJ) wind.o : $(WIND_H)

wind:  wind.c wind.o wind_lib.a 
	$(CC) $(LDFLAGS) -o $@ wind.o wind_lib.a  $(LIB)

3dpfile: 3dpfile.c 3dpfile.o $(WINDFILE_SRC.c) $(WINDFILE_OBJ)
	$(CC) $(LDFLAGS) -o $@ 3dpfile.o $(WINDFILE_OBJ) $(LIB)

wind_lib.so: $(WIND_OBJ)
	ld -G -o wind_lib.so $(WIND_OBJ) $(LIB)

kpdfile: $(KPDFILE_OBJ)
	$(CC) $(LDFLAGS) -o $@ $(KPDFILE_OBJ) $(LIBCDF) $(LIB)
	
cdffile: cdffile.c
	$(CC) $(LDFLAGS) -I $(CDFH_DIR) -o $@ cdffile.c $(LIBCDF) $(LIB)

make_doc: make_doc.c
	CC -o $@ make_doc.c

scan_index: windmisc.o scan_index.c
	$(CC) -o scan_index windmisc.o scan_index.c

$(KPDFILE_OBJ) : cdf_time.h 

sweeptest: sweeptest.c sweeptest.o wind_lib.a
	$(CC) $(LDFLAGS) -o $@ sweeptest.o wind_lib.a $(LIB)

kpdtest2: kpdtest.c kpdtest.o wind_lib.a
	$(CC) $(LDFLAGS) -o $@ kpdtest.o wind_lib.a $(LIB)

kpdtest: kpdtest.c kpdtest.o $(KPDTEST_OBJ)
	$(CC) $(LDFLAGS) -o $@ kpdtest.o $(KPDTEST_OBJ) $(LIB)

wind_lib.a: $(WIND_OBJ)
	ar rv $@ $?

wind_lib.a(%.o): %.o
	@true

clean:
	$(RM) *% core

realclean:
	$(RM) *% core
	$(RM) *.o
	$(RM) wind_lib.a


