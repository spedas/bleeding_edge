;+
; PROCEDURE get_fixed_pixel_graph
;
; :DESCRIPTION:
; 	Generate a tplot variable containing data values for 
; 	a fixed pixel, with given beam number and range gate number. 
;
; :PARAMS:
;   vn: name of the tplot variable from which values for a fixed pixel are extracted 
; 
; :KEYWORDS:
;   beam: beam number for a pixel to be extracted
;   range_gate: range gate number for a pixel to be extracted
;   newvn: if a string is set, the new tplot variable is generated with a name given by this keyword
;    
; :EXAMPLES:
;   get_fixed_pixel_graph, 'sd_hok_vlos_1', beam=3, range_gate=65
;
; :AUTHOR:
; 	Tomo Hori (E-mail: horit@stelab.nagoya-u.ac.jp)
;
; :HISTORY:
; 	2011/06/22: Created
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2012-03-16 14:46:35 -0700 (Fri, 16 Mar 2012) $
; $LastChangedRevision: 10146 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/ground/radar/superdarn/get_fixed_pixel_graph.pro $
;-
PRO get_fixed_pixel_graph, vn, beam=beam, range_gate=rgate, newvn=newvn
  
  ;Check the arguments and keywords
  npar = n_params()
  if npar ne 1 then return
  if ~keyword_set(beam) or ~keyword_set(rgate) then return
  beam = fix(beam) & rgate = fix(rgate)
  if beam lt 0 or beam gt 22 or rgate lt 0 or rgate gt 220 then return
  vn = tnames(vn)
  if vn[0] eq '' then return
  
  ;strings consisting of variable names
  prefix = strmid(vn, 0,7) ;e.g, 'sd_hok_'
  suf = strmid(vn,0,1,/reverse) 
  azm_vn = prefix+'azim_no_'+suf
  
  ;Get data from tplot vars
  get_data, vn, data=d, dl=var_dl, lim=var_lim
  vartime = d.x & var = d.y & var_v = d.v
  get_data, azm_vn, data=d 
  azmno = d.y 
  
  if beam gt max(azmno,/nan) or rgate ge n_elements(var[0,*]) then begin
    print, 'Given beam no (',beam,') or rgate no (',rgate,') is out of range'
    return
  endif
  
  idx_bm = where( azmno eq beam )
  newtime = vartime[idx_bm]
  newvar = var[idx_bm,rgate]
  if (size(var_v))[0] eq 2 then new_v=var_v[idx_bm,*] else new_v=var_v
  
  if ~keyword_set(newvn) then begin
    
    newvn = vn +'_bm'+string(beam,'(I02)')+'rg'+string(rgate,'(I03)')
  endif
  
  store_data, newvn[0], $
    data={x:newtime, y:newvar, v:new_v}, $
    lim={ytitle:'bm:'+string(beam,'(I02)')+',rg:'+string(rgate,'(I03)')+'!C'+var_lim.ztitle}
  
  ;Add the zrange as yrange if exists
  str_element, var_lim, 'zrange', success=s
  if s eq 1 then options, newvn, 'yrange', var_lim.zrange
   
  return
end
