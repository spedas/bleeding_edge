;+
;PROCEDURE:   swe_plot_fhsk
;PURPOSE:
;  Makes tplot variables for SWEA fast housekeeping data (A6).
;
;USAGE:
;  swe_plot_fhsk
;
;INPUTS:
;       None:  All information is obtained from the common block.
;
;KEYWORDS:
;       PANS:          Returns the tplot variables created.
;
;       TRANGE:        Returns a 2xN array of time ranges for the N 
;                      tplot variables created.  This makes it easy to
;                      zoom in to view each channel.  For example:
;
;                        tplot, pans[i], trange=trange[*,i]
;
;       TSHIFT:        If set, then for each housekeeping channel, shift
;                      data from multiple sweeps to start at the time
;                      of the first sweep.  This makes it easy to compare
;                      multiple channels synchronized to the sweep.  In
;                      this case, TRANGE will have just two elements.
;
;       VNORM:         If set, normalize voltage housekeeping data to the
;                      nominal value for each channel.  Temperatures and
;                      voltages that do not have a nominal value are left
;                      unchanged.
;
;       AVG:           If set, average multiple sweeps for each channel.
;                      Automatically sets TSHIFT.
;
;       RESULT:        Named variable to hold structure of results.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2018-08-03 14:58:34 -0700 (Fri, 03 Aug 2018) $
; $LastChangedRevision: 25576 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_plot_fhsk.pro $
;
;CREATED BY:    David L. Mitchell  2017-01-15
;-
pro swe_plot_fhsk, pans=pans, trange=trange, tshift=tshift, vnorm=vnorm, avg=avg, $
                   result=result

  @mvn_swe_com
  
  if (size(a6,/type) ne 8) then begin
    print,"No fast housekeeping data."
    return
  endif

  tshift = keyword_set(tshift)
  vnorm = keyword_set(vnorm)
  avg = keyword_set(avg)
  if (avg) then tshift = 1

  result = {name   : 'SWEA Fast Housekeeping'           , $
            date   : time_string(mean(a6.time),prec=-3) , $
            tshift : tshift                             , $
            vnorm  : vnorm                              , $
            avg    : avg                                   }

; Add sweep table information

  npkt = n_elements(a6)
  chksum = bytarr(npkt)
  tabnum = intarr(npkt)

  for i=0,(npkt-1) do begin
    dt = min(abs(swe_hsk.time - a6[i].time),j)
    chksum[i] = swe_hsk[j].chksum[(swe_hsk[j].ssctl < 3)]
    tabnum[i] = mvn_swe_tabnum(chksum[i])
  endfor

  str_element,a6,'chksum',chksum,/add
  str_element,a6,'tabnum',tabnum,/add

; Housekeeping (APID 28)
;   SWEA housekeeping includes 3 temperatures (thermistors on the LVPS, 
;   digital board, and anode board), analyzer voltages, MCP bias, and
;   numerous voltages provided by the LVPS to the front-end electronics
;   and digital board.  A total of 24 values are multiplexed into 224
;   housekeeping messages.  Time resolutions are:
;
;     anode counters   : 448 messages in 1.95 sec --> 0.00435 sec
;     hsk per channel  :   9 messages in 1.95 sec --> 0.21 sec
;     fast hsk (1 ch)  : 224 messages in 1.95 sec --> 0.00871 sec
;     dwell hsk (1 ch) : 448 messages in 1.95 sec --> 0.00435 sec
;
;   Only one channel at a time can be the fast housekeeping channel, 
;   with 224 messages per cycle.
;
;   In dwell mode, all 448 housekeeping messages are devoted to one 
;   channel -- all other channels are ignored.
;
;   The 24 housekeeping channels are:
;
;   Channel   Value
;  -----------------------------------------
;      0      LVPST
;      1      MCPHV
;      2      NRV     (scaled)
;      3      ANALV
;      4      DEF1V
;      5      DEF2V
;      6      -       (unused)
;      7      -       (unused)
;      8      V0V
;      9      ANALT
;     10      P12V
;     11      N12V
;     12      MCP28V  (after enable plug)
;     13      NR28V   (after enable plug)
;     14      -       (unused)
;     15      -       (unused)
;     16      DIGT
;     17      P2P5DV
;     18      P5DV
;     19      P3P3DV
;     20      P5AV
;     21      N5AV
;     22      P28V    (before enable plug)
;     23      -       (unused)
;  -----------------------------------------
;

  pans = ['']
  t0 = min(a6.time)
  trange = [0D,0D]
  sweep = (1.95D/224D)*dindgen(224)

  v_nrm = [  1.0,  1.0,  1.0,  1.0,  1.0,  1.0,  1.0,  1.0,  1.0,  1.0, $
            12.0,-12.0, 28.0, 28.0,  1.0,  1.0,  1.0,  2.5,  5.0,  3.3, $
             5.0, -5.0, 28.0,  1.0]

  for chan=0,23 do begin
    indx = where(a6.mux eq chan, count)
    if (count gt 0) then begin
      i = indx/4      ; packet index
      j = indx mod 4  ; mux index
      x = dblarr(count*224L)
      y = fltarr(count*224L)
      for k=0L,(count-1L) do begin
        if (tshift) then begin
          if (avg) then begin
            if (tabnum[i[k]] ne tabnum[i[0]]) then begin
              print,"WARNING: Sweep changed during average!"
            endif
            y[0:223] += a6[i[k]].value[*,j[k]]
          endif else begin
            x[(k*224L):(k*224L + 223L)] = t0 + sweep
            y[(k*224L):(k*224L + 223L)] = a6[i[k]].value[*,j[k]]
            y[k*224L + 223L] = !values.f_nan
          endelse
        endif else begin
          x[(k*224L):(k*224L + 223L)] = (a6[i[k]].time + 2D*j[k]) + sweep
          y[(k*224L):(k*224L + 223L)] = a6[i[k]].value[*,j[k]]
          y[k*224L + 223L] = !values.f_nan
        endelse
      endfor

      if (avg) then begin
        x = t0 + sweep
        y = y[0:223]/float(count)
      endif

      if (vnorm) then begin
        if (chan eq 1) then v_nrm[chan] = average(y,/nan)
        if (chan eq 2) then v_nrm[chan] = average((shift(y,40))[0:39],/nan)
        y /= v_nrm[chan]
      endif

      dat = {x:x, y:y, chan:chan, trange:(minmax(x) + [-0.05,0.05]), tabnum:tabnum[i]}

      name = a6[i[0]].name[j[0]]  ; one channel -> one name
      tname = 'a6_' + name
      str_element, result, name, dat, /add
      store_data, tname, data=dat
      options, tname, 'ytitle', name
      options, tname, 'psym', 0
      options, tname, 'ynozero', 1
      pans = [pans, tname]
      trange = [trange, dat.trange]
    endif
  endfor

  pans = pans[1:*]
  if (tshift) then trange = [(t0 - 0.05),(t0 + 2D)] $
              else trange = reform(trange[2:*], 2, n_elements(pans))

  return

end
