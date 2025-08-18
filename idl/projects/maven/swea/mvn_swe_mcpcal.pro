;+
;PROCEDURE:   mvn_swe_mcpcal
;PURPOSE:
;  Analyzes in-flight MCP calibration data to estimate the optimal
;  MCP bias value.  Returns the best value in decimal and hex.
;
;
;USAGE:
;  mvn_swe_mcpcal, trange
;
;INPUTS:
;     trange:          Time range bracketing calibration sequence.
;
;KEYWORDS:
;
;     SCP:             Spacecraft potential (volts).  Assumes same potential
;                      across calibration sequence.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-08-15 17:53:12 -0700 (Tue, 15 Aug 2017) $
; $LastChangedRevision: 23798 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_mcpcal.pro $
;
;CREATED BY:    David L. Mitchell
;FILE: mvn_swe_mcpcal.pro
;-
pro mvn_swe_mcpcal, trange

  @mvn_swe_com
  @swe_snap_common
  
  tmin = min(time_double(trange), max=tmax)
  
  str_element, mvn_swe_engy, 'sc_pot', scpot, success=ok
  if (not ok) then begin
    print,"You must load SWEA data first."
    return
  endif

  igud = where(scpot ne 0.), ngud)
  if (ngud eq 0) then begin
    print,"You must determine the spacecraft potential first."
    return
  endif
  indx = where((mvn_swe_engy.time ge tmin) and (mvn_swe_engy.time le tmax), count)
  if (count gt 0) then pot = average(scpot[indx],/nan) else pot = 0.
  mvn_scpot, set=pot
  mvn_swe_n1d, minden=1e-5

; Conversion from decimal to hex (for commanding the MCP bias)

  mcp_to_hex = 18.7244

; Calculate density as a function of MCP bias

  get_data,'mvn_swe_spec_dens',data=n_e,index=i
  if (i eq 0) then begin
    print,"No density data."
    return
  endif
  get_data,'MCPHV',data=mcp

  indx = where((n_e.x ge tmin) and (n_e.x le tmax), count)
  if (count eq 0L) then begin
    print,"No data within specified time range."
    return
  endif

  time = n_e.x[indx]
  dens = n_e.y[indx]

  nndx = nn(mcp.x, time)
  mcpv = mcp.y[nndx]

; Plot result

  tplot_options, get_opt=topt
  str_element, topt, 'window', value=Twin, success=ok
  if (not ok) then Twin = !d.window

  window, /free, xsize=Nopt.xsize, ysize=Nopt.ysize, xpos=Nopt.xpos, ypos=Nopt.ypos
  Nwin = !d.window

  wset, Nwin
  title = 'SWEA MCPHV Calibration'
  plot_io,mcpv,dens,psym=1,charsize=1.4, $
          xtitle='MCP Bias (Volts)',ytitle='Ne (1/cc)',title=title
  oplot,[2600.,2600.],[1e-6,1e3],line=2,color=6
  crosshairs,x,y

  print,round(x),round(x*mcp_to_hex),format='(i4," = ",z4.4)'

  wset, Twin

  return

end
