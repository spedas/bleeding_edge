;+
; PROCEDURE:
;     kgy_read_inf
; PURPOSE:
;     reads in Kaguya MAP/PACE information files
;     and stores data in a common block (kgy_pace_com)
; CALLING SEQUENCE:
;     kgy_raed_inf, files
; INPUTS:
;     files: full paths to the info files (gziped or decompressed)
;            e.g., ['dir/IEA_ENE_POL_AZ_GFACTOR_16X64_20080225.dat', $
;                   'dir/IEA_ENE_POL_AZ_GFACTOR_4X16_20080226.dat', ...]
; KEYWORDS:
;     load: if set, download and read in publicly available files
;           (override any inputs)
; CREATED BY:
;     Yuki Harada on 2014-06-29
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2018-05-25 00:09:00 -0700 (Fri, 25 May 2018) $
; $LastChangedRevision: 25271 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/pace/kgy_read_inf.pro $
;-

pro kgy_read_inf, files, load=load, verbose=verbose, _extra=_ex

@kgy_pace_com

if keyword_set(load) then begin
   files = ''
   if ~tag_exist(_ex,'no_server') then str_element,_ex,'no_server',0,/add
   s = kgy_file_source(remote_data_dir='http://research.ssl.berkeley.edu/~haraday/data/kaguya/',last_version=1, _extra=_ex)
   pfs = 'public/Kaguya_MAP_PACE_information/'+ $
         ['ESA-S1_ENE_POL_AZ_GFACTOR_16X64_*.dat', $
          'ESA-S1_ENE_POL_AZ_GFACTOR_4X16_*.dat', $
          'ESA-S2_ENE_POL_AZ_GFACTOR_16X64_*.dat', $
          'ESA-S2_ENE_POL_AZ_GFACTOR_4X16_*.dat', $
          'IEA_ENE_POL_AZ_GFACTOR_16X64_*.dat', $
          'IEA_ENE_POL_AZ_GFACTOR_4X16_*.dat', $
          'IMA_ENE_POL_AZ_GFACTOR_16X64_*.dat', $
          'IMA_ENE_POL_AZ_GFACTOR_4X16_*.dat' ]
   for ipf=0,n_elements(pfs)-1 do begin
      f = file_retrieve(pfs[ipf],_extra=s)
      if total(strlen(f)) then files = [files,f]
   endfor
   w = where(strlen(files) gt 0 , nw)
   if nw eq 0 then return
   files = files[w]
endif



for i_file=0,n_elements(files)-1 do begin

fname = files[i_file]

;- file info check
finfo = file_info(fname)
if finfo.exists eq 0 then begin
   dprint,dlevel=0,verbose=verbose,'FILE DOES NOT EXIST: '+fname+' --> skipped'
   CONTINUE
endif else dprint,dlevel=0,verbose=verbose,'open file: '+fname

fsensor = -1
polxaz = ''
if strmatch(fname,'*ESA-S1*') eq 1 then fsensor = 0
if strmatch(fname,'*ESA-S2*') eq 1 then fsensor = 1
if strmatch(fname,'*IMA*') eq 1 then fsensor = 2
if strmatch(fname,'*IEA*') eq 1 then fsensor = 3
if strmatch(fname,'*16X64*') eq 1 then polxaz = '16x64'
if strmatch(fname,'*4X16*') eq 1 then polxaz = '4x16'
if strmatch(fname,'*.gz') eq 1 then compress = 1 else compress = 0

case fsensor of
   0: begin                                            ;- ESA-S1
      if size(esa1_info_str,/tname) ne 'STRUCT' then $ ;- initialize str
         esa1_info_str $
         = {ene_16x64:fltarr(8,32,16,64), $ ;- keV
            pol_16x64:fltarr(8,32,16,64), $ ;- deg.
            az_16x64:fltarr(8,32,16,64), $  ;- deg.
            gfactor_16x64:dblarr(8,32,16,64), $  ;- cm^2 str keV/keV
            ene_sqno_16x64:intarr(8,32,16,64), $ ;- ENERGY-SEQUENCE_NO
            pol_sqno_16x64:intarr(8,32,16,64), $ ;- POLAR-ANGLE-SQUENCE_NO
            enemin_16x64:fltarr(8,32,16,64), $   ;- keV
            enemax_16x64:fltarr(8,32,16,64), $   ;- keV
            polmin_16x64:fltarr(8,32,16,64), $   ;- deg.
            polmax_16x64:fltarr(8,32,16,64), $   ;- deg.
            azmin_16x64:fltarr(8,32,16,64), $    ;- deg.
            azmax_16x64:fltarr(8,32,16,64), $    ;- deg.
            ene_4x16:fltarr(8,32,4,16), $        ;- keV
            pol_4x16:fltarr(8,32,4,16), $        ;- deg.
            az_4x16:fltarr(8,32,4,16), $         ;- deg.
            gfactor_4x16:dblarr(8,32,4,16), $    ;- cm^2 str keV/keV
            ene_sqno_4x16:intarr(8,32,4,16), $   ;- ENERGY-SEQUENCE_NO
            pol_sqno_4x16:intarr(8,32,4,16) }    ;- POLAR-ANGLE-SQUENCE_NO
      case polxaz of
         '16x64': begin
            xread = dblarr(16) & line_dum=''
            openr,1,fname,compress=compress
            readf,1,line_dum    ;- read header
            while not EOF(1) do begin
               readf,1,xread
               i_ram = fix(xread[0])
               i_ene = fix(xread[1])
               i_pol = fix(xread[2])
               i_az = fix(xread[3])
               esa1_info_str.ene_16x64[i_ram,i_ene,i_pol,i_az] = xread[4]
               esa1_info_str.pol_16x64[i_ram,i_ene,i_pol,i_az] = xread[5]
               esa1_info_str.az_16x64[i_ram,i_ene,i_pol,i_az] = xread[6]
               esa1_info_str.gfactor_16x64[i_ram,i_ene,i_pol,i_az] = xread[7]
               esa1_info_str.ene_sqno_16x64[i_ram,i_ene,i_pol,i_az] = xread[8]
               esa1_info_str.pol_sqno_16x64[i_ram,i_ene,i_pol,i_az] = xread[9]
               esa1_info_str.enemin_16x64[i_ram,i_ene,i_pol,i_az] = xread[10]
               esa1_info_str.enemax_16x64[i_ram,i_ene,i_pol,i_az] = xread[11]
               esa1_info_str.polmin_16x64[i_ram,i_ene,i_pol,i_az] = xread[12]
               esa1_info_str.polmax_16x64[i_ram,i_ene,i_pol,i_az] = xread[13]
               esa1_info_str.azmin_16x64[i_ram,i_ene,i_pol,i_az] = xread[14]
               esa1_info_str.azmax_16x64[i_ram,i_ene,i_pol,i_az] = xread[15]
            endwhile
            close,1
            free_lun,1
         end
         '4x16': begin
            xread = dblarr(10) & line_dum=''
            openr,1,fname,compress=compress
            readf,1,line_dum    ;- read header
            while not EOF(1) do begin
               readf,1,xread
               i_ram = fix(xread[0])
               i_ene = fix(xread[1])
               i_pol = fix(xread[2])
               i_az = fix(xread[3])
               esa1_info_str.ene_4x16[i_ram,i_ene,i_pol,i_az] = xread[4]
               esa1_info_str.pol_4x16[i_ram,i_ene,i_pol,i_az] = xread[5]
               esa1_info_str.az_4x16[i_ram,i_ene,i_pol,i_az] = xread[6]
               esa1_info_str.gfactor_4x16[i_ram,i_ene,i_pol,i_az] = xread[7]
               esa1_info_str.ene_sqno_4x16[i_ram,i_ene,i_pol,i_az] = xread[8]
               esa1_info_str.pol_sqno_4x16[i_ram,i_ene,i_pol,i_az] = xread[9]
            endwhile
            close,1
            free_lun,1
         end
         else: dprint,'pol x as does not match'
      endcase
   end
   1: begin                                            ;- ESA-S2
      if size(esa2_info_str,/tname) ne 'STRUCT' then $ ;- initialize str
         esa2_info_str $
         = {ene_16x64:fltarr(8,32,16,64), $ ;- keV
            pol_16x64:fltarr(8,32,16,64), $ ;- deg.
            az_16x64:fltarr(8,32,16,64), $  ;- deg.
            gfactor_16x64:dblarr(8,32,16,64), $  ;- cm^2 str keV/keV
            ene_sqno_16x64:intarr(8,32,16,64), $ ;- ENERGY-SEQUENCE_NO
            pol_sqno_16x64:intarr(8,32,16,64), $ ;- POLAR-ANGLE-SQUENCE_NO
            enemin_16x64:fltarr(8,32,16,64), $   ;- keV
            enemax_16x64:fltarr(8,32,16,64), $   ;- keV
            polmin_16x64:fltarr(8,32,16,64), $   ;- deg.
            polmax_16x64:fltarr(8,32,16,64), $   ;- deg.
            azmin_16x64:fltarr(8,32,16,64), $    ;- deg.
            azmax_16x64:fltarr(8,32,16,64), $    ;- deg.
            ene_4x16:fltarr(8,32,4,16), $        ;- keV
            pol_4x16:fltarr(8,32,4,16), $        ;- deg.
            az_4x16:fltarr(8,32,4,16), $         ;- deg.
            gfactor_4x16:dblarr(8,32,4,16), $    ;- cm^2 str keV/keV
            ene_sqno_4x16:intarr(8,32,4,16), $   ;- ENERGY-SEQUENCE_NO
            pol_sqno_4x16:intarr(8,32,4,16) }    ;- POLAR-ANGLE-SQUENCE_NO
      case polxaz of
         '16x64': begin
            xread = dblarr(16) & line_dum=''
            openr,1,fname,compress=compress
            readf,1,line_dum    ;- read header
            while not EOF(1) do begin
               readf,1,xread
               i_ram = fix(xread[0])
               i_ene = fix(xread[1])
               i_pol = fix(xread[2])
               i_az = fix(xread[3])
               esa2_info_str.ene_16x64[i_ram,i_ene,i_pol,i_az] = xread[4]
               esa2_info_str.pol_16x64[i_ram,i_ene,i_pol,i_az] = xread[5]
               esa2_info_str.az_16x64[i_ram,i_ene,i_pol,i_az] = xread[6]
               esa2_info_str.gfactor_16x64[i_ram,i_ene,i_pol,i_az] = xread[7]
               esa2_info_str.ene_sqno_16x64[i_ram,i_ene,i_pol,i_az] = xread[8]
               esa2_info_str.pol_sqno_16x64[i_ram,i_ene,i_pol,i_az] = xread[9]
               esa2_info_str.enemin_16x64[i_ram,i_ene,i_pol,i_az] = xread[10]
               esa2_info_str.enemax_16x64[i_ram,i_ene,i_pol,i_az] = xread[11]
               esa2_info_str.polmin_16x64[i_ram,i_ene,i_pol,i_az] = xread[12]
               esa2_info_str.polmax_16x64[i_ram,i_ene,i_pol,i_az] = xread[13]
               esa2_info_str.azmin_16x64[i_ram,i_ene,i_pol,i_az] = xread[14]
               esa2_info_str.azmax_16x64[i_ram,i_ene,i_pol,i_az] = xread[15]
            endwhile
            close,1
            free_lun,1
         end
         '4x16': begin
            xread = dblarr(10) & line_dum=''
            openr,1,fname,compress=compress
            readf,1,line_dum    ;- read header
            while not EOF(1) do begin
               readf,1,xread
               i_ram = fix(xread[0])
               i_ene = fix(xread[1])
               i_pol = fix(xread[2])
               i_az = fix(xread[3])
               esa2_info_str.ene_4x16[i_ram,i_ene,i_pol,i_az] = xread[4]
               esa2_info_str.pol_4x16[i_ram,i_ene,i_pol,i_az] = xread[5]
               esa2_info_str.az_4x16[i_ram,i_ene,i_pol,i_az] = xread[6]
               esa2_info_str.gfactor_4x16[i_ram,i_ene,i_pol,i_az] = xread[7]
               esa2_info_str.ene_sqno_4x16[i_ram,i_ene,i_pol,i_az] = xread[8]
               esa2_info_str.pol_sqno_4x16[i_ram,i_ene,i_pol,i_az] = xread[9]
            endwhile
            close,1
            free_lun,1
         end
         else: dprint,'pol x as does not match'
      endcase
   end
   2: begin                                           ;- IMA
      if size(ima_info_str,/tname) ne 'STRUCT' then $ ;- initialize str
         ima_info_str $
         = {ene_16x64:fltarr(4,32,16,64), $ ;- keV
            pol_16x64:fltarr(4,32,16,64), $ ;- deg.
            az_16x64:fltarr(4,32,16,64), $  ;- deg.
            gfactor_16x64:dblarr(4,32,16,64), $  ;- cm^2 str keV/keV
            ene_sqno_16x64:intarr(4,32,16,64), $ ;- ENERGY-SEQUENCE_NO
            pol_sqno_16x64:intarr(4,32,16,64), $ ;- POLAR-ANGLE-SQUENCE_NO
            enemin_16x64:fltarr(4,32,16,64), $   ;- keV
            enemax_16x64:fltarr(4,32,16,64), $   ;- keV
            polmin_16x64:fltarr(4,32,16,64), $   ;- deg.
            polmax_16x64:fltarr(4,32,16,64), $   ;- deg.
            azmin_16x64:fltarr(4,32,16,64), $    ;- deg.
            azmax_16x64:fltarr(4,32,16,64), $    ;- deg.
            ene_4x16:fltarr(4,32,4,16), $        ;- keV
            pol_4x16:fltarr(4,32,4,16), $        ;- deg.
            az_4x16:fltarr(4,32,4,16), $         ;- deg.
            gfactor_4x16:dblarr(4,32,4,16), $    ;- cm^2 str keV/keV
            ene_sqno_4x16:intarr(4,32,4,16), $   ;- ENERGY-SEQUENCE_NO
            pol_sqno_4x16:intarr(4,32,4,16) }    ;- POLAR-ANGLE-SQUENCE_NO
      case polxaz of
         '16x64': begin
            xread = dblarr(16) & line_dum=''
            openr,1,fname,compress=compress
            readf,1,line_dum    ;- read header
            while not EOF(1) do begin
               readf,1,xread
               i_ram = fix(xread[0])
               i_ene = fix(xread[1])
               i_pol = fix(xread[2])
               i_az = fix(xread[3])
               ima_info_str.ene_16x64[i_ram,i_ene,i_pol,i_az] = xread[4]
               ima_info_str.pol_16x64[i_ram,i_ene,i_pol,i_az] = xread[5]
               ima_info_str.az_16x64[i_ram,i_ene,i_pol,i_az] = xread[6]
               ima_info_str.gfactor_16x64[i_ram,i_ene,i_pol,i_az] = xread[7]
               ima_info_str.ene_sqno_16x64[i_ram,i_ene,i_pol,i_az] = xread[8]
               ima_info_str.pol_sqno_16x64[i_ram,i_ene,i_pol,i_az] = xread[9]
               ima_info_str.enemin_16x64[i_ram,i_ene,i_pol,i_az] = xread[10]
               ima_info_str.enemax_16x64[i_ram,i_ene,i_pol,i_az] = xread[11]
               ima_info_str.polmin_16x64[i_ram,i_ene,i_pol,i_az] = xread[12]
               ima_info_str.polmax_16x64[i_ram,i_ene,i_pol,i_az] = xread[13]
               ima_info_str.azmin_16x64[i_ram,i_ene,i_pol,i_az] = xread[14]
               ima_info_str.azmax_16x64[i_ram,i_ene,i_pol,i_az] = xread[15]
            endwhile
            close,1
            free_lun,1
         end
         '4x16': begin
            xread = dblarr(10) & line_dum=''
            openr,1,fname,compress=compress
            readf,1,line_dum    ;- read header
            while not EOF(1) do begin
               readf,1,xread
               i_ram = fix(xread[0])
               i_ene = fix(xread[1])
               i_pol = fix(xread[2])
               i_az = fix(xread[3])
               ima_info_str.ene_4x16[i_ram,i_ene,i_pol,i_az] = xread[4]
               ima_info_str.pol_4x16[i_ram,i_ene,i_pol,i_az] = xread[5]
               ima_info_str.az_4x16[i_ram,i_ene,i_pol,i_az] = xread[6]
               ima_info_str.gfactor_4x16[i_ram,i_ene,i_pol,i_az] = xread[7]
               ima_info_str.ene_sqno_4x16[i_ram,i_ene,i_pol,i_az] = xread[8]
               ima_info_str.pol_sqno_4x16[i_ram,i_ene,i_pol,i_az] = xread[9]
            endwhile
            close,1
            free_lun,1
         end
         else: dprint,'pol x as does not match'
      endcase
   end
   3: begin                                           ;- IEA
      if size(iea_info_str,/tname) ne 'STRUCT' then $ ;- initialize str
         iea_info_str $
         = {ene_16x64:fltarr(4,32,16,64), $ ;- keV
            pol_16x64:fltarr(4,32,16,64), $ ;- deg.
            az_16x64:fltarr(4,32,16,64), $  ;- deg.
            gfactor_16x64:dblarr(4,32,16,64), $  ;- cm^2 str keV/keV
            ene_sqno_16x64:intarr(4,32,16,64), $ ;- ENERGY-SEQUENCE_NO
            pol_sqno_16x64:intarr(4,32,16,64), $ ;- POLAR-ANGLE-SQUENCE_NO
            enemin_16x64:fltarr(4,32,16,64), $   ;- keV
            enemax_16x64:fltarr(4,32,16,64), $   ;- keV
            polmin_16x64:fltarr(4,32,16,64), $   ;- deg.
            polmax_16x64:fltarr(4,32,16,64), $   ;- deg.
            azmin_16x64:fltarr(4,32,16,64), $    ;- deg.
            azmax_16x64:fltarr(4,32,16,64), $    ;- deg.
            ene_4x16:fltarr(4,32,4,16), $        ;- keV
            pol_4x16:fltarr(4,32,4,16), $        ;- deg.
            az_4x16:fltarr(4,32,4,16), $         ;- deg.
            gfactor_4x16:dblarr(4,32,4,16), $    ;- cm^2 str keV/keV
            ene_sqno_4x16:intarr(4,32,4,16), $   ;- ENERGY-SEQUENCE_NO
            pol_sqno_4x16:intarr(4,32,4,16) }    ;- POLAR-ANGLE-SQUENCE_NO
      case polxaz of
         '16x64': begin
            xread = dblarr(16) & line_dum=''
            openr,1,fname,compress=compress
            readf,1,line_dum    ;- read header
            while not EOF(1) do begin
               readf,1,xread
               i_ram = fix(xread[0])
               i_ene = fix(xread[1])
               i_pol = fix(xread[2])
               i_az = fix(xread[3])
               iea_info_str.ene_16x64[i_ram,i_ene,i_pol,i_az] = xread[4]
               iea_info_str.pol_16x64[i_ram,i_ene,i_pol,i_az] = xread[5]
               iea_info_str.az_16x64[i_ram,i_ene,i_pol,i_az] = xread[6]
               iea_info_str.gfactor_16x64[i_ram,i_ene,i_pol,i_az] = xread[7]
               iea_info_str.ene_sqno_16x64[i_ram,i_ene,i_pol,i_az] = xread[8]
               iea_info_str.pol_sqno_16x64[i_ram,i_ene,i_pol,i_az] = xread[9]
               iea_info_str.enemin_16x64[i_ram,i_ene,i_pol,i_az] = xread[10]
               iea_info_str.enemax_16x64[i_ram,i_ene,i_pol,i_az] = xread[11]
               iea_info_str.polmin_16x64[i_ram,i_ene,i_pol,i_az] = xread[12]
               iea_info_str.polmax_16x64[i_ram,i_ene,i_pol,i_az] = xread[13]
               iea_info_str.azmin_16x64[i_ram,i_ene,i_pol,i_az] = xread[14]
               iea_info_str.azmax_16x64[i_ram,i_ene,i_pol,i_az] = xread[15]
            endwhile
            close,1
            free_lun,1
         end
         '4x16': begin
            xread = dblarr(10) & line_dum=''
            openr,1,fname,compress=compress
            readf,1,line_dum    ;- read header
            while not EOF(1) do begin
               readf,1,xread
               i_ram = fix(xread[0])
               i_ene = fix(xread[1])
               i_pol = fix(xread[2])
               i_az = fix(xread[3])
               iea_info_str.ene_4x16[i_ram,i_ene,i_pol,i_az] = xread[4]
               iea_info_str.pol_4x16[i_ram,i_ene,i_pol,i_az] = xread[5]
               iea_info_str.az_4x16[i_ram,i_ene,i_pol,i_az] = xread[6]
               iea_info_str.gfactor_4x16[i_ram,i_ene,i_pol,i_az] = xread[7]
               iea_info_str.ene_sqno_4x16[i_ram,i_ene,i_pol,i_az] = xread[8]
               iea_info_str.pol_sqno_4x16[i_ram,i_ene,i_pol,i_az] = xread[9]
            endwhile
            close,1
            free_lun,1
         end
         else: dprint,'pol x as does not match'
      endcase
   end
   else: dprint, 'Sensor does not match'
endcase

endfor                          ;- i_file loop

end
