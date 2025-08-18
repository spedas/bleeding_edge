;+
; PROCEDURE:
;     kgy_read_tof
; PURPOSE:
;     reads in Kaguya MAP/PACE TOF files
;     and stores data in a common block (kgy_pace_com)
; CALLING SEQUENCE:
;     kgy_raed_tof, files
; INPUTS:
;     files: full paths to the TOF files
;            e.g., ['dir/TOF_DATA_3He_8KeV.txt', $
;                   'dir/TOF_DATA_3He_10KeV.txt', ...]
; KEYWORDS:
;     load: if set, download and read in publicly available files
;           (override any inputs) 
; CREATED BY:
;     Yuki Harada on 2021-11-08
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2018-07-05 17:00:43 +0900 (Thu, 05 Jul 2018) $
; $LastChangedRevision: 25438 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/pace/kgy_read_fov.pro $
;-

pro kgy_read_tof, files, load=load, verbose=verbose, _extra=_ex

@kgy_pace_com

if keyword_set(load) then begin
   files = ''
   if ~tag_exist(_ex,'no_server') then str_element,_ex,'no_server',0,/add
;   s = kgy_file_source(remote_data_dir='http://research.ssl.berkeley.edu/~haraday/data/kaguya/',last_version=0, _extra=_ex)
   s = kgy_file_source(remote_data_dir='http://step0ku.kugi.kyoto-u.ac.jp/~haraday/data/kaguya/',last_version=0, _extra=_ex)
   pfs = 'public/TOF_DATA/'+ $
         [ $
         'TOF_DATA_3He_8KeV.txt', $
         'TOF_DATA_3He_10KeV.txt', $
         'TOF_DATA_3He_12KeV.txt', $
         'TOF_DATA_3He_15KeV.txt', $

         'TOF_DATA_4He_8KeV.txt', $
         'TOF_DATA_4He_10KeV.txt', $
         'TOF_DATA_4He_12KeV.txt', $
         'TOF_DATA_4He_15KeV.txt', $

         'TOF_DATA_Al_8KeV.txt', $
         'TOF_DATA_Al_10KeV.txt', $
         'TOF_DATA_Al_12KeV.txt', $
         'TOF_DATA_Al_15KeV.txt', $

         'TOF_DATA_Ar_8KeV.txt', $
         'TOF_DATA_Ar_10KeV.txt', $
         'TOF_DATA_Ar_12KeV.txt', $
         'TOF_DATA_Ar_15KeV.txt', $

         'TOF_DATA_C_8KeV.txt', $
         'TOF_DATA_C_10KeV.txt', $
         'TOF_DATA_C_12KeV.txt', $
         'TOF_DATA_C_15KeV.txt', $

         'TOF_DATA_Cr_8KeV.txt', $
         'TOF_DATA_Cr_10KeV.txt', $
         'TOF_DATA_Cr_12KeV.txt', $
         'TOF_DATA_Cr_15KeV.txt', $

         'TOF_DATA_D_8KeV.txt', $
         'TOF_DATA_D_10KeV.txt', $
         'TOF_DATA_D_12KeV.txt', $
         'TOF_DATA_D_15KeV.txt', $

         'TOF_DATA_Fe_8KeV.txt', $
         'TOF_DATA_Fe_10KeV.txt', $
         'TOF_DATA_Fe_12KeV.txt', $
         'TOF_DATA_Fe_15KeV.txt', $

         'TOF_DATA_H_8KeV.txt', $
         'TOF_DATA_H_10KeV.txt', $
         'TOF_DATA_H_12KeV.txt', $
         'TOF_DATA_H_15KeV.txt', $

         'TOF_DATA_He_8KeV.txt', $
         'TOF_DATA_He_10KeV.txt', $
         'TOF_DATA_He_12KeV.txt', $
         'TOF_DATA_He_15KeV.txt', $

         'TOF_DATA_K_8KeV.txt', $
         'TOF_DATA_K_10KeV.txt', $
         'TOF_DATA_K_12KeV.txt', $
         'TOF_DATA_K_15KeV.txt', $

         'TOF_DATA_Mg_8KeV.txt', $
         'TOF_DATA_Mg_10KeV.txt', $
         'TOF_DATA_Mg_12KeV.txt', $
         'TOF_DATA_Mg_15KeV.txt', $

         'TOF_DATA_Mn_8KeV.txt', $
         'TOF_DATA_Mn_10KeV.txt', $
         'TOF_DATA_Mn_12KeV.txt', $
         'TOF_DATA_Mn_15KeV.txt', $

         'TOF_DATA_N_8KeV.txt', $
         'TOF_DATA_N_10KeV.txt', $
         'TOF_DATA_N_12KeV.txt', $
         'TOF_DATA_N_15KeV.txt', $

         'TOF_DATA_Na_8KeV.txt', $
         'TOF_DATA_Na_10KeV.txt', $
         'TOF_DATA_Na_12KeV.txt', $
         'TOF_DATA_Na_15KeV.txt', $

         'TOF_DATA_O_8KeV.txt', $
         'TOF_DATA_O_10KeV.txt', $
         'TOF_DATA_O_12KeV.txt', $
         'TOF_DATA_O_15KeV.txt', $

         'TOF_DATA_P_8KeV.txt', $
         'TOF_DATA_P_10KeV.txt', $
         'TOF_DATA_P_12KeV.txt', $
         'TOF_DATA_P_15KeV.txt', $

         'TOF_DATA_S_8KeV.txt', $
         'TOF_DATA_S_10KeV.txt', $
         'TOF_DATA_S_12KeV.txt', $
         'TOF_DATA_S_15KeV.txt', $

         'TOF_DATA_Si_8KeV.txt', $
         'TOF_DATA_Si_10KeV.txt', $
         'TOF_DATA_Si_12KeV.txt', $
         'TOF_DATA_Si_15KeV.txt', $

         'TOF_DATA_Ti_8KeV.txt', $
         'TOF_DATA_Ti_10KeV.txt', $
         'TOF_DATA_Ti_12KeV.txt', $
         'TOF_DATA_Ti_15KeV.txt', $

         'TOF_DATA_Zn_8KeV.txt', $
         'TOF_DATA_Zn_10KeV.txt', $
         'TOF_DATA_Zn_12KeV.txt', $
         'TOF_DATA_Zn_15KeV.txt' $
         ]
   for ipf=0,n_elements(pfs)-1 do begin
;      f = file_retrieve(pfs[ipf],_extra=s) 
;      if total(strlen(f)) then files = [files,f]
      f = spd_download(remote_file=pfs[ipf],_extra=s)
     if total(file_test(f)) then files = [files,f]
   endfor
   w = where(strlen(files) gt 0 , nw)
   if nw eq 0 then return
   files = files[w]
endif


;;; initialize TOF structure
ima_tof_str = {}


;;; read files
for i_file=0,n_elements(files)-1 do begin

fname = files[i_file]

;- file info check
finfo = file_info(fname)
if finfo.exists eq 0 then begin
   dprint,dlevel=0,verbose=verbose,'FILE DOES NOT EXIST: '+fname+' --> skipped'
   CONTINUE
endif else dprint,dlevel=0,verbose=verbose,'open file: '+fname

d = read_ascii_cmdline(fname,delimiter=' ',count=c, $
                       field_names=['q','m','Kini','Vlef','Kloss','tofN','tofL','tofNEG','tofLidl'], $
;- charge, mass, initial energy, LEF voltage, loss energy, neutral TOF, positive ion TOF, negative ion TOF, positive ion ideal TOF (not used)
                       field_types=['int','int','float','float','float','float','float','float','float'])
for i=0,c-1 do begin
   ima_tof_str_0 = {q:0,m:0,kini:0.,Vlef:0.,Kloss:0.,tofN:0.,tofL:0.,tofNEG:0.,tofLidl:0.}
   ntag = n_tags(ima_tof_str_0)

   for itag=0,ntag-1 do ima_tof_str_0.(itag) = d.(itag)[i]

   append_array,ima_tof_str,ima_tof_str_0
endfor

endfor                          ;- i_file loop


end
