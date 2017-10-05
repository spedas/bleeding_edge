#ifndef P3D_PRT_H
#define P3D_PRT_H
#include "wind_pk.h"
#include "p3d_dcm.h"

extern FILE *el3d_fp;
extern FILE *eh3d_fp;
extern FILE *ph3d_fp;

extern FILE *phb3d_raw_fp;
extern FILE *ph3d_raw_fp;
extern FILE *eh3d_raw_fp;
extern FILE *el3d_raw_fp;

extern FILE *phb3d_log_fp;
extern FILE *ph3d_log_fp;
extern FILE *eh3d_log_fp;
extern FILE *el3d_log_fp;

extern FILE *ph3d_spec_fp;
extern FILE *eh3d_spec_fp;
extern FILE *el3d_spec_fp;

extern FILE *eh3d_bins_fp;
extern FILE *el3d_bins_fp;
extern FILE *ph3d_bins_fp;

extern FILE *eh3d_cuts_fp;
extern FILE *ph3d_cuts_fp;
extern FILE *el3d_cuts_fp;

extern FILE *ph3d_omni_fp;
extern FILE *eh3d_omni_fp;
extern FILE *el3d_omni_fp;

extern FILE *el3d_accums_fp;
extern FILE *eh3d_accums_fp;
extern FILE *ph3d_accums_fp;

int print_ph3d_packet(packet *pk);
int print_phb3d_packet(packet *pk);
int print_el3d_packet(packet *pk);
int print_elc3d_packet(packet *pk);
int print_eh3d_packet(packet *pk);
int print_data_3d_gse(FILE *fp,data_map_3d *Map);
int print_data_3d_spectra(FILE *fp,data_map_3d *Map);
int print_data_3d_cuts(FILE *fp,data_map_3d *Map,uchar *blank);
int print_data_3d_bins(FILE *fp,data_map_3d *Map);
int print_data_3d_omni(FILE *fp,data_map_3d *Map,uchar *blank);
int print_data_3d_idl(FILE *fp,data_map_3d *Map);
int print_omni_spec(FILE *fp,spectra_3d_omni *spec);
int print_data_3d_accums(FILE *fp,data_map_3d *map);


extern uchar el_blank[MAX3DBINS];
extern uchar eh_blank[MAX3DBINS];
extern uchar ph_blank[MAX3DBINS];
extern int flux_units;

#endif

