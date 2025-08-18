;+
;
; Unit tests for MMS curlometer routines
;
; To run:
;     IDL> mgunit, 'mms_curlometer_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-10-09 09:19:08 -0700 (Mon, 09 Oct 2017) $
; $LastChangedRevision: 24128 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_curlometer_ut__define.pro $
;-

function mms_curlometer_ut::test_both_methods
    trange = ['2015-10-30/05:15:45', '2015-10-30/05:15:48']
    mms_load_fgm, trange=trange, /get_fgm_ephemeris, probes=[1, 2, 3, 4], data_rate='brst', /time_clip
    mms_lingradest, fields='mms'+['1', '2', '3', '4']+'_fgm_b_gse_brst_l2', positions='mms'+['1', '2', '3', '4']+'_fgm_r_gse_brst_l2', suffix='_lingradest'
    mms_curl, trange=trange, fields='mms'+['1', '2', '3', '4']+'_fgm_b_gse_brst_l2', positions='mms'+['1', '2', '3', '4']+'_fgm_r_gse_brst_l2', suffix='_mms_curl'
    get_data, 'jx_lingradest', data=lx
    get_data, 'jy_lingradest', data=ly
    get_data, 'jz_lingradest', data=lz
    get_data, 'jtotal_mms_curl', data=d
    assert, total(d.Y[0, *]*1e9-[lx.Y[0], ly.Y[0], lz.Y[0]] lt 1) eq 3, 'Problem comparing curlometer methods on the same event'
    return, 1
end

function mms_curlometer_ut::test_lingradest
    trange = ['2015-10-30/05:15:45', '2015-10-30/05:15:48']
    mms_load_fgm, trange=trange, /get_fgm_ephemeris, probes=[1, 2, 3, 4], data_rate='brst'
    mms_lingradest, fields='mms'+['1', '2', '3', '4']+'_fgm_b_gse_brst_l2', positions='mms'+['1', '2', '3', '4']+'_fgm_r_gse_brst_l2'
    assert, spd_data_exists('jx jy jz CxB CyB CzB', trange[0], trange[1]), 'Problem with mms_lingradest'
    return, 1
end

function mms_curlometer_ut::test_basic
    trange = ['2015-10-30/05:15:45', '2015-10-30/05:15:48']
    mms_load_fgm, trange=trange, /get_fgm_ephemeris, probes=[1, 2, 3, 4], data_rate='brst'
    mms_curl, trange=trange, fields='mms'+['1', '2', '3', '4']+'_fgm_b_gse_brst_l2', positions='mms'+['1', '2', '3', '4']+'_fgm_r_gse_brst_l2'
    assert, spd_data_exists('jtotal curlB jperp jpar', trange[0], trange[1]), 'Problem with mms_curl'
    return, 1
end

pro mms_curlometer_ut::setup
    del_data, '*'
end

function mms_curlometer_ut::init, _extra=e
    if (~self->MGutTestCase::init(_extra=e)) then return, 0
    ; the following adds code coverage % to the output
    self->addTestingRoutine, ['mms_curl', 'mms_lingradest', 'lingradest']
    return, 1
end

pro mms_curlometer_ut__define
    define = { mms_curlometer_ut, inherits MGutTestCase }
end