pro gp_ex_2,refine=refine

; Show geopack version installed

help,'geopack',/dlm

; If no 'refine' keyword provided, enable it (to reproduce the tracing issue)

if n_elements(refine) eq 0 then begin
  refine = 1
endif

; If using 'refine', also set the ionosphere flag, otherwise, set it to 0 (not valid without /refine)

if refine eq 0 then begin
  equator = 0
  ionosphere = 0
endif else begin
  equator = 0
  ionosphere = 1
endelse

; Set time 2022-11-23 01:00:30

year = 2022
doy = 327
hour = 1
minute = 0
sec = 30

; Start position (GSW in RE) (ERG s/c position at start time)

startpos_gsw_x = 1.0773251061938103D
startpos_gsw_y = 4.5740390469308823D
startpos_gsw_z = 2.9926138096815640D

; Correct south foot point position

sfoot_gsw = [0.65405689D, 0.31240662D, -0.68892024D]

; calculate tilt

geopack_recalc_08, year, doy, hour, minute, sec, tilt = tilt

print, 'Tilt (expected -25.531946614204912 for latest IGRF coefficients) : ', tilt

; set model parameters

par_iter = [1.7358368713587498D, -1.0000000000000000D, -3.4670000076293945D, 1.4919999718666077D, 0.030043020864904266D, 0.012242400554213096D, 0.025672221363611112D, 0.0061831478743294430D,0.0015737276816553134D,0.0078245301655424995D]

; calculate foot point and trace field line from south foot point back to north ionosphere

sp_foot_x = sfoot_gsw[0]
sp_foot_y = sfoot_gsw[1]
sp_foot_z = sfoot_gsw[2]

dir=-1

geopack_trace_08, sp_foot_x, sp_foot_y, sp_foot_z, dir, par_iter, ret_foot_x, ret_foot_y, ret_foot_z, R0=R02, RLIM=60.0, fline=trgsm_out, tilt=tilt, IGRF=1, TS04=1, refine=refine, ionosphere=ionosphere

print, 'Count of trace points, south ionospere to north ionosphere: ', n_elements(trgsm_out)/3
print, 'Retraced north foot point (Expected: -0.22478692      0.35936250      0.92365387): ',ret_foot_x, ret_foot_y, ret_foot_z
tr_sp_np = trgsm_out
plot,tr_sp_np[*,0], tr_sp_np[*,1]


loadct,2
; plot all three field line traces on same plot, different colors
!p.background = !d.table_size - 1
plot,tr_sp_np[*,0],tr_sp_np[*,1],color=25, thick=5
end