;+
;Procedure:
;  mms_pgs_make_multipad_spec
;
;Purpose:
;  Builds theta (latitudinal) spectrogram from simplified particle data structure.
;  this is like mms_pgs_make_theta_spec, except it's per energy and this routine expects
;  'spec' to be sent already initialized
;
;
;Input:
;  data: single sanitized data structure
;
;
;Input/Output:
;  spec: The spectrogram (ntimes x n_energy x ny)
;  yaxis: The y axis (ny OR ny x ntimes)
;  colatitude: Flag to specify that data is in colatitude
;  
;  -Each time this procedure runs it will concatenate the sample's data
;   to the SPEC variable.
;  -Both variables will be initialized if not set
;  -The y axis will remain a single dimension until a change is detected
;   in the data, at which point it will be expanded to two dimensions.
;
;
;Notes:
; forked from mms_pgs_make_theta_spec by egrimes on 23 April 2018
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-06-30 07:36:07 -0700 (Fri, 30 Jun 2017) $
;$LastChangedRevision: 23532 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_pgs_make_theta_spec.pro $
;-


pro mms_pgs_make_multipad_spec, data, spec=spec, sigma=sigma, yaxis=yaxis, colatitude=colatitude, time_idx=time_idx, $
                                wegy=wegy, _extra=ex

  compile_opt idl2, hidden
  
  if ~is_struct(data) then return
  
  ;copy data and zero inactive bins to ensure
  ;areas with no data are represented as NaN
  d = data.data
  idx = where(~data.bins,nd)
  if nd gt 0 then begin
    d[idx] = 0.
  endif
  
  n_theta = data.dims[2]
  n_energy = data.dims[0]

  ave_full = dblarr(n_energy, n_theta)
  
  outbins = interpol([0, 180],n_theta+1)
  en_bins = bin_edges(data.ORIG_ENERGY)
  wegy = data.ORIG_ENERGY
  
  ; shift to colatitude
  if undefined(colatitude) then data.theta = 90-data.theta
  
  for bin_idx = 0, n_elements(outbins)-2 do begin
    this_bin = where(data.theta ge outbins[bin_idx] and data.theta lt outbins[bin_idx+1], bcount)
    for en_idx=0, n_elements(en_bins)-2 do begin
      this_en_bin = where(data.energy ge en_bins[en_idx] and data.energy lt en_bins[en_idx+1], encount)
      both_bins = ssl_set_intersection(this_en_bin, this_bin)
      if both_bins[0] ne -1 then ave_full[en_idx, bin_idx] += total(d[both_bins])/total(data.bins[both_bins])
    endfor
  endfor

  if undefined(colatitude) then data.theta = 90-data.theta
  if undefined(colatitude) then outbins = 90-outbins
  outcenters = bin_centers(outbins)

  ;get values for the y axis
  y = outcenters

  ;set the y axis
  if undefined(yaxis) then begin
    yaxis = y
  endif else begin
    spd_pgs_concat_yaxis, yaxis, y, ns=dimen2(spec)
  endelse
  
  ;concatenate spectra
  spec[time_idx, *, *] = ave_full

end