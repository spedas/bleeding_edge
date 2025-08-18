#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <cdf.h>
#include "df.h"
#include "hdf.h"

void ACEepoch_to_str(double, char *);

void main(int argc, char *argv[])
{
  int32 hdf_fp, vdata_ref, vdata_id, n_records, n;
  float64 startdatebuf[1],enddatebuf[1];
  char *filename, startdate[100], enddate[100];
  
  if (argc < 3) {
    printf("Usage: hdffile vdata_name hdf_file0 hdf_file1...\n");
    exit(1);
  }

  for (n=2; n < argc; n++) {
    
    filename = argv[n];
  
    if ((hdf_fp=Hopen(filename, DFACC_READ, 0))==FAIL)
      {
        fprintf(stderr, "Hopen: could not open hdf file\n");
        exit(-1);
      }

    Vstart(hdf_fp);
  
    if ((vdata_ref=VSfind(hdf_fp,argv[1]))==0)
      {
        fprintf(stderr, "VSfind: could not find Vdata name %s\n", argv[2]);
        exit(-1);
      }
    
    vdata_id = VSattach(hdf_fp, vdata_ref, "r");
  
    VSinquire(vdata_id, &n_records, NULL, NULL, NULL, NULL);
  
    VSsetfields(vdata_id, "ACEepoch");
    VSread(vdata_id, (uint8 *)startdatebuf, 1, 0);
  
    VSseek(vdata_id,n_records-1);
    VSread(vdata_id, (uint8 *)enddatebuf, 1, 0);
  
    VSdetach(vdata_id);
    Vend(hdf_fp);

    if (Hclose(hdf_fp)==FAIL)
      {
        fprintf(stderr, "Hclose: could not close hdf file\n");
        exit(-1);
      }
  
    ACEepoch_to_str((double)*startdatebuf, startdate);
    ACEepoch_to_str((double)*enddatebuf, enddate);
    printf("%s %s  %s  %d\n", startdate, enddate, filename, n_records);
  }
    
  exit(0);
}

void ACEepoch_to_str(double epoch, char *date)
{
    long year;
    long month;
    long day;
    long hour;
    long minute;
    long second;
    long msec;
    double epoch0=(719528.+9496.)* 24.* 3600. * 1000.;

    epoch *= 1000.;
    epoch += epoch0;

    EPOCHbreakdown(epoch, &year, &month, &day, &hour, &minute, &second, &msec);
    sprintf(date,"%4d-%02d-%02d/%02d:%02d:%02d",year,month,day,hour,minute,second);
}
