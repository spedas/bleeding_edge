;+
; PROCEDURE:
;         mms_fpi_fix_metadata
;
; PURPOSE:
;         Helper routine for setting FPI metadata. Original metadata from L2 QL plots script
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-11-15 09:45:38 -0800 (Thu, 15 Nov 2018) $
;$LastChangedRevision: 26125 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_fpi_fix_metadata.pro $
;-

pro mms_fpi_fix_metadata, tplotnames, prefix = prefix, instrument = instrument, data_rate = data_rate, suffix = suffix, level=level
    if undefined(prefix) then prefix = ''
    if undefined(suffix) then suffix = ''
    if undefined(level) then level = ''
    if undefined(data_rate) then data_rate = 'fast'

    for sc_idx = 0, n_elements(prefix)-1 do begin
      for name_idx = 0, n_elements(tplotnames)-1 do begin
        tplot_name = tplotnames[name_idx]
        case tplot_name of
          prefix[sc_idx] + '_dis_energyspectr_px_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[eV]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end
          prefix[sc_idx] + '_dis_energyspectr_py_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[eV]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end
          prefix[sc_idx] + '_dis_energyspectr_pz_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[eV]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end
          prefix[sc_idx] + '_dis_energyspectr_mx_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[eV]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end
          prefix[sc_idx] + '_dis_energyspectr_my_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[eV]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end
          prefix[sc_idx] + '_dis_energyspectr_mz_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[eV]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end
          prefix[sc_idx] + '_dis_energyspectr_par_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[eV]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end
          prefix[sc_idx] + '_dis_energyspectr_anti_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[eV]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end
          prefix[sc_idx] + '_dis_energyspectr_perp_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[eV]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end
          prefix[sc_idx] + '_des_energyspectr_px_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[eV]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end
          prefix[sc_idx] + '_des_energyspectr_py_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[eV]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end
          prefix[sc_idx] + '_des_energyspectr_pz_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[eV]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end
          prefix[sc_idx] + '_des_energyspectr_mx_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[eV]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end
          prefix[sc_idx] + '_des_energyspectr_my_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[eV]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end
          prefix[sc_idx] + '_des_energyspectr_mz_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[eV]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end
          prefix[sc_idx] + '_des_energyspectr_par_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[eV]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end
          prefix[sc_idx] + '_des_energyspectr_anti_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[eV]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end
          prefix[sc_idx] + '_des_energyspectr_perp_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[eV]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end
          prefix[sc_idx] + '_des_energyspectr_omni_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[eV]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end
          prefix[sc_idx] + '_dis_energyspectr_omni_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 0, 1
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[eV]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end
          ; PADs
          prefix[sc_idx] + '_des_pitchangdist_lowen_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 180, 0
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[deg]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end
          prefix[sc_idx] + '_des_pitchangdist_miden_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 180, 0
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[deg]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end
          prefix[sc_idx] + '_des_pitchangdist_highen_'+data_rate+suffix: begin
            ylim, tplot_name, 0, 180, 0
            zlim, tplot_name, 0, 0, 1
            options, tplot_name, ysubtitle='[deg]', ztitle='[keV/(cm^2 s sr keV)]', ystyle=1
          end



          ; moms
          prefix[sc_idx] + '_dis_heatq_dbcs_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', ['Qx DBCS', 'Qy DBCS', 'Qz DBCS']
            options, /def, tplot_name, 'colors', [2, 4, 6]
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDIS heat-flux'
          end
          prefix[sc_idx] + '_dis_heatq_gse_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', ['Qx GSE', 'Qy GSE', 'Qz GSE']
            options, /def, tplot_name, 'colors', [2, 4, 6]
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDIS heat-flux'
          end
          prefix[sc_idx] + '_des_heatq_dbcs_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', ['Qx DBCS', 'Qy DBCS', 'Qz DBCS']
            options, /def, tplot_name, 'colors', [2, 4, 6]
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDES heat-flux'
          end
          prefix[sc_idx] + '_des_heatq_gse_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', ['Qx GSE', 'Qy GSE', 'Qz GSE']
            options, /def, tplot_name, 'colors', [2, 4, 6]
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDES heat-flux'
          end
          prefix[sc_idx] + '_des_bulkv_dbcs_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', ['Vx DBCS', 'Vy DBCS', 'Vz DBCS']
            options, /def, tplot_name, 'colors', [2, 4, 6]
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDES velocity'
          end
          prefix[sc_idx] + '_des_bulkv_gse_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', ['Vx GSE', 'Vy GSE', 'Vz GSE']
            options, /def, tplot_name, 'colors', [2, 4, 6]
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDES velocity'
          end
          prefix[sc_idx] + '_dis_bulkv_dbcs_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', ['Vx DBCS', 'Vy DBCS', 'Vz DBCS']
            options, /def, tplot_name, 'colors', [2, 4, 6]
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDIS velocity'
          end
          prefix[sc_idx] + '_dis_bulkv_gse_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', ['Vx GSE', 'Vy GSE', 'Vz GSE']
            options, /def, tplot_name, 'colors', [2, 4, 6]
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDIS velocity'
          end
          prefix[sc_idx] + '_des_numberdensity_'+data_rate+suffix: begin
            options, /def, tplot_name, 'colors', 2
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDES'
            options, /def, tplot_name, 'labels', 'Ne, electrons'
          end
          prefix[sc_idx] + '_dis_numberdensity_'+data_rate+suffix: begin
            options, /def, tplot_name, 'colors', 4
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDIS'
            options, /def, tplot_name, 'labels', 'Ni, ions'
          end
          prefix[sc_idx] + '_des_pseudo_numberdensity_'+data_rate+suffix: begin
            options, /def, tplot_name, 'colors', 2
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDES'
            options, /def, tplot_name, 'labels', 'Ne, electrons'
          end
          prefix[sc_idx] + '_dis_pseudo_numberdensity_'+data_rate+suffix: begin
            options, /def, tplot_name, 'colors', 4
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDIS'
            options, /def, tplot_name, 'labels', 'Ni, ions'
          end
          prefix[sc_idx] + '_des_numberdensity_dbcs_'+data_rate+suffix: begin
            options, /def, tplot_name, 'colors', 2
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDES'
            options, /def, tplot_name, 'labels', 'Ne, electrons'
          end
          prefix[sc_idx] + '_dis_numberdensity_dbcs_'+data_rate+suffix: begin
            options, /def, tplot_name, 'colors', 4
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDIS'
            options, /def, tplot_name, 'labels', 'Ni, ions'
          end
          prefix[sc_idx] + '_des_bulkx_dbcs_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Vx'
            options, /def, tplot_name, 'colors', 2
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDES velocity'
          end
          prefix[sc_idx] + '_des_bulky_dbcs_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Vy'
            options, /def, tplot_name, 'colors', 4
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDES velocity'
          end
          prefix[sc_idx] + '_des_bulkz_dbcs_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Vz'
            options, /def, tplot_name, 'colors', 6
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDES velocity'
          end
          prefix[sc_idx] + '_dis_bulkx_dbcs_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Vx'
            options, /def, tplot_name, 'colors', 2
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDIS velocity'
          end
          prefix[sc_idx] + '_dis_bulky_dbcs_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Vy'
            options, /def, tplot_name, 'colors', 4
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDIS velocity'
          end
          prefix[sc_idx] + '_dis_bulkz_dbcs_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Vz'
            options, /def, tplot_name, 'colors', 6
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDIS velocity'
          end
          prefix[sc_idx] + '_des_bulkx_gse_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Vx'
            options, /def, tplot_name, 'colors', 2
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDES velocity'
          end
          prefix[sc_idx] + '_des_bulky_gse_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Vy'
            options, /def, tplot_name, 'colors', 4
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDES velocity'
          end
          prefix[sc_idx] + '_des_bulkz_gse_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Vz'
            options, /def, tplot_name, 'colors', 6
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDES velocity'
          end
          prefix[sc_idx] + '_dis_bulkx_gse_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Vx'
            options, /def, tplot_name, 'colors', 2
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDIS velocity'
          end
          prefix[sc_idx] + '_dis_bulky_gse_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Vy'
            options, /def, tplot_name, 'colors', 4
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDIS velocity'
          end
          prefix[sc_idx] + '_dis_bulkz_gse_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Vz'
            options, /def, tplot_name, 'colors', 6
            options, /def, tplot_name, 'labflag', -1
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CDIS velocity'
          end
          prefix[sc_idx] + '_des_temppara_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Te, para'
            options, /def, tplot_name, 'colors', 2
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CTemp'
          end
          prefix[sc_idx] + '_des_tempperp_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Te, perp'
            options, /def, tplot_name, 'colors', 4
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CTemp'
          end
          prefix[sc_idx] + '_dis_temppara_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Ti, para'
            options, /def, tplot_name, 'colors', 6
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CTemp'
          end
          prefix[sc_idx] + '_dis_tempperp_'+data_rate+suffix: begin
            options, /def, tplot_name, 'labels', 'Ti, perp'
            options, /def, tplot_name, 'colors', 8
            options, /def, tplot_name, 'ytitle', strupcase(prefix[sc_idx]) + '!CTemp'
          end
          else: ; not doing anything
        endcase
      endfor
    endfor
end