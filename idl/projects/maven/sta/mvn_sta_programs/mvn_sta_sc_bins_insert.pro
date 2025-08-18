;+
; FUNCTION:        MVN_STA_SC_BINS_INSERT
;
; PURPOSE:         Insert s/c blockage into new data structure
;
; INPUT:           orig_dat - data structure containing spacecraft
;                             blockage
;                  new_dat  - new data structure containig data with
;                             spacecraft blockage removed
;
; OUTPUT:          None.
;
; KEYWORDS:        None.
;
; CREATED BY:      Roberto Livi on 2015-10-07.
;
; VERSION:
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2015-11-03 16:35:37 -0800 (Tue, 03 Nov 2015) $
; $LastChangedRevision: 19226 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/mvn_sta_programs/mvn_sta_sc_bins_insert.pro $
;
;-
pro mvn_sta_sc_bins_insert, orig_dat, new_dat

  ;;-------------------------------------------
  ;; Copy over old structure into new structure
  new_dat = orig_dat

  ;;-------------------------------------------
  ;; Fill in new structure with blockage
  ss = size(orig_dat)
  if ss[2] eq 8 then begin
     ss   = size(orig_dat.data)
     bins = orig_dat.bins_sc
     if size(bins, /n_dimension) eq 2 then begin
        if ss[n_elements(ss)-2] eq 3 then bins = transpose(rebin(bins, ss[1], ss[3], ss[2]), [0, 2, 1])
        if ss[n_elements(ss)-2] eq 4 then bins = transpose(rebin(bins, ss[1], ss[3], ss[2], ss[4]), [0, 2, 1, 3])
     endif 
     if size(bins, /n_dimension) eq 1 then begin
        if ss[n_elements(ss)-2] eq 3 then bins = transpose(rebin(orig_dat.bins_sc, ss[2], ss[1], ss[3]), [1, 0, 2])
        if ss[n_elements(ss)-2] eq 2 then bins = transpose(rebin(orig_dat.bins_sc, ss[2], ss[1]), [1, 0])
     endif 
     new_dat.data = orig_dat.data * bins
     if tag_exist(new_dat, 'eflux') then new_dat.eflux = orig_dat.eflux * bins
  endif

end




