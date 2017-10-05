#include <stdio.h>
#include "df.h"
#include "mfhdf.h"

void print_vgroup_info(int32 hdf_fp, int32 vgroup_ref);
void print_vdata_info(int32 hdf_fp, int32 vmember_ref);

void main(int argc, char *argv[])
{
  int32 hdf_fp, vgroup_ref=-1;
  
  if (argc!=2) {
    printf("Usage: hdf_file_info hdf_file\n");
    exit(1);
  }
  
  if ((hdf_fp=Hopen(argv[1], DFACC_READ, 0))==FAIL)
    {
      fprintf(stderr, "Hopen: could not open hdf file\n");
      exit(-1);
    }

  Vstart(hdf_fp);
  
  while ((vgroup_ref=Vgetid(hdf_fp,vgroup_ref))!=FAIL)
    {
      print_vgroup_info(hdf_fp,vgroup_ref);
    }

  Vend(hdf_fp);

  if (Hclose(hdf_fp)==FAIL)
    {
      fprintf(stderr, "Hclose: could not close hdf file\n");
      exit(-1);
    }
    
  exit(0);
}

void print_vgroup_info(int32 hdf_fp, int32 vgroup_ref)
{
  int32 vgroup_id, vmember_ref;
  char vgroup_name[VGNAMELENMAX];
  
  printf("Found VGroup\n");
  vgroup_id = Vattach(hdf_fp,vgroup_ref,"r");
  Vgetname(vgroup_id,vgroup_name);
  printf("Vgroup name: %s\n",vgroup_name);
  vmember_ref = -1;
  while ((vmember_ref = Vgetnext(vgroup_id, vmember_ref))!=FAIL)
    {
      printf("Found VMember\n");
      if (Visvs(vgroup_id,vmember_ref))
        {
          print_vdata_info(hdf_fp, vmember_ref);
        }
      else if (Visvg(vgroup_id,vmember_ref))
        {
          print_vgroup_info(hdf_fp, vmember_ref);
        }
    }
  Vdetach(vgroup_id);
  return;
}  

void print_vdata_info(int32 hdf_fp, int32 vmember_ref)
{
  int32 vdata_ref, cnt;
  char field_list[500], vdata_name[VGNAMELENMAX];

  vdata_ref = VSattach(hdf_fp,vmember_ref,"r");
  VSQueryname(vdata_ref,vdata_name);
  printf("VData name: %s\n",vdata_name);
  VSQuerycount(vdata_ref,&cnt);
  printf("Number of records: %d\n",cnt);
  VSQueryfields(vdata_ref,field_list);
  printf("Field list: %s\n",field_list);
  VSdetach(vdata_ref);

  return;
}