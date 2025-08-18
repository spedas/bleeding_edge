;+
;NAME:
; thm_get_fgm_quality_flags
;
;PURPOSE:
; returns an spd_qf_list object with quality flags
;
;CALLING SEQUENCE:
; fgm_qf = thm_get_fgm_quality_flags('tha',trange=trange) ;
;
;INPUT:
; probe = string, has to me a single probe 'a' or 'b' etc
;
;KEYWORDS:
; trange = time range
;
;OUTPUT:
; fgm_qf = quality flags for FGM
;
;EXAMPLES:
; qf = thm_get_fgm_quality_flags('a',trange=['2014-02-01/00:00:00','2014-02-05/00:00:00'])
; qf->qf_print()
;
;NOTES:
;Quality flags:
;     1:boom not deployed, 2:in shadow, 3:uncorrected shadow, 4:noisy
;     waveforms, 8:Bz estimated from spin-plane components
;
;FGM/SCM boom deploy:
;THEMIS_A: 2007/056 21:00
;THEMIS_B: 2007/056 10:20
;THEMIS_C: 2007/056 09:40
;THEMIS_D: 2007/058 00:05
;THEMIS_E: 2007/058 00:40
;
;EFI deploy completed:
;THEMIS_A: spin plane: 2008/012 21:43
;axial: 2008/014 16:30
;THEMIS_B: spin plane: 2007/321 18:43
;axial: 2007/322 06:05
;THEMIS_C: spin plane: 2007/134 22:25
;axial: 2007/136 20:40
;THEMIS_D: spin plane: 2007/156 22:50
;axial: 2007/158 17:40
;THEMIS_E: spin plane: 2007/156 23:55
;axial: 2007/158 18:45
;
;Data for thc are wrong for 2011:
;
;Nov 26 10:10 – Nov 26 24:00
;Nov 28 23:10 – Nov 29 03:00
;Nov 30 05:00 – Nov 30 24:00
;Dec 07 15:00 – Dec 08 24:00
;Dec 27 15:00 – Dec 27 24:00
;
;Data for thb are wrong for 2012:;
;Jan 04 20:45 – Jan 04 24:00
;
;RELATED:
;spd_qf_list__define
;
;HISTORY:;
;$LastChangedBy: jimm $
;$LastChangedDate: 2024-11-20 12:14:41 -0800 (Wed, 20 Nov 2024) $
;$LastChangedRevision: 32969 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_get_fgm_quality_flags.pro $
;-

function thm_get_fgm_quality_flags, probe, trange=trange

  compile_opt idl2
  ; boom deployment times
  if (probe eq 'a') then begin
    t1 = time_double('2007/056 21:00', TFORMAT='YYYY/DOY hh:mm')
    t2 = time_double('2008/014 16:30', TFORMAT='YYYY/DOY hh:mm')
  endif else if (probe eq 'b') then begin
    t1 = time_double('2007/056 21:00', TFORMAT='YYYY/DOY hh:mm')
    t2 = time_double('2007/322 06:05', TFORMAT='YYYY/DOY hh:mm')
  endif else if (probe eq 'c') then begin
    t1 = time_double('2007/056 21:00', TFORMAT='YYYY/DOY hh:mm')
    t2 = time_double('2007/136 20:40', TFORMAT='YYYY/DOY hh:mm')
  endif else if (probe eq 'd') then begin
    t1 = time_double('2007/058 21:00', TFORMAT='YYYY/DOY hh:mm')
    t2 = time_double('2007/158 17:40', TFORMAT='YYYY/DOY hh:mm')
  endif else if (probe eq 'e') then begin
    t1 = time_double('2007/058 21:00', TFORMAT='YYYY/DOY hh:mm')
    t2 = time_double('2007/158 18:45', TFORMAT='YYYY/DOY hh:mm')
  endif else begin
    t1 = time_double('2007/001 00:00', TFORMAT='YYYY/DOY hh:mm')
    t2 = time_double('2007/001 00:00', TFORMAT='YYYY/DOY hh:mm')
  endelse


  if (keyword_set(trange) && (n_elements(trange) eq 2) && (time_double(trange[1]) ge time_double(trange[0]))) then begin
    trange = time_double(trange)
    if (trange[0] ge t2) then begin
      fgm_qf= obj_new('SPD_QF_LIST', t_start=[trange[0]], t_end=[trange[1]], qf_bits=[0])
    endif else if (trange[1] le t1) then begin
      fgm_qf= obj_new('SPD_QF_LIST', t_start=[trange[0]], t_end=[trange[1]], qf_bits=[0])
    endif else if (trange[0] lt t1) and (trange[1] gt t2) then begin
      fgm_qf= obj_new('SPD_QF_LIST', t_start=[trange[0],t1,t2], t_end=[t1,t2,trange[1]], qf_bits=[0,1,0])
    endif else if (trange[0] lt t1) and (trange[1] le t2) then begin
      fgm_qf= obj_new('SPD_QF_LIST', t_start=[trange[0],t1], t_end=[t1,trange[1]], qf_bits=[0,1])
    endif else if (trange[0] ge t1) and (trange[1] gt t2) then begin
      fgm_qf= obj_new('SPD_QF_LIST', t_start=[trange[0],t2], t_end=[t2,trange[1]], qf_bits=[1,0])
    endif else if (trange[0] ge t1) and (trange[1] le t2) then begin
      fgm_qf= obj_new('SPD_QF_LIST', t_start=[trange[0]], t_end=[trange[1]], qf_bits=[1])
    endif
  endif else begin
    fgm_qf = obj_new('SPD_QF_LIST', t_start=[t1,t2], t_end=[t2,SYSTIME(1)], qf_bits=[1,0])
    trange = [t1, SYSTIME(1)]
  endelse

  ; eclipse corrections
  thm_load_state,probe=probe, trange=trange, /get_support
  smp=spinmodel_get_ptr(probe,use_eclipse_corrections=2)
  smp->get_info,shadow_count=shadow_count,shadow_start=shadow_start,$
    shadow_end=shadow_end

  for i=0, shadow_count-1 do begin
    shadow_start0 = shadow_start[i]
    shadow_end0 = shadow_end[i]
    shadow_midpoints=(shadow_start0 + shadow_end0)/2.0D
    smp->interp_t,time=shadow_midpoints, segflag=segflag
    if segflag eq 3 then qf = 3 else qf = 2
    fgm_qf0= obj_new('SPD_QF_LIST', t_start=[shadow_start0], t_end=[shadow_end0], qf_bits=[qf])
    fgm_qf = fgm_qf->qf_merge(fgm_qf0)
  endfor

  ; noisy waveforms
  if (probe eq 'b') then begin ;Jan 04 20:45 – Jan. 04 24:00
    t_start = [time_double('2012-01-04/20:45:00')]
    t_end = [time_double('2012-01-04/24:00:00')]
    fgm_qf4 = obj_new('SPD_QF_LIST', t_start=t_start, t_end=t_end, qf_bits=[4])
    fgm_qf = fgm_qf->qf_merge(fgm_qf4)
  endif else if (probe eq 'c') then begin
    t_start = [time_double('2011-11-26/10:10:00'),time_double('2011-11-28/23:10:00'),time_double('2011-11-30/05:00:00'),time_double('2011-12-07/15:00:00'),time_double('2011-12-27/15:00:00')]
    t_end = [time_double('2011-11-27/00:00:00'),time_double('2011-11-29/03:00:00'),time_double('2011-11-30/24:00:00'),time_double('2011-12-08/24:00:00'),time_double('2011-12-27/24:00:00')]
    fgm_qf4 = obj_new('SPD_QF_LIST', t_start=t_start, t_end=t_end, qf_bits=[4,4,4,4,4])    
    fgm_qf = fgm_qf->qf_merge(fgm_qf4)
  endif
  
;Bz estimated from spin-plane components
  If(probe Eq 'e') Then Begin
     If(trange[0] Gt time_double('2024-06-01')) Then Begin
        fgm_qf0= obj_new('SPD_QF_LIST', t_start=[trange[0]], t_end=[trange[1]], qf_bits=[8])
        fgm_qf = fgm_qf->qf_merge(fgm_qf0)
     Endif
  Endif

  
  fgm_qf = fgm_qf->qf_time_slice(trange[0],trange[1])

  return, fgm_qf

end
