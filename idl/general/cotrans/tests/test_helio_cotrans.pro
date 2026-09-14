; Regression tests for GSEQ and the dedicated heliocentric transforms.

pro test_helio_cotrans
  compile_opt idl2

  times = time_double(['2004-02-14/12:00:00', '2016-07-01/00:00:00', $
    '2025-01-10/06:30:00'])
  data = dblarr(3,4)
  data[*,0] = times
  data[*,1:3] = [[1d,2d,3d], [-4d,5d,-6d], [7d,-8d,9d]]

  cotrans, data[*,1:3], gseq, times, /GSE2GSEQ, /IGNORE_DLIMITS
  cotrans, gseq, gse_roundtrip, times, /GSEQ2GSE, /IGNORE_DLIMITS
  ; ROCOT csundir_vect works in single precision.
  if max(abs(gse_roundtrip-data[*,1:3])) gt 2d-6 then $
    message, 'GSE-GSEQ vector round-trip failed.'

  gse2hee, data, hee, /POSITION
  gse2hee, hee, gse_position_roundtrip, /HEE2GSE, /POSITION
  if max(abs(gse_position_roundtrip-data)) gt 1d-7 then $
    message, 'GSE-HEE position round-trip failed.'

  gei2hae, data, hae, /POSITION
  gei2hae, hae, gei_position_roundtrip, /HAE2GEI, /POSITION
  if max(abs(gei_position_roundtrip-data)) gt 2d-4 then $
    message, 'GEI-HAE position round-trip failed.'

  gseq_data = data
  gseq_data[*,1:3] = gseq
  gseq2heeq, gseq_data, heeq, /POSITION
  gseq2heeq, heeq, gseq_position_roundtrip, /HEEQ2GSEQ, /POSITION
  if max(abs(gseq_position_roundtrip-gseq_data)) gt 1d-5 then $
    message, 'GSEQ-HEEQ position round-trip failed.'

  ; Rotation-only transforms must not acquire a one-AU position offset.
  gse2hee, data, hee_vector
  if max(abs(hee_vector[*,1:3])) gt 10d then $
    message, 'HEE vector transform incorrectly applied a position offset.'

  ; Tplot position metadata selects translation and is updated on output.
  dl = {data_att:{coord_sys:'gse', st_type:'pos'}}
  store_data, 'test_helio_gse', data={x:times, y:data[*,1:3]}, dlimits=dl
  gse2hee, 'test_helio_gse', 'test_helio_hee'
  get_data, 'test_helio_hee', data=hee_tplot, dlimits=hee_dl
  if cotrans_get_coord(hee_dl) ne 'hee' then message, 'HEE metadata update failed.'
  gse2hee, 'test_helio_hee', 'test_helio_gse_roundtrip', /HEE2GSE
  get_data, 'test_helio_gse_roundtrip', data=gse_tplot
  if max(abs(gse_tplot.y-data[*,1:3])) gt 1d-7 then $
    message, 'HEE tplot position round-trip failed.'
  del_data, 'test_helio_gse test_helio_hee test_helio_gse_roundtrip'

  print, 'test_helio_cotrans: all tests passed.'
end
