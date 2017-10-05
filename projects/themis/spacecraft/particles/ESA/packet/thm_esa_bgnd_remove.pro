;+
;PROCEDURE: thm_esa_bgnd_remove
;
;PURPOSE: 
;Background removal code from Vassilis
;This abstracts the code as the same algorithm is used in many of the get_th?_pexx routines  
;INPUT:   
;  dat:  The dat structure from the parent routine
;  gf: The geometric factor array from the parent routine
;  eff: The efficiency array from the parent routine
;  nenergy: The number of energy bins for the data being calibrated
;  nbins: The number of angle bins for the data being calibrated
;  theta: angles in theta for the angle bins of the data being calibrated 
;
;OUTPUTS:
;  Modifies the dat structure that was provided to it.
;
;KEYWORDS:
;
;/bdnd_remove:  Turn on ESA background removal.
;
;bgnd_type(Default 'anode'): Set to string naming background removal type:
;'angle','omni', or 'anode'.
;
;bgnd_npoints(Default = 3): Set to the number of lowest values points to average over when determining background.
;              
;bgnd_scale(Default=1): Set to a scaling factor that the background will be multiplied by before it is subtracted
;
;HISTORY:
; 2016-08-23 - now called from thm_pgs_clean_esa instead of thm_part_dist
;            - takes full structure input instead of copying fields
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2016-08-24 18:29:05 -0700 (Wed, 24 Aug 2016) $
; $LastChangedRevision: 21724 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/ESA/packet/thm_esa_bgnd_remove.pro $
;- 

pro thm_esa_bgnd_remove, dat, bgnd_scale = bgnd_scale, bgnd_type = bgnd_type, $
                         bgnd_npoints = bgnd_npoints, bgnd_remove=bgnd_remove, $
                         esa_bgnd_remove=esa_bgnd_remove, _extra = _extra

    compile_opt hidden


  ;default options
  default = {bgnd_remove:1, bgnd_type:'anode', bgnd_npoints:3, bgnd_scale:1.0}

  ;use options appended to structure if present (backward compatibility)
  if in_set(tag_names(dat),'ESA_BGND') then begin
    struct_assign, dat.esa_bgnd, default, /nozero
  endif

  ;use explicitly passed options preferentially
  if undefined(bgnd_remove) then bgnd_remove = default.bgnd_remove
  if ~undefined(esa_bgnd_remove) then bgnd_remove = esa_bgnd_remove
  if ~keyword_set(bgnd_remove) then return

  if ~keyword_set(bgnd_scale) then bgnd_scale=default.bgnd_scale
  
  if ~keyword_set(bgnd_type) then begin
    bgnd_type=strlowcase(default.bgnd_type)
  endif else begin
    bgnd_type=strlowcase(bgnd_type)
  endelse
  
  if ~keyword_set(bgnd_npoints) then bgnd_npoints=default.bgnd_npoints
    

  gfeff = dat.gf*dat.eff
  narrdims=size(dat.data,/dimensions)
  case bgnd_type of
  'angle' : bgnd= gfeff * (make_array(dat.nenergy,value=1,/float) # $
            minjmin(dat.data/dat.gf,dim=1,jmin_points=bgnd_npoints)) ;  2d or 1d
  'omni' : begin
             if (n_elements(narrdims) eq 1) then bgnd=gfeff * $
               minjmin(dat.data/dat.gf,jmin_points=bgnd_npoints)
             if (n_elements(narrdims) eq 2) then bgnd=gfeff * $
               minjmin(average(dat.data/dat.gf,2),jmin_points=bgnd_npoints)
           end
  'anode' : begin
             if (n_elements(narrdims) eq 1) then bgnd=gfeff * $
               minjmin(dat.data/dat.gf,jmin_points=bgnd_npoints)
             if (n_elements(narrdims) eq 2) then begin ; here compute anode dependent bgnd, 22.5 deg at a time
               bgnd = make_array(dat.nenergy,dat.nbins,value=0,/float)
;               nths=16 ; max number of anodes, general case
;               thmin=[0,22.5,45.,56.25,67.5,73.125,78.75,84.375] & thmin=-[90.-thmin,-thmin]
;               thmax=[22.5,45.,56.25,67.5,73.125,78.75,84.375,90.] & thmax=-[90.-thmax,-thmax]
               ;set theta bins
               thbins = [67.5, 45.0, 33.75, 22.5, 16.875, 11.25, 5.625] 
               thmin = [-90, -thbins, 0, reverse(thbins) ] 
               thmax =      [-thbins, 0, reverse(thbins), 90]
               for ith=0, n_elements(thmin)-1 do begin 
                 ian=where((dat.theta[0,*] ge thmin[ith]) and (dat.theta[0,*] lt thmax[ith]),jan)
                 if jan gt 0 then begin
                   if jan eq 1 then begin
                    bgnd[*,ian]=gfeff[*,ian] * $
                     minjmin(dat.data[*,ian]/dat.gf[*,ian],jmin_points=bgnd_npoints)
                   endif else begin
                     bgnd[*,ian]=gfeff[*,ian] * $
                     minjmin(average(dat.data[*,ian]/dat.gf[*,ian],2),jmin_points=bgnd_npoints)
                   endelse
                 endif
               endfor
             endif
           end
  else:    dprint,'unknown bgnd_type entered'
  endcase
  dat.data=dat.data-bgnd*bgnd_scale > 0.
;  izeros=where(dat le 0., jzeros)
;  if (jzeros gt 0) then dat[izeros]=0.

end
  
