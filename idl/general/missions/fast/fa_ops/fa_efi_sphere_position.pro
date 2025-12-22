;+
;NAME:
;fa_efi_sphere_position
;PURPOSE:
;Returns the position of an electric field probe as a function of time
;in DSC coordinates.
;CALLING SEQUENCE:
;probe_position = fa_efi_sphere_position(probe, phase)
;INPUT:
;probe = A number from 1 to 10, for probes 1 to 10
;tim_arr = time array 
;phase = Sphase array, can be from a call to fa_fields_phase (comp2),
;or calculated as in fa_fields_despin
;OUTPUT:
;position = probe position in DSC coordinates
;NOTES:
;The appropriate phase data must be loaded in a current SDT session,
;be sure to load data 1032_spinPhase
;See:
;for a diagram
;http://sprg.ssl.berkeley.edu/fast/scienceops/fast_fields_help.html
;DSC system corresponds to when the X axis points at the Sun (s_phase = 0)
;for boom length info see:
;/disks/django/home/sdt/nws/Linux.2.6/lib/fast_fields_cals/fastboom_hist.cal
;HISTORY:
; 21-oct-2024, jmm, jimm@ssl.berkeley.edu
;+

Function fa_efi_sphere_position, probe, tim_arr, phase

  probe = (probe > 1) < 10
;Times for boom deployment, to determine length
  boom_times = time_double(['1995-07-26/00:00:00',$
                            '1996-09-03/16:53:40', $
                            '1996-09-10/14:16:40', $
                            '1996-09-11/00:00:00', $
                            '1996-09-15/00:00:00', $
                            '1996-09-29/00:00:00', $
                            '1997-02-03/10:07:20', $
                            '2024-10-23/00:00:00'])
  nbt = n_elements(boom_times)

  ntimes = n_elements(tim_arr)
  length = fltarr(ntimes)
  probel = fltarr(n_elements(boom_times)-1, 10)
;After '1995-07-26/00:00:00'
  probel[0, *] = 0.0            ;Launch configuration
;After '1996-09-03/16:53:40'
  probel[1, *] = [5.5, 0.5, 0.0, 0.6, 0.0, $
                  0.0, 0.0, 0.0, 0.0, 0.0]
;After '1996-09-10/14:16:40'
  probel[2, *] = [5.5, 0.5, 0.0, 0.6, 5.5, $
                  0.5, 0.5, 5.5, 0.0, 0.0]
;After '1996-09-11/00:00:00'
  probel[3, *] = [8.0, 3.0, 0.0, 0.6, 8.0, $
                  3.0, 3.0, 8.0, 0.0, 0.0]
;After '1996-09-15/00:00:00'
  probel[4, *] = [8.0, 3.0, 0.0, 0.6, 28.0, $
                  23.0, 23.0, 28.0, 0.0, 0.0]
;After '1996-09-29/00:00:00'
  probel[5, *] = [28.3, 23.3, 0.0, 0.6, 28.0, $
                  23.0, 23.0, 28.0, 0.0, 0.0]
;After '1997-02-03/10:07:20']
  probel[6, *] = [28.3, 23.3, 0.0, 0.6, 28.0, $
                  23.0, 23.0, 28.0, 4.05, 0.0]
;Assign lengths
  For j = 1, nbt-2 Do Begin
     xx0 = where(tim_arr Gt boom_times[j-1] And $
                 tim_arr Le boom_times[j], nxx0)
     If(nxx0 Gt 0) Then length[xx0] = probel[j, probe-1]
  Endfor
  xx0 = where(tim_arr Gt boom_times[nbt-2], nxx0)
  If(nxx0 Gt 0) Then length[xx0] = probel[nbt-2, probe-1]
;Probe phase angles, in degrees, only valid for some probes, probe 3
;is never exended, probes 9 and 10 are axial. In Radians
  probe_phase = 2.0*!dpi*[-142.0, -142.0, 0.0, 38.0, -45.0, $
                          -45.0, 121.0, 121.0, 0.0, 0.0]/360.0
  otp = fltarr(ntimes, 3)
  If(probe Eq 3 Or probe Eq 9 Or probe Eq 10) Then Begin
     otp[*, 2] = length
  Endif Else Begin
;The Y component in the frame rotating with the probe is zero
     otp[*, 0] = length*cos(phase+probe_phase[probe-1])
     otp[*, 1] = length*sin(phase+probe_phase[probe-1])
  Endelse
;That's it
     
  Return, otp
End
