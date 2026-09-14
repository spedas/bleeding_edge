; End-to-end tests for heliocentric routing through spd_cotrans.

pro test_spd_cotrans_helio
  compile_opt idl2

  spd_cotrans, '', /VALID_NAMES, in_coord=valid_in, out_coord=valid_out
  required = ['gseq', 'hee', 'hae', 'heeq']
  for i=0, n_elements(required)-1 do begin
    if ~array_equal(where(valid_in eq required[i]), -1) then continue
    message, 'Missing spd_cotrans coordinate: '+required[i]
  endfor

  times = time_double(['2004-02-14/12:00:00', '2016-07-01', $
    '2025-01-10/06:30:00'])
  vectors = [[7000d,20d,-30d], [-10000d,50d,80d], [42164d,-10d,40d]]
  dl = {data_att:{coord_sys:'gei', st_type:'pos'}}
  store_data, 'test_route_gei', data={x:times, y:vectors}, dlimits=dl

  ; Exercise a multi-edge route: GEI->GSE->GSEQ->HEEQ and back.
  spd_cotrans, 'test_route_gei', 'test_route_heeq', out_coord='heeq'
  if cotrans_get_coord('test_route_heeq') ne 'heeq' then $
    message, 'spd_cotrans did not set HEEQ metadata.'
  spd_cotrans, 'test_route_heeq', 'test_route_gei_back', out_coord='gei'
  get_data, 'test_route_gei_back', data=back
  print, 'GEI-HEEQ maximum round-trip error (km): ', max(abs(back.y-vectors))
  ; The existing ROCOT GEI/GSE legs use single-precision matrices.  Allow
  ; 10 metres of accumulated round-trip error across the six-leg chain.
  if max(abs(back.y-vectors)) gt 1d-2 then $
    message, 'spd_cotrans GEI-HEEQ round-trip failed.'

  ; Exercise both other heliocentric branches.
  spd_cotrans, 'test_route_gei', 'test_route_hae', out_coord='hae'
  spd_cotrans, 'test_route_hae', 'test_route_hee', out_coord='hee'
  spd_cotrans, 'test_route_hee', 'test_route_gei_back2', out_coord='gei'
  get_data, 'test_route_gei_back2', data=back2
  if max(abs(back2.y-vectors)) gt 1d-2 then $
    message, 'spd_cotrans HAE-HEE chained round-trip failed.'

  ; Four-character coordinate suffixes must be inferred correctly.
  copy_data, 'test_route_gei', 'test_suffix_gseq'
  get_data, 'test_suffix_gseq', data=suffix_data, dlimits=suffix_dl, $
    limits=suffix_limits
  cotrans_set_coord, suffix_dl, 'gseq'
  store_data, 'test_suffix_gseq', data=suffix_data, dlimits=suffix_dl, $
    limits=suffix_limits
  spd_cotrans, 'test_suffix', in_suffix='_gseq', out_suffix='_heeq'
  if tnames('test_suffix_heeq') eq '' then message, 'HEEQ suffix routing failed.'

  del_data, 'test_route_* test_suffix_*'
  print, 'test_spd_cotrans_helio: all tests passed.'
end
