;+
; NAME:
;  spd_ui_fieldmodels_settings__define
;
; PURPOSE:
;  Settings object for the field models panel
;
; CALLING SEQUENCE:
;  fieldmodels = obj_new('SPD_UI_FIELDMODELS_SETTINGS')
; 
; INPUT:
;  none
;  
; KEYWORDS:
;   pos_tvar: variable containing position data, in km
;   pressure_tvar: variable containing dynamic pressure
;   imf_by_tvar: variable containing IMF By data, in nT
;   imf_bz_tvar: variable containing IMF Bz data, in nT
;   sw_density_tvar: variable containing solar wind proton density, in #/cc
;   sw_speed_tvar: variable containing solar wind proton speed, in km/s
;   dst_tvar: variable containing Dst (or Sym-H) data, in nT
;   w_coeff_tvar: variable containing W coefficients for the TS04 model
;   g_coeff_tvar: variable containing G coefficients for the T01 model
;   nindex_tvar: variable containing N-Index for the TA15N model
;   bindex_tvar: variable containing B-Index for the TA15B model
;   t89_kp: iopt for the Kp index, for the T89 model
;   t89_set_tilt: user supplied tilt angle for the T89 model
;   t89_add_tilt: user supplied angle to add to the model tilt angle for T89
;   output_options: models to run - [model at position, equatorial footprint, ionospheric footprint]
;   geopack_2008: flag to switch between original and Geopack 2008 library routines
;       
;$LastChangedBy: jwl $
;$LastChangedDate: 2021-06-22 13:30:26 -0700 (Tue, 22 Jun 2021) $
;$LastChangedRevision: 30078 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_fieldmodels_settings__define.pro $
;-

function spd_ui_fieldmodels_settings::init, $
    pos_tvar=pos_tvar,                       $
    imf_by_tvar=imf_by_tvar,                 $
    imf_bz_tvar=imf_bz_tvar,                 $
    sw_density_tvar=sw_density_tvar,         $
    sw_speed_tvar=sw_speed_tvar,             $
    dst_tvar=dst_tvar,                       $
    w_coeff_tvar=w_coeff_tvar,               $
    g_coeff_tvar=g_coeff_tvar,               $
    output_options=output_options,           $
    t89_kp=t89_kp,                           $
    t89_set_tilt=t89_set_tilt,               $
    t01_storm=t01_storm,                     $
    pressure_tvar=pressure_tvar,             $
    bindex_tvar=bindex_tvar,                 $
    nindex_tvar=nindex_tvar,                 $
    t89_add_tilt=t89_add_tilt,               $
    geopack_2008=geopack_2008
    
    if undefined(pos_tvar) then pos_tvar = ''
    if undefined(imf_by_tvar) then imf_by_tvar = ''
    if undefined(imf_bz_tvar) then imf_bz_tvar = ''
    if undefined(sw_density_tvar) then sw_density_tvar = ''
    if undefined(sw_speed_tvar) then sw_speed_tvar = ''
    if undefined(dst_tvar) then dst_tvar = ''
    if undefined(w_coeff_tvar) then w_coeff_tvar = ''
    if undefined(g_coeff_tvar) then g_coeff_tvar = ''
    if undefined(output_options) then output_options = [1,0,0] ; initialize with only model at position
    if undefined(t89_kp) then t89_kp = 2
    if undefined(t89_set_tilt) then t89_set_tilt = ''
    if undefined(t89_add_tilt) then t89_add_tilt = ''
    if undefined(t01_storm) then t01_storm = 0
    if undefined(pressure_tvar) then pressure_tvar = ''
    if undefined(bindex_tvar) then bindex_tvar = ''
    if undefined(nindex_tvar) then nindex_tvar = ''
    if undefined(geopack_2008) then geopack_2008=0
   
    
    self.pos_tvar = pos_tvar
    self.imf_by_tvar = imf_by_tvar
    self.imf_bz_tvar = imf_bz_tvar
    self.sw_density_tvar = sw_density_tvar
    self.sw_speed_tvar = sw_speed_tvar
    self.dst_tvar = dst_tvar
    self.w_coeff_tvar = w_coeff_tvar
    self.g_coeff_tvar = g_coeff_tvar
    self.t89_kp = t89_kp
    self.t89_set_tilt = t89_set_tilt
    self.t89_add_tilt = t89_add_tilt
    self.t01_storm = t01_storm
    self.pressure_tvar = pressure_tvar
    self.bindex_tvar = bindex_tvar
    self.nindex_tvar = nindex_tvar
    self.output_options = output_options
    self.geopack_2008 = geopack_2008
    return, 1
end

pro spd_ui_fieldmodels_settings__define
    ; field models settings 
    state = {SPD_UI_FIELDMODELS_SETTINGS, $
             pos_tvar: '',                $
             imf_by_tvar: '',             $
             imf_bz_tvar: '',             $
             sw_density_tvar: '',         $
             sw_speed_tvar: '',           $
             dst_tvar: '',                $
             w_coeff_tvar: '',            $
             g_coeff_tvar: '',            $
             output_options: [1,0,0],     $
             t89_kp: 2,                   $
             t89_set_tilt: '',            $
             t89_add_tilt: '',            $
             t01_storm: 0,                $
             pressure_tvar: '',           $
             bindex_tvar: '',             $
             nindex_tvar: '',             $
             geopack_2008: 0,              $
             inherits spd_ui_getset       $
             }
end
