;+
;;FUNCTION: mvn_lpw_prd_swp_extract
;
;;INPUT: time
;   time: in format of 'YYYY-MM-DD/HH:MM:SS'
;
;;KEYWORDS: tnameI=tnameI, tnameV=tnameV, prb=prb
;   tnameI : default is 'mvn_lpw_swp1_I1'/'mvn_lpw_swp2_I2'
;   tnameV : default is 'mvn_lpw_swp1_I1_pot'/'mvn_lpw_swp2_I2_pot'
;   prb    : probe no 1/2
;;OUTPUT
;   returns a structure contains, T, U, and I
;
;;Examples:
;   swp = mm_mvn_lpw_swp_extract('2014-07-07/19:34:00',tnameI='mvn_lpw_swp2_I2',tnameV='mvn_lpw_swp2_I2_pot')
;   swp = mm_mvn_lpw_swp_extract('2014-07-07/19:34:00',prb=1)
;   swp = mm_mvn_lpw_swp_extract('2014-07-07/19:34:00')
;;CREATED BY:  Michiko W. Morooka Apr. 2014
;FILE      : mvn_lpw_prd_swp_extract.pro
;VERSION:   0.0
;CREATED:             M. Morooka 04/18/14
;LAST MODIFICATION:   M. Morooka 11/22/14 added to mvn_lpr_prd product
;
;-

;------- this_version_mvn_lpw_prd_swp_extract -------------
function this_version_mvn_lpw_prd_swp_extract
  ver = 2.2
  pdr_ver= 'version mvn_lpw_prd_lp_n_t: ' + string(ver,format='(F4.1)')
  return, pdr_ver
end
;--------------- this_version_mvn_lpw_prd_swp_extract -----

;==================================================================================================
function mvn_lpw_prd_swp_extract, time, tnameI=tnameI, tnameV=tnameV, prb=prb, PP=PP, dwnswp=dwnswp, upswp=upswp

;------ the version number of this routine --------------------------------------------------------
  t_routine=SYSTIME(0)
  pdr_ver= this_version_mvn_lpw_prd_swp_extract()
;--------------------------------------------------------------------------------------------------

  if keyword_set(time) eq 0 then begin
    ;doc_library, 'mm_mvn_lpw_swp_extract'  & return, 0
    ctime,t,npoints=1,/silent ;, prompt="Use cursor to select a time"
    time = t
  endif
  if keyword_set(prb) eq 0 then prb = 1
  prb = string(prb,format='(i01)')
  if keyword_set(tnameI) eq 0 then tnameI = 'mvn_lpw_swp'+prb+'_I'+prb
  if keyword_set(tnameV) eq 0 then tnameV = 'mvn_lpw_swp'+prb+'_I'+prb+'_pot'
  
  time = time_double(time)
  
  if keyword_set(PP) then begin
    if size(PP,/type) eq 8 then begin
      t_pp = where(PP.time ge time)
      if (n_elements(t_pp) eq 1) then if(t_pp lt 0) then begin & print, 'No muched time.' & return, 0 &  endif
      t_pp = t_pp(0)
      swp = PP(t_pp)
      goto, OUT
    endif
  endif
  
  ;----- get sweep dataset from tplot value -----------------------------------
  get_data,tnameV,data=data_V,limit=limit_V,dlimit=dlimit_V
  get_data,tnameI,data=data_I,limit=limit_I,dlimit=dlimit_I
  T0 = data_V.x & V0 = data_V.y & I0 = data_I.y
  ;--- Split lp_data into sweep blocks ----------------------------------------
  p_et = where(ts_diff(T0,1) lt -1.0)
  p_st = [0, p_et+1] & p_et = [p_et, n_elements(T0)-1]
  blk_no = n_elements(p_st)
  ;----- pick up sweep set for input time, setup sweep dataset ----------------
  T = T0(p_st)
  pkt = where( T le time) & pkt = pkt(n_elements(pkt)-1)
  if pkt eq -1 then begin & print, 'no matching time' & return, 0 & endif
    
  swp_t = T0(p_st(pkt):p_et(pkt)) & swp_u = V0(p_st(pkt):p_et(pkt)) & swp_i = I0(p_st(pkt):p_et(pkt))
  if keyword_set(dwnswp) ne 0 and keyword_set(PP) eq 0 then begin
    swp_t = swp_t(0:63) &  swp_u = swp_u(0:63) & swp_i = swp_i(0:63)
  endif
  if keyword_set(upswp) ne 0  and keyword_set(PP) eq 0 then begin
    swp_t = swp_t(64:127) &  swp_u = swp_u(64:128) & swp_i = swp_i(64:128)
  endif
  
  if keyword_set(PP) then begin
    ;if keyword_set(dlimit_V) then PP = mm_swp_setupparam(dlimit_V) $
    ;else                          PP = mm_swp_setupparam('MAVEN')    
    PP = mvn_lpw_prd_lp_swp_setupparam('created by mm_mvn_lpw_swp_extract')
    
    PP.time_l0 = swp_t & PP.voltage_l0 = swp_u & PP.current_l0 = swp_i
    PP.xlim = [min(swp_u),max(swp_u)]
    PP.ptitle = strmid(PP.proj,0,5)+'_P'+prb+'_'+time_string(swp_t(0))+'-'+strmid(time_string(swp_t(n_elements(swp_t)-1)),11,18)

    if keyword_set(dwnswp) ne 0 then begin
      swp_t = swp_t(0:63) &  swp_u = swp_u(0:63) & swp_i = swp_i(0:63)
    endif
    if keyword_set(upswp) ne 0 then begin
      swp_t = swp_t(64:127) &  swp_u = swp_u(64:127) & swp_i = swp_i(64:127)
    endif
    PP.time = swp_t(0)    
    vind = sort(swp_u) & swp_u = swp_u(vind) & swp_i = swp_i(vind)
    PP.voltage = swp_u & PP.current = swp_i
    swp = PP
  endif else begin
    swp = create_struct('T',swp_t,'U',swp_u,'I',swp_i)    
  endelse
OUT:
  return, swp
  
end
;--------------------------------------- mm_mvn_lpw_swp_extract -----