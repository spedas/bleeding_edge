
;+
;Procedure:
;  erg_pgs_make_e_spec
;
;Purpose:
;  Builds energy spectrogram from simplified particle data structure.
;
;
;Input:
;  data: single sanitized data structure
;  
;
;Input/Output:
;  spec: The spectrogram (ny x ntimes)
;  yaxis: The y axis (ny OR ny x ntimes)
;  
;  -Each time this procedure runs it will concatenate the sample's data
;   to the SPEC variable.
;  -Both variables will be initialized if not set
;  -The y axis will remain a single dimension until a change is detected
;   in the data, at which point it will be expanded to two dimensions.
;
;
;Notes:
;
;
;$LastChangedDate: 2019-10-23 14:19:14 -0700 (Wed, 23 Oct 2019) $
;$LastChangedRevision: 27922 $
;-

pro erg_pgs_make_e_spec, data, spec=spec, sigma=sigma, yaxis=yaxis, enormalize=enormalize, _extra=ex

    compile_opt idl2, hidden
  
  
  if ~is_struct(data) then return
  
  ; if set, normalize spec between 0 and 1
  if keyword_set(enormalize) && enormalize ne 0 then begin
    data_energy = data.energy / max(data.energy,/NAN)
  endif else begin
    data_energy = data.energy
  endelse
  
  dr = !dpi/180.
  
  enum = dimen1(data.energy)
  anum = dimen2(data.energy)

  ;copy data and zero inactive bins to ensure
  ;areas with no data are represented as NaN
  d = data.data
  scaling = data.scaling
  idx = where(~data.bins,nd)
  if nd gt 0 then begin
    d[idx] = 0.
  endif
  
  ;weighted average to create spectrogram piece
  ;energies with no valid data should come out as NaN
  if anum gt 1 then begin
    ave = total(d,2) / total(data.bins,2)
    ave_s = sqrt(  total( d * scaling ,2) / total(data.bins,2)^2  )
  endif else begin
    ave = d / data.bins
    ave_s = sqrt(  ( d * scaling ) / data.bins^2  )
  endelse
  
  ;output the y-axis values
  ; *check for varying energy levels?
  y = data_energy[*,0]
  
  
  ;set y axis
  if undefined(yaxis) then begin
    yaxis = y
  endif else begin
    spd_pgs_concat_yaxis, yaxis, y, ns=dimen2(spec)
  endelse
  
  
  ;concatenate spectra
  if undefined(spec) then begin
    spec = temporary(ave)
  endif else begin
    spd_pgs_concat_spec, spec, ave
  endelse 
  
  
  ;concatenate standard deviation
  if undefined(sigma) then begin
    sigma = temporary(ave_s)
  endif else begin
    spd_pgs_concat_spec, sigma, ave_s
  endelse 
    
  
end
