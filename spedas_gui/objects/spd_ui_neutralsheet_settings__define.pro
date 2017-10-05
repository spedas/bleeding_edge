;+
; NAME:
;  spd_ui_neutralsheet_settings__define
;
; PURPOSE:
;  Settings object for the field models panel
;
; CALLING SEQUENCE:
;  neutralsheet = obj_new('SPD_UI_NEUTRALSHEET_SETTINGS')
;
; INPUT:
;  none
;
; KEYWORDS:
;   pos_tvar: variable containing position data, in km, in gsm
;   nsmodel: neutral sheet model name. models include:
;     'sm', 'aen', 'den', 'fairfield', 'themis', 'lopez'
;   kp: Kp index (Kp index is only for the Lopez Neutral Sheet Model)
;   magnetic_lat: magnetic latitude (mlt is only used by the Lopez Neutral Sheet Model)
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_neutralsheet_settings__define.pro $
;-

function spd_ui_neutralsheet_settings::init, $
  pos_tvar=pos_tvar,                       $
  ns_model=ns_model,                       $
  kp_index=kp_index,                       $
  magnetic_lat=magnetic_lat

  if undefined(pos_tvar) then pos_tvar = ''
  if undefined(ns_model) then ns_model = 'AEN'
  if undefined(kp_index) then kp_index = 0.
  if undefined(magnetic_lat) then magnetic_lat = 0.

  self.pos_tvar = pos_tvar
  self.ns_model = ns_model
  self.kp_index = kp_index
  self.magnetic_lat = magnetic_lat
  return, 1
end

pro spd_ui_neutralsheet_settings__define
  ; neutral sheet settings
  state = {SPD_UI_NEUTRALSHEET_SETTINGS, $
    pos_tvar: '',                $
    ns_model: '',                $
    kp_index: 0.,                $
    magnetic_lat: 0.,            $
    inherits spd_ui_getset       $
  }
end
