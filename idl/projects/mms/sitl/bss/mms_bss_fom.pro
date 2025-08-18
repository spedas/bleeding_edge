FUNCTION mms_bss_fom_read, s
  compile_opt idl2

  if n_tags(s) eq 0 then begin
    return, {x:0, y:0, z:0, nmax:0, Nsegs:0}
  endif

  ; FOM vs time plot
  strFinish = s.FINISHTIME
  i = where(strlen(strFinish) eq 0,c)
  dblFinish = time_double(strFinish)
  if c gt 0 then begin
    dblFinish[i] = systime(/utc,/seconds)
  endif
  wx = (dblFinish-time_double(s.CREATETIME))/86400.d0
  wy = s.FOM
  wz = s.SEGLENGTHS
  Nsegs = long(total(s.SEGLENGTHS))
  nmax = n_elements(wx)
  if nmax gt 0 then begin
    for n=0,nmax-1 do begin
      if wx[n] lt 0 then begin
        print, n,' ', s.STATUS[n], ', isPending=',s.isPENDING[n]
      endif
    endfor
  endif else begin
    wx = [0]
    wy = [0]
    wz = [0]
  endelse
  return, {x:[wx], y:[wy], z:[wz], nmax:nmax, Nsegs:Nsegs}
END

PRO mms_bss_fom, bss=bss, trange=trange, plot=plot, csv=csv, dir=dir
  compile_opt idl2

  clock=tic('mms_bss_fom')
  
  mms_init

  if undefined(plot) then plot=1
  if undefined(dir) then dir = '' else dir = spd_addslash(dir)
  if undefined(csv) then csv = 0

  ;----------------
  ; CATCH
  ;----------------
  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status
    message, /reset
    return
  endif

  ;----------------
  ; TIME
  ;----------------
  tnow = systime(/utc,/seconds)
  tlaunch = time_double('2015-03-12/22:44')
  t3m = tnow - 180.d0*86400.d0; 180 days
  if n_elements(trange) eq 2 then begin
    tr = timerange(trange)
  endif else begin
    tr = [t3m,tnow]
    ;tr = [tlaunch,tnow]
    trange = time_string(tr)
  endelse
  
  ;----------------
  ; LOAD DATA
  ;----------------
  if n_elements(bss) eq 0 then bss = mms_bss_query(trange=trange);,/fin)

  ; COMPLETE
  bse = mms_bss_query(bss=bss, exclude='INCOMPLETE')
  bsc = mms_bss_query(bss=bse, status='COMPLETE')
  d_comp = mms_bss_fom_read(bsc)
  print, 'complete', d_comp.NSEGS

  ; PENDING
  bsp = mms_bss_query(bss=bss, isPending=1)
  d_pend = mms_bss_fom_read(bsp)
  print, 'pending: ',d_pend.NSEGS

  ; OVERWRITTEN
  bsi = mms_bss_query(bss=bss, exclude='INCOMPLETE')
  bso = mms_bss_query(bss=bsi, status='DEMOTED DERELICT')
  d_over = mms_bss_fom_read(bso)
  print, 'overwritten: ', d_over.NSEGS

  ; INCOMPLETE
  bsa = mms_bss_query(bss=bss, status='INCOMPLETE')
  if n_tags(bsa) gt 0 then begin
    bsf = mms_bss_query(bss=bsa, status='FINISHED')
  endif else bsf = -1
  if n_tags(bsf) gt 0 then begin
    d_icmp = mms_bss_fom_read(bsf)
  endif else begin
    d_icmp = {x:0, y:0, z:0, nmax: 0, Nsegs: 0}
  endelse
  print, 'incomplete', d_icmp.NSEGS

  ;---------------
  ; PLOT
  ;---------------
  if plot then begin

    ; PREPARATION
    A = FINDGEN(17) * (!PI*2/16.); Make a vector of 16 points, A[i] = 2pi/16:
    USERSYM, COS(A), SIN(A), /FILL; Define the symbol, unit circle, filled
    char = 1.2
    plot,[0,30],[0,255],/nodata,xtitle='Number of days to FINISH',ytitle='FOM', color=0,ystyle=1

    ; COMPLETE
    oplot, d_comp.x, d_comp.y, psym=8,color=4
    xyouts, 20,200, 'TRANSMITTED: '+string(d_comp.NSEGS,format='(I8)'), charsize=char, color=4,/data

    ; PENDING
    oplot, d_pend.x, d_pend.y, psym=8, color=0
    xyouts, 20,190, 'PENDING:     '+string(d_pend.NSEGS,format='(I8)'), charsize=char, color=0,/data

    ; OVERWRITTEN
    if d_over.NMAX gt 0 then begin
      oplot, d_over.x, d_over.y, psym=8, color=6
    endif
    xyouts, 20,180, 'OVERWRITTEN: '+string(d_over.NSEGS,format='(I8)'), charsize=char, color=6,/data
  endif

  ;---------------
  ; CSV
  ;---------------
  if csv then begin
    write_csv, dir+'mms_bss_fom_comp.txt', d_comp.x, d_comp.y, d_comp.z, HEADER=['x','y','z']
    write_csv, dir+'mms_bss_fom_pend.txt', d_pend.x, d_pend.y, d_pend.z, HEADER=['x','y','z']
    write_csv, dir+'mms_bss_fom_over.txt', d_over.x, d_over.y, d_over.z, HEADER=['x','y','z']
    write_csv, dir+'mms_bss_fom_icmp.txt', d_icmp.x, d_icmp.y, d_icmp.z, HEADER=['x','y','z']
  endif
  toc,clock
END
