;+
; PROCEDURE:
;     kgy_read_fov
; PURPOSE:
;     reads in Kaguya MAP/PACE FOV files
;     and stores data in a common block (kgy_pace_com)
; CALLING SEQUENCE:
;     kgy_raed_fov, files
; INPUTS:
;     files: full paths to the FOV files (gziped or decompressed)
;            e.g., ['dir/esas1-ch_angle', $
;                   'dir/esas1-pol_angle-RAM0', ...]
; KEYWORDS:
;     load: if set, download and read in publicly available files
;           (override any inputs) 
; CREATED BY:
;     Yuki Harada on 2014-07-01
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2018-05-18 00:03:47 -0700 (Fri, 18 May 2018) $
; $LastChangedRevision: 25235 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/pace/kgy_read_fov.pro $
;-

pro kgy_read_fov, files, load=load, verbose=verbose, _extra=_ex

@kgy_pace_com

if keyword_set(load) then begin
   files = ''
   s = kgy_file_source(remote_data_dir='http://research.ssl.berkeley.edu/~haraday/data/kaguya/',last_version=0, _extra=_ex)
   pfs = 'public/FOV_ANGLE_*/'+ $
         ['ESAS1/esas1*','ESAS2/esas2*','IEA/iea*','IMA/ima*']
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

if strmatch(fname,'*esas1*') eq 1 then fsensor = 0
if strmatch(fname,'*esas2*') eq 1 then fsensor = 1
if strmatch(fname,'*ima*') eq 1 then fsensor = 2
if strmatch(fname,'*iea*') eq 1 then fsensor = 3
if strmatch(fname,'*ch_angle*') eq 1 then chpol = 'ch'
if strmatch(fname,'*pol_angle*') eq 1 then chpol = 'pol'
if strmatch(fname,'*RAM0*') eq 1 then ram = 0
if strmatch(fname,'*RAM1*') eq 1 then ram = 1
if strmatch(fname,'*RAM2*') eq 1 then ram = 2
if strmatch(fname,'*RAM3*') eq 1 then ram = 3
if strmatch(fname,'*RAM4*') eq 1 then ram = 4
if strmatch(fname,'*RAM5*') eq 1 then ram = 5
if strmatch(fname,'*RAM6*') eq 1 then ram = 6
if strmatch(fname,'*RAM7*') eq 1 then ram = 7
if strmatch(fname,'*.gz') eq 1 then compress = 1 else compress = 0

case fsensor of
   0: begin                                           ;- ESA-S1
      if size(esa1_fov_str,/tname) ne 'STRUCT' then $ ;- initialize str
         esa1_fov_str $
         = {az64:fltarr(64), $        ;- deg.
            az16:fltarr(16), $        ;- deg.
            ene:fltarr(8,32), $       ;- keV
            pol16:dblarr(8,32,16), $  ;- deg.
            pol4:intarr(8,32,4) }     ;- deg.
      case chpol of
         'ch': begin
            xread3 = dblarr(3) & xread2 = dblarr(2) & line_dum='' & i_az = 0
            openr,1,fname,compress=compress
            readf,1,line_dum    ;- read header
            while not EOF(1) do begin
               readf,1,line_dum
               reads,line_dum,xread2
               i_az = fix(xread2[0])
               if i_az lt 16 then begin
                  reads,line_dum,xread3
                  esa1_fov_str.az64[i_az] = xread3[1]
                  esa1_fov_str.az16[i_az] = xread3[2]
               endif else begin
                  reads,line_dum,xread2
                  esa1_fov_str.az64[i_az] = xread2[1]
               endelse
            endwhile
            close,1
            free_lun,1
         end
         'pol': begin
            xread5 = dblarr(5) & xread4 = dblarr(4) & line_dum='' & i_pol = 0
            openr,1,fname,compress=compress
            readf,1,line_dum    ;- read header
            while not EOF(1) do begin
               readf,1,line_dum
               reads,line_dum,xread4
               i_ene = fix(xread4[0])
               i_pol = fix(xread4[1])
               if i_pol lt 4 then begin
                  reads,line_dum,xread5
                  esa1_fov_str.ene[ram,i_ene] = xread5[2]
                  esa1_fov_str.pol16[ram,i_ene,i_pol] = xread5[3]
                  esa1_fov_str.pol4[ram,i_ene,i_pol] = xread5[4]
               endif else begin
                  reads,line_dum,xread4
                  esa1_fov_str.ene[ram,i_ene] = xread4[2]
                  esa1_fov_str.pol16[ram,i_ene,i_pol] = xread4[3]
               endelse
            endwhile
            close,1
            free_lun,1
         end
      endcase
   end
   1: begin                                           ;- ESA-S2
      if size(esa2_fov_str,/tname) ne 'STRUCT' then $ ;- initialize str
         esa2_fov_str $
         = {az64:fltarr(64), $        ;- deg.
            az16:fltarr(16), $        ;- deg.
            ene:fltarr(8,32), $       ;- keV
            pol16:dblarr(8,32,16), $  ;- deg.
            pol4:intarr(8,32,4) }     ;- deg.
      case chpol of
         'ch': begin
            xread3 = dblarr(3) & xread2 = dblarr(2) & line_dum='' & i_az = 0
            openr,1,fname,compress=compress
            readf,1,line_dum    ;- read header
            while not EOF(1) do begin
               readf,1,line_dum
               reads,line_dum,xread2
               i_az = fix(xread2[0])
               if i_az lt 16 then begin
                  reads,line_dum,xread3
                  esa2_fov_str.az64[i_az] = xread3[1]
                  esa2_fov_str.az16[i_az] = xread3[2]
               endif else begin
                  reads,line_dum,xread2
                  esa2_fov_str.az64[i_az] = xread2[1]
               endelse
            endwhile
            close,1
            free_lun,1
         end
         'pol': begin
            xread5 = dblarr(5) & xread4 = dblarr(4) & line_dum='' & i_pol = 0
            openr,1,fname,compress=compress
            readf,1,line_dum    ;- read header
            while not EOF(1) do begin
               readf,1,line_dum
               reads,line_dum,xread4
               i_ene = fix(xread4[0])
               i_pol = fix(xread4[1])
               if i_pol lt 4 then begin
                  reads,line_dum,xread5
                  esa2_fov_str.ene[ram,i_ene] = xread5[2]
                  esa2_fov_str.pol16[ram,i_ene,i_pol] = xread5[3]
                  esa2_fov_str.pol4[ram,i_ene,i_pol] = xread5[4]
               endif else begin
                  reads,line_dum,xread4
                  esa2_fov_str.ene[ram,i_ene] = xread4[2]
                  esa2_fov_str.pol16[ram,i_ene,i_pol] = xread4[3]
               endelse
            endwhile
            close,1
            free_lun,1
         end
      endcase
   end
   2: begin                     ;- IMA
      if size(ima_fov_str,/tname) ne 'STRUCT' then $ ;- initialize str
         ima_fov_str $
         = {az64:fltarr(64), $        ;- deg.
            az16:fltarr(16), $        ;- deg.
            ene:fltarr(4,32), $       ;- keV
            pol16:dblarr(4,32,16), $  ;- deg.
            pol4:intarr(4,32,4) }     ;- deg.
      case chpol of
         'ch': begin
            xread3 = dblarr(3) & xread2 = dblarr(2) & line_dum='' & i_az = 0
            openr,1,fname,compress=compress
            readf,1,line_dum    ;- read header
            while not EOF(1) do begin
               readf,1,line_dum
               reads,line_dum,xread2
               i_az = fix(xread2[0])
               if i_az lt 16 then begin
                  reads,line_dum,xread3
                  ima_fov_str.az64[i_az] = xread3[1]
                  ima_fov_str.az16[i_az] = xread3[2]
               endif else begin
                  reads,line_dum,xread2
                  ima_fov_str.az64[i_az] = xread2[1]
               endelse
            endwhile
            close,1
            free_lun,1
         end
         'pol': begin
            xread5 = dblarr(5) & xread4 = dblarr(4) & line_dum='' & i_pol = 0
            openr,1,fname,compress=compress
            readf,1,line_dum    ;- read header
            while not EOF(1) do begin
               readf,1,line_dum
               reads,line_dum,xread4
               i_ene = fix(xread4[0])
               i_pol = fix(xread4[1])
               if i_pol lt 4 then begin
                  reads,line_dum,xread5
                  ima_fov_str.ene[ram,i_ene] = xread5[2]
                  ima_fov_str.pol16[ram,i_ene,i_pol] = xread5[3]
                  ima_fov_str.pol4[ram,i_ene,i_pol] = xread5[4]
               endif else begin
                  reads,line_dum,xread4
                  ima_fov_str.ene[ram,i_ene] = xread4[2]
                  ima_fov_str.pol16[ram,i_ene,i_pol] = xread4[3]
               endelse
            endwhile
            close,1
            free_lun,1
         end
      endcase
   end
   3: begin                     ;- IEA
      if size(iea_fov_str,/tname) ne 'STRUCT' then $ ;- initialize str
         iea_fov_str $
         = {az64:fltarr(64), $        ;- deg.
            az16:fltarr(16), $        ;- deg.
            ene:fltarr(4,32), $       ;- keV
            pol16:dblarr(4,32,16), $  ;- deg.
            pol4:intarr(4,32,4) }     ;- deg.
      case chpol of
         'ch': begin
            xread3 = dblarr(3) & xread2 = dblarr(2) & line_dum='' & i_az = 0
            openr,1,fname,compress=compress
            readf,1,line_dum    ;- read header
            while not EOF(1) do begin
               readf,1,line_dum
               reads,line_dum,xread2
               i_az = fix(xread2[0])
               if i_az lt 16 then begin
                  reads,line_dum,xread3
                  iea_fov_str.az64[i_az] = xread3[1]
                  iea_fov_str.az16[i_az] = xread3[2]
               endif else begin
                  reads,line_dum,xread2
                  iea_fov_str.az64[i_az] = xread2[1]
               endelse
            endwhile
            close,1
            free_lun,1
         end
         'pol': begin
            xread5 = dblarr(5) & xread4 = dblarr(4) & line_dum='' & i_pol = 0
            openr,1,fname,compress=compress
            readf,1,line_dum    ;- read header
            while not EOF(1) do begin
               readf,1,line_dum
               reads,line_dum,xread4
               i_ene = fix(xread4[0])
               i_pol = fix(xread4[1])
               if i_pol lt 4 then begin
                  reads,line_dum,xread5
                  iea_fov_str.ene[ram,i_ene] = xread5[2]
                  iea_fov_str.pol16[ram,i_ene,i_pol] = xread5[3]
                  iea_fov_str.pol4[ram,i_ene,i_pol] = xread5[4]
               endif else begin
                  reads,line_dum,xread4
                  iea_fov_str.ene[ram,i_ene] = xread4[2]
                  iea_fov_str.pol16[ram,i_ene,i_pol] = xread4[3]
               endelse
            endwhile
            close,1
            free_lun,1
         end
      endcase
   end
endcase

endfor                          ;- i_file loop

end
