pro mvn_common_l0_file_transfer,l0_dir,new_l0_dir

if not keyword_set(l0_dir) then l0_dir = root_data_dir() + 'maven/data/sci/pfp/l0/'
if ~keyword_set(new_l0_dir) then new_l0_dir = root_data_dir() + 'maven/data/sci/pfp/l0_all/'

pattern = 'mvn_pfp_all_l0_YYYYMMDD_v???.dat'
spattern= 'mvn_pfp_all_l0_????????_v???.dat'
files= file_search(l0_dir+spattern)
bnames = file_basename(files)
rootnames = strmid(bnames,0,23)              ;  file name without version
last_ind = uniq(rootnames)                   ;  determine the last version files

last_files = files[last_ind]  
last_bnames = bnames[last_ind]

last_times= time_double(tformat=pattern,last_bnames)       ; get file dates;

new_last_dirs = new_l0_dir + time_string( last_times,tformat= 'YYYY/MM/')   ; get new directories

tr =  [ time_double('2013-1-1'),systime(1) ]                    ; Throw out the outliers
;tr =  [ time_double('2015-10-15'),systime(1) ]                    ; Throw out the outliers
w = where(last_times ge tr[0] and last_times lt tr[1] ,nw)
if nw ne 0 then begin 
  new_last_dirs = new_last_dirs[w]
  last_bnames = last_bnames[w]
  last_files = last_files[w]
  
  u = uniq(new_last_dirs)                         ; get unique directories
  file_mkdir2,new_last_dirs[u]                    ; create directories if needed
  ;dprint,'files to be linked:',transpose(last_files)
  file_link,/hardlink,last_files, new_last_dirs+last_bnames ,/allow_same,/verbose
  ;dprint,'hardlinks created:',transpose(new_last_dirs+last_bnames)
endif 


;  Now remove old versions from the new directory
if 1 then begin
  version_pattern = '_v???.dat'
  all_files = file_search(new_l0_dir,'*'+version_pattern,count=count)
  if count ne 0 then begin
    bfiles = strmid(all_files,0,transpose(strlen(all_files) -strlen(version_pattern)))
    last_ind = uniq(bfiles)    ; good files
    ind = replicate(1,n_elements(all_files))
    ind[last_ind] = 0
    old_ind = where(ind,n_old)
    old_files= n_old eq 0 ? '' : all_files[old_ind]
    count = n_old
    if n_old ne 0 then begin
      dprint,'files to be removed:',transpose(old_files)
      file_archive,archive_dir='.oldversions/',old_files      
    endif
  endif

endif


generate_checksums,new_l0_dir,dir='*',file_=spattern,/include

end


