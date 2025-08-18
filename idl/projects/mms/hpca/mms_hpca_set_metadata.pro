;+
; PROCEDURE:
;         mms_hpca_set_metadata
;         
; PURPOSE:
;         Sets metadata for HPCA tplot variables
; 
; KEYWORDS:
;         prefix: prefix for names of the tplot variables, typically 'mms#' where # is the S/C number
;         fov: field of view of the summed/averaged counts/fluxes
;         anodes: anodes of the summed/averaged counts/fluxes (shouldn't be used with fov keyword)
;         suffix: suffix of the summed/averaged counts/fluxes
; 
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-01-08 12:02:58 -0800 (Tue, 08 Jan 2019) $
; $LastChangedRevision: 26437 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/hpca/mms_hpca_set_metadata.pro $
;-

pro mms_hpca_set_metadata, tplotnames, prefix = prefix, fov = fov, anodes = anodes, $
    suffix=suffix
    
    if undefined(fov) then fov = ['0','360'] else fov = strcompress(string(fov), /rem) ; default to the full field of view, if none is passed
    if undefined(prefix) then prefix = 'mms1'
    ysubtitle_fov = ''
    if ~undefined(fov) then begin
        fov_str = strcompress('_elev_'+string(fov[0])+'-'+string(fov[1]), /rem)
        ysubtitle_fov = 'ELEV '+fov[0]+'-'+fov[1]
    endif
    if ~undefined(anodes) then begin
        fov_str = '_anodes_' + strjoin(strcompress(string(anodes), /rem), '_')
        ysubtitle_fov = 'Anodes ' + strjoin(strcompress(string(anodes), /rem), ', ')
    endif
    if undefined(suffix) then suffix = ''

    valid_spectra = ['*_count_rate', '*_RF_corrected', '*_bkgd_corrected', '*_norm_counts', '*_flux', '*_vel_dist_fn']+suffix
    append_array, valid_spectra, valid_spectra+fov_str

    for valid_idx = 0, n_elements(valid_spectra)-1 do begin
        vars_to_fix = strmatch(tplotnames, valid_spectra[valid_idx])

        for vars_idx = 0, n_elements(vars_to_fix)-1 do begin

            if vars_to_fix[vars_idx] eq 1 then begin
                options, tplotnames[vars_idx], ystyle=1
                options, tplotnames[vars_idx], spec=1

                ylim, tplotnames[vars_idx], 1, 40000., 1
                zlim, tplotnames[vars_idx], 0, 0, 1
                
                if strmatch(tplotnames[vars_idx], fov_str) then this_fov=fov_str else this_fov=''

                case tplotnames[vars_idx] of
                    ; count rate variable
                    prefix + '_hpca_hplus_count_rate'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="H!U+!N Energy (eV)", ztitle='H!U+!N Count Rate (0.625 s)!U-1!N', ysubtitle=ysubtitle_fov, yunits='eV'
                    prefix + '_hpca_heplus_count_rate'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="He!U+!N Energy (eV)", ztitle='He!U+!N Count Rate (0.625 s)!U-1!N', ysubtitle=ysubtitle_fov, yunits='eV'
                    prefix + '_hpca_heplusplus_count_rate'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="He!U++!N Energy (eV)", ztitle='He!U++!N Count Rate (0.625 s)!U-1!N', ysubtitle=ysubtitle_fov, yunits='eV'
                    prefix + '_hpca_oplus_count_rate'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="O!U+!N Energy (eV)", ztitle='O!U+!N Count Rate (0.625 s)!U-1!N', ysubtitle=ysubtitle_fov, yunits='eV'
                    prefix + '_hpca_oplusplus_count_rate'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="O!U++!N Energy (eV)", ztitle='O!U++!N Count Rate (0.625 s)!U-1!N', ysubtitle=ysubtitle_fov, yunits='eV'
                    ; RF corrected counts
                    prefix + '_hpca_hplus_RF_corrected'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="H!U+!N Energy (eV)", ztitle='H!U+!N RF Corrected Counts', ysubtitle=ysubtitle_fov, yunits='eV'
                    prefix + '_hpca_heplus_RF_corrected'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="He!U+!N Energy (eV)", ztitle='He!U+!N RF Corrected Counts', ysubtitle=ysubtitle_fov, yunits='eV'
                    prefix + '_hpca_heplusplus_RF_corrected'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="He!U++!N Energy (eV)", ztitle='He!U++!N RF Corrected Counts', ysubtitle=ysubtitle_fov, yunits='eV'
                    prefix + '_hpca_oplus_RF_corrected'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="O!U+!N Energy (eV)", ztitle='O!U+!N RF Corrected Counts', ysubtitle=ysubtitle_fov, yunits='eV'
                    prefix + '_hpca_oplusplus_RF_corrected'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="O!U++!N Energy (eV)", ztitle='O!U++!N RF Corrected Counts', ysubtitle=ysubtitle_fov, yunits='eV'
                    ; background corrected counts
                    prefix + '_hpca_hplus_bkgd_corrected'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="H!U+!N Energy (eV)", ztitle='H!U+!N Background Corrected Counts', ysubtitle=ysubtitle_fov, yunits='eV'
                    prefix + '_hpca_heplus_bkgd_corrected'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="He!U+!N Energy (eV)", ztitle='He!U+!N Background Corrected Counts', ysubtitle=ysubtitle_fov, yunits='eV'
                    prefix + '_hpca_heplusplus_bkgd_corrected'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="He!U++!N Energy (eV)", ztitle='He!U++!N Background Corrected Counts', ysubtitle=ysubtitle_fov, yunits='eV'
                    prefix + '_hpca_oplus_bkgd_corrected'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="O!U+!N Energy (eV)", ztitle='O!U+!N Background Corrected Counts', ysubtitle=ysubtitle_fov, yunits='eV'
                    prefix + '_hpca_oplusplus_bkgd_corrected'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="O!U++!N Energy (eV)", ztitle='O!U++!N Background Corrected Counts', ysubtitle=ysubtitle_fov, yunits='eV'
                    ; normalized counts
                    prefix + '_hpca_hplus_norm_counts'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="H!U+!N Energy (eV)", ztitle='H!U+!N Normalized Counts', ysubtitle=ysubtitle_fov, yunits='eV'
                    prefix + '_hpca_heplus_norm_counts'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="He!U+!N Energy (eV)", ztitle='He!U+!N Normalized Counts', ysubtitle=ysubtitle_fov, yunits='eV'
                    prefix + '_hpca_heplusplus_norm_counts'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="He!U++!N Energy (eV)", ztitle='He!U++!N Normalized Counts', ysubtitle=ysubtitle_fov, yunits='eV'
                    prefix + '_hpca_oplus_norm_counts'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="O!U+!N Energy (eV)", ztitle='O!U+!N Normalized Counts', ysubtitle=ysubtitle_fov, yunits='eV'
                    prefix + '_hpca_oplusplus_norm_counts'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="O!U++!N Energy (eV)", ztitle='O!U++!N Normalized Counts', ysubtitle=ysubtitle_fov, yunits='eV'
                    ; flux
                    prefix + '_hpca_hplus_flux'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="H!U+!N Energy (eV)", ztitle='H!U+!N Flux (cm!U2!N s sr eV)!U-1!N', ysubtitle=ysubtitle_fov, yunits='eV'
                    prefix + '_hpca_heplus_flux'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="He!U+!N Energy (eV)", ztitle='He!U+!N Flux (cm!U2!N s sr eV)!U-1!N', ysubtitle=ysubtitle_fov, yunits='eV'
                    prefix + '_hpca_heplusplus_flux'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="He!U++!N Energy (eV)", ztitle='He!U++!N Flux (cm!U2!N s sr eV)!U-1!N', ysubtitle=ysubtitle_fov, yunits='eV'
                    prefix + '_hpca_oplus_flux'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="O!U+!N Energy (eV)", ztitle='O!U+!N Flux (cm!U2!N s sr eV)!U-1!N', ysubtitle=ysubtitle_fov, yunits='eV'
                    prefix + '_hpca_oplusplus_flux'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="O!U++!N Energy (eV)", ztitle='O!U++!N Flux (cm!U2!N s sr eV)!U-1!N', ysubtitle=ysubtitle_fov, yunits='eV'
                    ; velocity distribution function
                    prefix + '_hpca_hplus_vel_dist_fn'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="H!U+!N Energy (eV)", ztitle='H!U+!N Velocity Distribution (s!U3!N cm!U-6!N)', ysubtitle=ysubtitle_fov
                    prefix + '_hpca_heplus_vel_dist_fn'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="He!U+!N Energy (eV)", ztitle='He!U+!N Velocity Distribution (s!U3!N cm!U-6!N)', ysubtitle=ysubtitle_fov
                    prefix + '_hpca_heplusplus_vel_dist_fn'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="He!U++!N Energy (eV)", ztitle='He!U++!N Velocity Distribution (s!U3!N cm!U-6!N)', ysubtitle=ysubtitle_fov
                    prefix + '_hpca_oplus_vel_dist_fn'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="O!U+!N Energy (eV)", ztitle='O!U+!N Velocity Distribution (s!U3!N cm!U-6!N)', ysubtitle=ysubtitle_fov
                    prefix + '_hpca_oplusplus_vel_dist_fn'+suffix+this_fov: options, tplotnames[vars_idx], ytitle="O!U++!N Energy (eV)", ztitle='O!U++!N Velocity Distribution (s!U3!N cm!U-6!N)', ysubtitle=ysubtitle_fov
                    
                    ; SITL omni-directional fluxes
                    prefix + '_hpca_hplus_omni_flux'+suffix: options, tplotnames[vars_idx], ytitle="H!U+!N Flux", ztitle='H!U+!N Flux (cm!U2!N s sr eV)!U-1!N', ysubtitle='[eV]'
                    prefix + '_hpca_heplusplus_omni_flux'+suffix: options, tplotnames[vars_idx], ytitle="He!U++!N Flux", ztitle='He!U++!N Flux (cm!U2!N s sr eV)!U-1!N', ysubtitle='[eV]'
                    prefix + '_hpca_oplus_omni_flux'+suffix: options, tplotnames[vars_idx], ytitle="O!U+!N Flux", ztitle='O!U+!N Flux (cm!U2!N s sr eV)!U-1!N', ysubtitle='[eV]'
                    else: ; do nothing
                endcase

            endif
        endfor
    endfor

    valid_density = '*_number_density'+suffix

    vars_to_fix = strmatch(tplotnames, valid_density)
    for vars_idx = 0, n_elements(vars_to_fix)-1 do begin
        if vars_to_fix[vars_idx] eq 1 then begin
            case tplotnames[vars_idx] of
                prefix + '_hpca_hplus_number_density'+suffix: options, tplotnames[vars_idx], labels='n (H!U+!N)', labflag=1, ytitle=strupcase(prefix+'!CHPCA!C')+'H!U+!N density'
                prefix + '_hpca_heplus_number_density'+suffix: options, tplotnames[vars_idx], labels='n (He!U+!N)', labflag=1, ytitle=strupcase(prefix+'!CHPCA!C')+'He!U+!N density'
                prefix + '_hpca_heplusplus_number_density'+suffix: options, tplotnames[vars_idx], labels='n (He!U++!N)', labflag=1, ytitle=strupcase(prefix+'!CHPCA!C')+'He!U++!N density'
                prefix + '_hpca_oplus_number_density'+suffix: options, tplotnames[vars_idx], labels='n (O!U+!N)', labflag=1, ytitle=strupcase(prefix+'!CHPCA!C')+'O!U+!N density'
                prefix + '_hpca_oplusplus_number_density'+suffix: options, tplotnames[vars_idx], labels='n (O!U++!N)', labflag=1, ytitle=strupcase(prefix+'!CHPCA!C')+'O!U++!N density'
                else:
            endcase
        endif
    endfor

    valid_vel = '*_ion_bulk_velocity*'+suffix

    vars_to_fix = strmatch(tplotnames, valid_vel)
    for vars_idx = 0, n_elements(vars_to_fix)-1 do begin
        if vars_to_fix[vars_idx] eq 1 then begin
            case tplotnames[vars_idx] of
                prefix + '_hpca_hplus_ion_bulk_velocity'+suffix: options, tplotnames[vars_idx], labels=['Vx (H!U+!N)', 'Vy (H!U+!N)', 'Vz (H!U+!N)'], labflag=-1, colors=[2,4,6], ytitle=strupcase(prefix+'!CHPCA!C')+'H!U+!N velocity'
                prefix + '_hpca_heplus_ion_bulk_velocity'+suffix: options, tplotnames[vars_idx], labels=['Vx (He!U+!N)', 'Vy (He!U+!N)', 'Vz (He!U+!N)'], labflag=-1, colors=[2,4,6], ytitle=strupcase(prefix+'!CHPCA!C')+'He!U+!N velocity'
                prefix + '_hpca_heplusplus_ion_bulk_velocity'+suffix: options, tplotnames[vars_idx], labels=['Vx (He!U++!N)', 'Vy (He!U++!N)', 'Vz (He!U++!N)'], labflag=-1, colors=[2,4,6], ytitle=strupcase(prefix+'!CHPCA!C')+'He!U++!N velocity'
                prefix + '_hpca_oplus_ion_bulk_velocity'+suffix: options, tplotnames[vars_idx], labels=['Vx (O!U+!N)', 'Vy (O!U+!N)', 'Vz (O!U+!N)'], labflag=-1, colors=[2,4,6], ytitle=strupcase(prefix+'!CHPCA!C')+'O!U+!N velocity'
                prefix + '_hpca_oplusplus_ion_bulk_velocity'+suffix: options, tplotnames[vars_idx], labels=['Vx (O!U++!N)', 'Vy (O!U++!N)', 'Vz (O!U++!N)'], labflag=-1, colors=[2,4,6], ytitle=strupcase(prefix+'!CHPCA!C')+'O!U++!N velocity'
                
                ; GSM velocity vars
                prefix + '_hpca_hplus_ion_bulk_velocity_GSM'+suffix: options, tplotnames[vars_idx], labels=['Vx (H!U+!N)', 'Vy (H!U+!N)', 'Vz (H!U+!N)'], labflag=-1, colors=[2,4,6], ytitle=strupcase(prefix+'!CHPCA!C')+'H!U+!N velocity!CGSM'
                prefix + '_hpca_heplus_ion_bulk_velocity_GSM'+suffix: options, tplotnames[vars_idx], labels=['Vx (He!U+!N)', 'Vy (He!U+!N)', 'Vz (He!U+!N)'], labflag=-1, colors=[2,4,6], ytitle=strupcase(prefix+'!CHPCA!C')+'He!U+!N velocity!CGSM'
                prefix + '_hpca_heplusplus_ion_bulk_velocity_GSM'+suffix: options, tplotnames[vars_idx], labels=['Vx (He!U++!N)', 'Vy (He!U++!N)', 'Vz (He!U++!N)'], labflag=-1, colors=[2,4,6], ytitle=strupcase(prefix+'!CHPCA!C')+'He!U++!N velocity!CGSM'
                prefix + '_hpca_oplus_ion_bulk_velocity_GSM'+suffix: options, tplotnames[vars_idx], labels=['Vx (O!U+!N)', 'Vy (O!U+!N)', 'Vz (O!U+!N)'], labflag=-1, colors=[2,4,6], ytitle=strupcase(prefix+'!CHPCA!C')+'O!U+!N velocity!CGSM'
                prefix + '_hpca_oplusplus_ion_bulk_velocity_GSM'+suffix: options, tplotnames[vars_idx], labels=['Vx (O!U++!N)', 'Vy (O!U++!N)', 'Vz (O!U++!N)'], labflag=-1, colors=[2,4,6], ytitle=strupcase(prefix+'!CHPCA!C')+'O!U++!N velocity!CGSM'

                
                else:
            endcase
        endif
    endfor

    valid_temp = '*_scalar_temperature'+suffix

    vars_to_fix = strmatch(tplotnames, valid_temp)
    for vars_idx = 0, n_elements(vars_to_fix)-1 do begin
        if vars_to_fix[vars_idx] eq 1 then begin
            case tplotnames[vars_idx] of
                prefix + '_hpca_hplus_scalar_temperature'+suffix: options, tplotnames[vars_idx], labels='T (H!U+!N)', labflag=1, ytitle=strupcase(prefix+'!CHPCA!C')+'H!U+!N temp', ysubtitle='[eV]'
                prefix + '_hpca_heplus_scalar_temperature'+suffix: options, tplotnames[vars_idx], labels='T (He!U+!N)', labflag=1, ytitle=strupcase(prefix+'!CHPCA!C')+'He!U+!N temp', ysubtitle='[eV]'
                prefix + '_hpca_heplusplus_scalar_temperature'+suffix: options, tplotnames[vars_idx], labels='T (He!U++!N)', labflag=1, ytitle=strupcase(prefix+'!CHPCA!C')+'He!U++!N temp', ysubtitle='[eV]'
                prefix + '_hpca_oplus_scalar_temperature'+suffix: options, tplotnames[vars_idx], labels='T (O!U+!N)', labflag=1, ytitle=strupcase(prefix+'!CHPCA!C')+'O!U+!N temp', ysubtitle='[eV]'
                prefix + '_hpca_oplusplus_scalar_temperature'+suffix: options, tplotnames[vars_idx], labels='T (O!U++!N)', labflag=1, ytitle=strupcase(prefix+'!CHPCA!C')+'O!U++!N temp', ysubtitle='[eV]'
                else:
            endcase
        endif
    endfor
end
