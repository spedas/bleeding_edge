;+
;NAME:
; spp_swp_spi_cmn_l2vararr
;PURPOSE:
; Returns an array with common block variable names for the input
; apid.
;CALLING SEQUENCE:
; vars = spp_swp_spi_cmn_l2vararr(apid)
;INPUT:
; apid = the app_id for the data type;
;OUTPUT:
; vars = a 3, N array with common block variable names for the input
; apid, with three columns, one is the common block name, the second is
; the name in the CDF file, the third is 'Y' or 'N' for record
; variance.
;HISTORY:
; 16-sep-2018, rlivi, rlivi@berkeley.edu
;SVN Berkeley Information:
; $LastChangedBy: rlivi2 $
; $LastChangedDate: 2018-12-03 23:01:25 -0800 (Mon, 03 Dec 2018) $
; $LastChangedRevision: 26222 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_cmn_l2vararr.pro $
;-

FUNCTION spp_swp_spi_cmn_l2vararr, apid

  app_id = strlowcase(strcompress(/remove_all, apid))
  a0 = strmid(app_id, 0, 1)
  If(a0 Eq 'c' OR app_id EQ 'd0' OR app_id EQ 'd1' OR $
     app_id EQ 'd2' OR app_id EQ 'd3' OR app_id EQ 'd4') THEN BEGIN
     vars = [['PROJECT_NAME',    'PROJECT_NAME',   'N'], $
             ['SPACECRAFT',      'SPACECRAFT',     'N'], $
             ['DATA_NAME',       'DATA_NAME',      'N'], $
             ['APID',            'APID',           'N'], $
             ['UNITS_NAME',      'UNITS_NAME',     'N'], $ 
             ['UNITS_PROCEDURE', 'UNITS_PROCEDURE','N'], $ 
             ['VALID',           'VALID',          'Y'], $
             ['QUALITY_FLAG',    'QUALITY_FLAG',   'Y'], $ 
             ['TIME',            'TIME_START',     'Y'], $
             ['MET',             'TIME_MET',       'Y'], $
             ['END_TIME',        'TIME_END',       'Y'], $
             ['DELTA_T',         'TIME_DELTA',     'Y'], $
             ['INTEG_T',         'TIME_INTEG',     'Y'], $
             ['EPROM_VER',       'EPROM_VER',      'Y'], $
             ['HEADER',          'HEADER',         'Y'], $
             ['MODE',            'MODE',           'Y'], $
             ['RATE',            'RATE',           'Y'], $
             ['SWP_IND',         'SWP_IND',        'Y'], $
             ['MLUT_IND',        'MLUT_IND',       'Y'], $ 
             ['EFF_IND',         'EFF_IND',        'Y'], $
             ['ATT_IND',         'ATT_IND',        'Y'], $
             ['NENERGY',         'NENERGY',        'N'], $
             ['ENERGY',          'ENERGY',         'N'], $
             ['DENERGY',         'DENERGY',        'N'], $
             ['NBINS',           'NBINS',          'N'], $
             ['BINS',            'BINS',           'N'], $
             ['NDEF',            'NDEF',           'N'], $
             ['NANODE',          'NANODE',         'N'], $
             ['THETA',           'THETA',          'N'], $
             ['DTHETA',          'DTHETA',         'N'], $
             ['PHI',             'PHI',            'N'], $
             ['DPHI',            'DPHI',           'N'], $
             ['DOMEGA',          'DOMEGA',         'N'], $
             ['GF',              'GF',             'N'], $
             ['EFF',             'EFF',            'N'], $ 
             ['GEOM_FACTOR',     'GEOM_FACTOR',    'N'], $
             ['DEAD1',           'DEAD_TIME_1',    'N'], $
             ['DEAD2',           'DEAD_TIME_2',    'N'], $
             ['DEAD3',           'DEAD_TIME_3',    'N'], $
             ['NMASS',           'NMASS',          'N'], $
             ['MASS',            'MASS',           'N'], $
             ['MASS_ARR',        'MASS_ARR',       'N'], $
             ['TOF_ARR',         'TOF_ARR',        'N'], $
             ['TWT_ARR',         'TWT_ARR',        'N'], $
             ['CHARGE',          'CHARGE',         'N'], $
             ['SC_POT',          'SC_POT',         'Y'], $
             ['MAGF',            'MAGF',           'Y'], $
             ['QUAT_SC',         'QUAT_SC',        'Y'], $
             ['QUAT_MSO',        'QUAT_MSO',       'Y'], $
             ['BINS_SC',         'BINS_SC',        'Y'], $
             ['POS_SC_MSO',      'POS_SC_MSO',     'Y'], $
             ['BKG',             'BKG',            'Y'], $
             ['DEAD',            'DEAD',           'Y'], $
             ['DATA',            'DATA',           'Y'], $
             ['EFLUX',           'EFLUX',          'Y']]
  ENDIF ELSE IF (app_id EQ 'd8' OR app_id EQ 'd9') THEN BEGIN
     vars = [['PROJECT_NAME', 'PROJECT_NAME', 'N'], $
             ['SPACECRAFT',   'SPACECRAFT',   'N'], $
             ['DATA_NAME',    'DATA_NAME',    'N'], $
             ['APID',         'APID',         'N'], $
             ['VALID',        'VALID',        'Y'], $
             ['QUALITY_FLAG', 'QUALITY_FLAG', 'Y'], $ 
             ['TIME',         'TIME_START',   'Y'], $
             ['MET',          'TIME_MET',     'Y'], $
             ['END_TIME',     'TIME_END',     'Y'], $
             ['INTEG_T',      'INTEG_TIME',   'Y'], $
             ['EPROM_VER',    'EPROM_VER',    'Y'], $
             ['HEADER',       'HEADER',       'Y'], $
             ['MODE',         'MODE',         'Y'], $
             ['RATE',         'RATE',         'Y'], $
             ['SWP_IND',      'SWP_IND',      'Y'], $
             ['ENERGY',       'ENERGY',       'N'], $
             ['NRATE',        'NRATE',        'N'], $
             ['RATE_LABELS',  'RATE_LABELS',  'N'], $
             ['RATES',        'RATES',        'Y']]
  ENDIF ELSE IF (app_id Eq 'da') THEN BEGIN
     vars = [['PROJECT_NAME', 'PROJECT_NAME', 'N'], $
             ['SPACECRAFT',   'SPACECRAFT',   'N'], $
             ['DATA_NAME',    'DATA_NAME',    'N'], $
             ['APID',         'APID',         'N'], $
             ['VALID',        'VALID',        'Y'], $
             ['QUALITY_FLAG', 'QUALITY_FLAG', 'Y'], $ 
             ['TIME',         'TIME_START',   'Y'], $
             ['MET',          'TIME_MET',     'Y'], $
             ['END_TIME',     'TIME_END',     'Y'], $
             ['INTEG_T',      'INTEG_TIME',   'Y'], $
             ['EPROM_VER',    'EPROM_VER',    'Y'], $
             ['HEADER',       'HEADER',       'Y'], $
             ['MODE',         'MODE',         'Y'], $
             ['RATE',         'RATE',         'Y'], $
             ['SWP_IND',      'SWP_IND',      'Y'], $
             ['ENERGY',       'ENERGY',       'N'], $
             ['NRATE',        'NRATE',        'N'], $
             ['RATE_LABELS',  'RATE_LABELS',  'N'], $
             ['RATE_CHANNEL', 'RATE_CHANNEL', 'Y'], $
             ['RATES',        'RATES',        'Y']]
  ENDIF ELSE IF (app_id Eq 'd6') THEN BEGIN
     vars = [['PROJECT_NAME',   'PROJECT_NAME',   'N'], $
             ['SPACECRAFT',     'SPACECRAFT',     'N'], $
             ['DATA_NAME',      'DATA_NAME',      'N'], $
             ['APID',           'APID',           'N'], $
             ['VALID',          'VALID',          'Y'], $
             ['QUALITY_FLAG',   'QUALITY_FLAG',   'Y'], $
             ['TIME',           'TIME_UNIX',      'Y'], $
             ['MET',            'TIME_MET',       'Y'], $
             ['TDC_1',          'TDC_1',          'Y'], $
             ['TDC_2',          'TDC_2',          'Y'], $
             ['TDC_3',          'TDC_3',          'Y'], $
             ['TDC_4',          'TDC_4',          'Y'], $
             ['EVENT_CODE',     'EVENT_CODE',     'Y'], $
             ['CYCLESTEP',      'CYCLESTEP',      'Y'], $
             ['ENERGY',         'ENERGY',         'Y'], $
             ['TDC1_CONV',      'TDC1_CONV',      'N'], $
             ['TDC2_CONV',      'TDC2_CONV',      'N'], $
             ['TDC3_CONV',      'TDC3_CONV',      'N'], $
             ['TDC4_CONV',      'TDC4_CONV',      'N'], $
             ['TDC1_OFFSET',    'TDC1_OFFSET',    'N'], $
             ['TDC2_OFFSET',    'TDC2_OFFSET',    'N'], $
             ['TDC3_OFFSET',    'TDC3_OFFSET',    'N'], $
             ['TDC4_OFFSET',    'TDC4_OFFSET',    'N'], $
             ['AN_BIN_TDC3',    'AN_BIN_TDC3',    'N'], $
             ['AN_BIN_TDC4',    'AN_BIN_TDC4',    'N'], $
             ['MS_BIAS_OFFSET', 'MS_BIAS_OFFSET', 'N'], $
             ['EVCONVLUT',      'EVCONVLUT',      'N'], $
             ['TIMERST',        'TIMERST',        'N']]
  ENDIF ELSE IF (app_id EQ 'd7') THEN BEGIN
     vars = [['PROJECT_NAME', 'PROJECT_NAME', 'N'], $
             ['SPACECRAFT',   'SPACECRAFT',   'N'], $
             ['DATA_NAME',    'DATA_NAME',    'N'], $
             ['APID',         'APID',         'N'], $
             ['VALID',        'VALID',        'Y'], $
             ['QUALITY_FLAG', 'QUALITY_FLAG', 'Y'], $ 
             ['TIME',         'TIME_UNIX',    'Y'], $
             ['MET',          'TIME_MET',     'Y'], $
             ['HKP_RAW',      'HKP_RAW',      'Y'], $
             ['HKP_CALIB',    'HKP_CALIB',    'Y'], $
             ['HKP_IND',      'HKP_IND',      'Y'], $
             ['NHKP',         'NHKP',         'N'], $
             ['HKP_CONV',     'HKP_CONV',     'N'], $
             ['HKP_LABELS',   'HKP_LABELS',   'N']]
  ENDIF ELSE IF (app_id EQ 'db') THEN BEGIN
     vars = [['PROJECT_NAME', 'PROJECT_NAME', 'N'], $
             ['SPACECRAFT',   'SPACECRAFT',   'N'], $
             ['DATA_NAME',    'DATA_NAME',    'N'], $
             ['APID',         'APID',         'N'], $
             ['VALID',        'VALID',        'Y'], $
             ['QUALITY_FLAG', 'QUALITY_FLAG', 'Y'], $ 
             ['TIME',         'TIME_START',   'Y'], $
             ['MET',          'TIME_MET',     'Y'], $
             ['END_TIME',     'TIME_END',     'Y'], $
             ['INTEG_T',      'INTEG_TIME',   'Y'], $
             ['EPROM_VER',    'EPROM_VER',    'Y'], $
             ['HEADER',       'HEADER',       'Y'], $
             ['MODE',         'MODE',         'Y'], $
             ['RATE',         'RATE',         'Y'], $
             ['SWP_IND',      'SWP_IND',      'Y'], $
             ['ENERGY',       'ENERGY',       'N'], $
             ['TOF',          'TOF',          'N'], $
             ['DATA',         'DATA',         'Y']]
  ENDIF ELSE IF(app_id EQ '2a') THEN BEGIN
     vars = [['PROJECT_NAME',    'PROJECT_NAME',    'N'], $
             ['SPACECRAFT',      'SPACECRAFT',      'N'], $
             ['DATA_NAME',       'DATA_NAME',       'N'], $
             ['APID',            'APID',            'N'], $
             ['QUALITY_FLAG',    'QUALITY_FLAG',    'Y'], $ 
             ['TIME',            'TIME_UNIX',       'Y'], $
             ['MET',             'TIME_MET',        'Y'], $
             ['NHKP',            'NHKP',            'N'], $
             ['CALIB_CONSTANTS', 'CALIB_CONSTANTS', 'N'], $
             ['HKP_LABELS',      'HKP_LABELS',      'N'], $
             ['HKP_RAW',         'HKP_RAW',         'Y'], $
             ['HKP',             'HKP',             'Y']]
  ENDIF ELSE BEGIN
     dprint, 'APID: '+app_id+'Not recognized'
     vars = -1
  ENDELSE
  RETURN, vars
END
