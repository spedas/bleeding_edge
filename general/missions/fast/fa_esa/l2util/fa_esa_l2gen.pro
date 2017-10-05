;+
;NAME:
; fa_esa_l2gen
;PURPOSE:
; Generates FAST ESA L2 files
;CALLING SEQUENCE:
; fa_esa_l2gen, orbit
;KEYWORDS:
; local_data_dir = if set, then write files in orbit directories under
;                  local_data_dir/fast/l2 , the default is to
;                  use ROOT_DATA_DIR, /disks/data
;INPUT:
; Either the date or input L0 file, via keyword:
;HISTORY:
; 2015-09-02, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2017-05-26 12:02:12 -0700 (Fri, 26 May 2017) $
; $LastChangedRevision: 23357 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2util/fa_esa_l2gen.pro $
;-
Pro fa_esa_l2gen, orbit, local_data_dir = local_data_dir, _extra = _extra


;Run in Z buffer
  set_plot,'z'

  load_position = 'init'
  catch, error_status
  
  If(error_status ne 0) Then Begin
     help, /last_message, output = err_msg
     For ll = 0, n_elements(err_msg)-1 Do print, err_msg[ll]
     If(load_position Eq 'init') Then Begin
        print, 'Problem with initialization'
        goto, skip_all
     Endif Else Begin
        print, 'Problem with type: '+load_position+' Skipping:'+load_position
        Case load_position Of
           'ies':goto, skip_ies
           'ees':goto, skip_ees
           'ieb':goto, skip_ieb
           'eeb':goto, skip_eeb
           Else: goto, skip_all
        Endcase
     Endelse
  Endif
  
;Clear all common blocks
  fa_esa_clear_common_blocks

  If(keyword_set(local_data_dir)) Then ldir = local_data_dir $
  Else Begin
     If(~is_string(getenv('ROOT_DATA_DIR'))) Then Begin
        ldir = root_data_dir()
     Endif Else ldir = getenv('ROOT_DATA_DIR')
  Endelse

  sw_vsn = fa_esa_current_sw_version()
  vxx = 'v'+string(sw_vsn, format='(i2.2)')

;handle orbit string
  orbit = long(orbit[0])
  orbit_str = strcompress(string(orbit,format='(i05)'), /remove_all)
  orbit_dir = strmid(orbit_str,0,2)+'000'
;Unlike L1 files, we put the date in L2 files
  dtemp = fa_orbit_to_time(orbit)
  date = time_string(dtemp[1], tformat='YYYYMMDDhhmmss')

;For each type, create and output the L2 structure
  type = 'ies'
  load_position = type
  fa_esa_l2create, type = type, orbit = orbit, data_struct = dat
  If(is_struct(dat)) Then Begin
     fa_esa_cmn_l2gen, dat, esa_type = type, otp_struct = otp_struct, fullfile_out =  fullfile, _extra = _extra
     If(~is_struct(otp_struct)) Then message, type+' Write to CDF failed: orbit'+strcompress(/remove_all, string(orbit))
  Endif Else Begin
     message, type+' L2 generation failed: orbit'+strcompress(/remove_all, string(orbit))
  Endelse
;move the file into the correct database directory
  relpathname='fast/l2/'+type+'/'+orbit_dir;+'/fa_l2_'+type+'_'+date+'_'+orbit_str+'_'+vxx+'.cdf'
  final_resting_place = ldir+relpathname
  file_move, fullfile, final_resting_place, /overwrite
  skip_ies:

  type = 'ees'
  load_position = type
  fa_esa_l2create, type = type, orbit = orbit, data_struct = dat
  If(is_struct(dat)) Then Begin
     fa_esa_cmn_l2gen, dat, esa_type = type, otp_struct = otp_struct, fullfile_out =  fullfile, _extra = _extra
     If(~is_struct(otp_struct)) Then message, type+' Write to CDF failed: orbit'+strcompress(/remove_all, string(orbit))
  Endif Else Begin
     message, type+' L2 generation failed: orbit'+strcompress(/remove_all, string(orbit))
  Endelse
;move the file into the correct database directory
  relpathname='fast/l2/'+type+'/'+orbit_dir;+'/fa_l2_'+type+'_'+date+'_'+orbit_str+'_'+vxx+'.cdf'
  final_resting_place = ldir+relpathname
  file_move, fullfile, final_resting_place, /overwrite
  skip_ees:

  type = 'ieb'
  load_position = type
  fa_esa_l2create, type = type, orbit = orbit, data_struct = dat
  If(is_struct(dat)) Then Begin
     fa_esa_cmn_l2gen, dat, esa_type = type, otp_struct = otp_struct, fullfile_out =  fullfile, _extra = _extra
     If(~is_struct(otp_struct)) Then message, type+' Write to CDF failed: orbit'+strcompress(/remove_all, string(orbit))
  Endif Else Begin
     message, type+' L2 generation failed: orbit'+strcompress(/remove_all, string(orbit))
  Endelse
;move the file into the correct database directory
  relpathname='fast/l2/'+type+'/'+orbit_dir;+'/fa_l2_'+type+'_'+date+'_'+orbit_str+'_'+vxx+'.cdf'
  final_resting_place = ldir+relpathname
  file_move, fullfile, final_resting_place, /overwrite
  skip_ieb:

  type = 'eeb'
  load_position = type
  fa_esa_l2create, type = type, orbit = orbit, data_struct = dat
  If(is_struct(dat)) Then Begin
     fa_esa_cmn_l2gen, dat, esa_type = type, otp_struct = otp_struct, fullfile_out =  fullfile, _extra = _extra
     If(~is_struct(otp_struct)) Then message, type+' Write to CDF failed: orbit'+strcompress(/remove_all, string(orbit))
  Endif Else Begin
     message, type+' L2 generation failed: orbit'+strcompress(/remove_all, string(orbit))
  Endelse
;move the file into the correct database directory
  relpathname='fast/l2/'+type+'/'+orbit_dir;+'/fa_l2_'+type+'_'+date+'_'+orbit_str+'_'+vxx+'.cdf'
  final_resting_place = ldir+relpathname
  file_move, fullfile, final_resting_place, /overwrite
  skip_eeb:

  load_position = 'done'

  message, /info, 'All ESA datatypes finished, Orbit: '+strcompress(/remove_all, orbit)
  
  skip_all:

  Return

End

