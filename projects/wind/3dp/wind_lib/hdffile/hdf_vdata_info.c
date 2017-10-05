#include <stdio.h>
#include "df.h"
#include "mfhdf.h"

void main(int argc, char *argv[])
{
  int32 hdf_fp, vdata_ref, vdata_id, n_records, interlace_mode, vdata_size;
  char field_list[500];
  uint8 *databuf;
  
  if (argc!=3) {
    printf("Usage: hdf_file_info hdf_file vdata_name\n");
    exit(1);
  }
  
  if ((hdf_fp=Hopen(argv[1], DFACC_READ, 0))==FAIL)
    {
      fprintf(stderr, "Hopen: could not open hdf file\n");
      exit(-1);
    }

  Vstart(hdf_fp);
  
  if ((vdata_ref=VSfind(hdf_fp,argv[2]))==0)
    {
      fprintf(stderr, "VSfind: could not find Vdata name %s\n", argv[2]);
      exit(-1);
    }
  
  vdata_id = VSattach(hdf_fp, vdata_ref, "r");
  
  VSinquire(vdata_id, &n_records, &interlace_mode, field_list, &vdata_size, NULL);
  printf("n_records: %d\n", n_records);
  printf("interlace_mode: %d\n", interlace_mode);
  printf("vdata_size: %d\n", vdata_size);
  printf("field_list: %s\n", field_list);
  
  databuf = (uint8 *)malloc(vdata_size*n_records);
  
  VSsetfields(vdata_id, field_list);
  VSread(vdata_id, databuf, n_records, 1);
  
  VSdetach(vdata_id);
  Vend(hdf_fp);

  if (Hclose(hdf_fp)==FAIL)
    {
      fprintf(stderr, "Hclose: could not close hdf file\n");
      exit(-1);
    }
    
  exit(0);
}

