#ifndef SPEC_PRT_H
#define SPEC_PRT_H


int print_eesa_spectra(packet *pk);
extern FILE *elspec_fp;
extern FILE *ehspec_fp;
extern FILE *elspec_auto_fp;

int print_pesa_spectra(packet *pk);
extern FILE *plspec_fp;
extern FILE *phspec_fp;



#endif
