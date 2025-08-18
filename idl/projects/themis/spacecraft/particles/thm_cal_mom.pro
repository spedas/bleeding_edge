;+
;Deprecated, 8-feb-2010,jmm
;-

pro thm_cal_mom,scs=scs, create=create, verbose=verbose

message, /info, 'This program is obsolete and is no longer used in TDAS'
message, /info, 'To obtain calibrated THEMIS MOM data, please call THM_LOAD_MOM, '
message, /info, 'without setting /raw, or type = ''raw''.'

; This file section will need to be
;sc = 'tha'
;calsource = !themis
;calsource.remote_data_dir = 'http://sprg.ssl.berkeley.edu/~davin/themis/'   ; temporary cluge, comment out when files are in place
;cal_relpathname = sc+'/l1/mom/0000/'+sc+'_l1_mom_cal_v01.sav'
;cal_file = file_retrieve(cal_relpathname, _extra=calsource)
;if file_test(cal_file) then  restore,file=cal_file,verbose=verbose


;if keyword_set(create) then begin
;   cal_data = replicate(1.,13,4)
;   cal_sc_pot = 100./(2.^15) + 0.      ; default conversion for space_craft potential.
;   Comment="Version 1 of the THEMIS moment calibration"
;   save,file=cal_file,cal_data,cal_sc_pot,description=comment
;endif
;
;
;if not keyword_set(scs) then scs = 'th'+['a']
;
;instrs= ['si','ei','ee','se'] +'m'  ;This seems odd!   Order needs checking!;
;
;for s=0,n_elements(scs)-1 do begin
;  sc = scs[s]
;  get_data,sc+'_mom',ptr=p
;  get_data,sc+'_mom_pot',ptr=pot
;
;  if keyword_set(p) then begin
;    dim = size(/dimen,*p.y)
;
;    for i=0,3 do begin
;       instr = instrs[i]
;
;       dens  = (*p.y)[*,0,i]  * cal_data[0,i]
;
;       vel = fltarr(dim[0],3)
;       for m = 0,2 do vel[*,m]  =  (*p.y)[*,1+m,i]  * cal_data[1+m,i] / dens
;
;       pt = fltarr(dim[0],6)
;       for m = 0,5 do pt[*,m]  =  (*p.y)[*,4+m,i]  * cal_data[4+m,i]
;
;       hf = fltarr(dim[0],3)
;       for m = 0,2 do hf[*,m]  =  (*p.y)[*,10+m,i]  * cal_data[10+m,i]
;
;       store_data,sc+'_'+instr+'_dens',data={x:p.x,  y:dens}
;       store_data,sc+'_'+instr+'_vel', data={x:p.x,  y:vel }
;       store_data,sc+'_'+instr+'_pt',  data={x:p.x,  y:pt  }
;       store_data,sc+'_'+instr+'_hf',  data={x:p.x,  y:hf  }
;
;    endfor
;
;    sc_pot = *pot.y * cal_sc_pot
;    store_data,sc+'_scm_pot',data={x:p.x,  y:sc_pot }


;  endif

;endfor


end
