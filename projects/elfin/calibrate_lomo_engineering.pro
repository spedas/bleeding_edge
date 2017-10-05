pro calibrate_lomo_engineering

  coefs = [3.2925429509d-03,3.4185374931d-04,9.5787248560d-05,3.6688156858d-05]  ; these coefficients are in the csv file
  thm_init

  temps= tnames('ell_hsk_*temp')
  for i=0, n_elements(temps)-1 do begin
    get_data, temps[i], data=in_data, dlimits=dl, limits=l
    lg_data = alog(3.3*(double(in_data.y))/256);
    fit = coefs[0] + coefs[1]*lg_data + coefs[2]*lg_data*lg_data + coefs[3]*lg_data*lg_data*lg_data;
    idx=where(fit LE 0.00001)  ; careful small in_data values (< 2) could result in not a real number
    cal_in_data = 1/fit(idx)-273.15
    y1=min(cal_in_data)
    y2=max(cal_in_data)
    new_dl={CDF:dl.cdf, $
      SPEC:0, $
      LOG:0, $
      COLORS:[2], $
      YSUBTITLE:'[Kelvin]', $
      YRANGE:[y1,y2]}
    store_data, temps[i], data={x:in_data.x[idx], y:cal_in_data}, dlimits=new_dl, limits=l
    tplot_gui, temps[i], /no_verify, /no_draw
  endfor

  volts = tnames('ell_hsk_*volt_mon')
  for i=0, n_elements(volts)-1 do begin
    ; handle bias separately, ignore L2 calibrate using only l1 data
    if (strpos(volts[i], 'bias') EQ -1) then begin 
    get_data, volts[i], data=in_data, dlimits=dl, limits=l
    Case volts[i] of
      'ell_hsk_30v_volt_mon': begin
        volt=double(in_data.y) *3.3*14.333/256.
      end
      'ell_hsk_23v_volt_mon': begin
        volt=double(in_data.y) *3.3*8.5188/256.
      end
      'ell_hsk_22v_volt_mon': begin
        volt=double(in_data.y) *3.3*8.5188/256.
      end
      'ell_hsk_8v6_volt_mon': begin
        volt=double(in_data.y) *3.3*3.8/256.
      end
      'ell_hsk_8v_volt_mon': begin
        volt=double(in_data.y) *3.3*3.8/256.
      end
      'ell_hsk_5v_dig_volt_mon': begin
        volt=double(in_data.y) *3.3*2./256.
      end
      'ell_hsk_5v_epd_volt_mon': begin
        volt=double(in_data.y) *3.3*2./256.
      end
      'ell_hsk_4v5_volt_mon': begin
        volt=double(in_data.y) *3.3*2./256.
      end
      'ell_hsk_3v3_volt_mon': begin
        volt=double(in_data.y) *3.3*2./256.
      end
      'ell_hsk_1v5_dig_volt_mon': begin
        volt=double(in_data.y) *3.3*2./256.
      end
      'ell_hsk_1v5_epd_volt_mon': begin
        volt=double(in_data.y) *3.3*2./256.
      end
      'ell_hsk_1v5_prm_volt_mon': begin
        volt=double(in_data.y) *3.3*2./256.
      end
      else: print, 'ERROR - no variable by the name of '+volts[i]
    Endcase
    y1=min(volt)
    y2=max(volt)
    new_dl={CDF:dl.cdf, $
      SPEC:0, $
      LOG:0, $
      COLORS:[2], $
      YSUBTITLE:'volt', $
      YRANGE:[y1,y2]}
    store_data, volts[i], data={x:in_data.x, y:volt}, dlimits=new_dl, limits=l
    tplot_gui, volts[i], /no_verify, /no_draw
    endif
  endfor

  biasl= tnames('ell_hsk_epd_biasl_volt_mon')
  get_data, biasl, data=in_data, dlimits=dl, limits=l
  v=3.3*(in_data.y/255.)
  new_biasl = (v*266.369)-826.446
  y1=min(new_biasl)
  y2=max(new_biasl)
  new_dl={CDF:dl.cdf, $
    SPEC:0, $
    LOG:0, $
    COLORS:[2], $
    YSUBTITLE:'', $
    YRANGE:[y1,y2]}
  store_data, 'ell_hsk_epd_biasl_volt_mon', data={x:in_data.x, y:new_biasl}, dlimits=dl, limits=l
  tplot_gui, biasl, /no_verify, /no_draw

  
  biash= tnames('ell_hsk_epd_biash_volt_mon')
  get_data, biash, data=in_data, dlimits=dl, limits=l
  new_biash = (v*461.892)-1436.78
  y1=min(new_biash)
  y2=max(new_biash)
  new_dl={CDF:dl.cdf, $
    SPEC:0, $
    LOG:0, $
    COLORS:[2], $
    YSUBTITLE:'', $
    YRANGE:[y1,y2]}
  store_data, 'ell_hsk_epd_biash_volt_mon', data={x:in_data.x, y:new_biash}, dlimits=dl, limits=l
  tplot_gui, biash, /no_verify, /no_draw

end