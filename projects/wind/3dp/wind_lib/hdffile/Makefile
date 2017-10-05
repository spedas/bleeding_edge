#CC = gcc        # gnu c compiler
CC = cc
CFLAGS= -g

# You will need to set this on your system
HDFHOME=/disks/aeolus/disk1/wind/hdf

LIBDIR = ${HDFHOME}/lib
INC =${HDFHOME}/include

CDFHOME = /disks/aeolus/disk1/wind/source/wind_lib/cdf
CDFLIB = ${HDFHOME}/lib
CDFINC = ${CDFHOME}/include

# These are system dependent variables (currently set for Solaris)
# Look at your HDF README file for information on your platform
HDFLIBS = -lmfhdf -ldf -ljpeg -lz -lnsl
MISCLIB = -lm -lsunmath

# Some of the libraries on our system are here. You may need to change this.
LIBDIR2 = /disks/apollo/export/SUNWspro/lib

all: hdf_file_info hdf_vdata_info hdffile	# create these executable files

hdf_file_info: hdf_file_info.o
	$(CC) ${CFLAGS} hdf_file_info.o -I${INC} -L${LIBDIR} -L${LIBDIR2} ${HDFLIBS} ${MLIBS} -o $@ 

hdf_file_info.o: hdf_file_info.c
	$(CC) ${CFLAGS} -c hdf_file_info.c -o $@ -I${INC} 

hdf_vdata_info: hdf_vdata_info.o
	$(CC) ${CFLAGS} hdf_vdata_info.o -I${INC} -L${LIBDIR} -L${LIBDIR2} ${HDFLIBS} ${MLIBS} -o $@ 

hdf_vdata_info.o: hdf_vdata_info.c
	$(CC) ${CFLAGS} -c hdf_vdata_info.c -o $@ -I${INC} 

hdffile: hdffile.o
	$(CC) ${CFLAGS} hdffile.o -I${INC} -I${CDFINC} -L${CDFLIB} -L${LIBDIR} -L${LIBDIR2} ${HDFLIBS} ${MLIBS} ${MISCLIB} -lcdf -o $@ 

hdffile.o: hdffile.c
	$(CC) ${CFLAGS} -c hdffile.c -o $@ -I${INC} -I${CDFINC}

