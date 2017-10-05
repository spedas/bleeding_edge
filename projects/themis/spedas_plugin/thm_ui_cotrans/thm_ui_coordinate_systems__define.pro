;+ 
; NAME: 
;     thm_ui_coordinate_systems
;
; PURPOSE:
;     This object exists for two purposes:
;         1) Maintain the list of coordinate systems used throughout SPEDAS 
;            in a single location
;         2) Encapsulate the methods that produce coordinate system lists
;            for different contexts, e.g., the verify data panel, 
;            load data panel, data processing panel, etc.
;               
;     Both are ultimately for code maintenance
;
;
; KEYWORDS:
;     
; METHODS:
;     makeCoordSysList: creates and returns a list of valid coordinate systems
;     makeCoordSysListForSpinModel: creates and returns a list of valid 
;         coordinate systems that don't require spin model variables to be loaded
;     makeCoordSysListForTHEMIS: creates and returns a list of valid THEMIS-centric 
;         coordinate systems ('dsl', 'ssl', 'spg')
;     makeCoordSysListForTHEMISReqPos: creates and returns a list of valid THEMIS coordinate
;         systems that require position data to be transformed to/from
;
; EXAMPLES:
;     To make a simple list of general purpose coordinate systems:
;        THEMIS> coordSysObj = obj_new('thm_ui_coordinate_systems') ; create the object
;        THEMIS> print, coordSysObj->makeCoordSysList(/uppercase) ; make the list
;           DSL SSL SPG GSM AGSM GSE GEI SM GEO MAG SEL SSE
;        THEMIS> print, coordSysObj->makeCoordSysList(/uppercase, /include_none) ; include N/A 
;           N/A DSL SSL SPG GSM GSE GEI SM GEO MAG SEL SSE
;        THEMIS> print, coordSysObj->makeCoordSysList(/uppercase, /include_none, /include_all) ; includes 'N/A' and 'ALL'
;           N/A DSL SSL SPG GSM GSE GEI SM GEO MAG SEL SSE ALL
;        THEMIS> obj_destroy, coordSysObj ; delete the object
;
;
; NOTE: 
;      All coordinate system lists exist in this object's constructor, with pointers
;        to the lists in the objects state structure
;        
;      Changes to this object should be reflected in the corresponding test procedure, thm_ui_test_coordinate_systems_obj
;
;
;$LastChangedBy: crussell $
;$LastChangedDate: 2015-09-18 14:21:09 -0700 (Fri, 18 Sep 2015) $
;$LastChangedRevision: 18843 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spedas_plugin/thm_ui_cotrans/thm_ui_coordinate_systems__define.pro $
;
;-

; destructor
function thm_ui_coordinate_systems::cleanup
    if ptr_valid(self.coordinate_systems) then ptr_free, self.coordinate_systems
    if ptr_valid(self.fgm_scm_load_list) then ptr_free, self.fgm_scm_load_list
    if ptr_valid(self.fit_esa_load_list) then ptr_free, self.fit_esa_load_list
    if ptr_valid(self.misc_coord_sys_list) then ptr_free, self.misc_coord_sys_list
    if ptr_valid(self.themis_coord_sys_list) then ptr_free, self.themis_coord_sys_list
    if ptr_valid(self.geomag_coord_sys_list) then ptr_free, self.geomag_coord_sys_list
    if ptr_valid(self.themis_pos_data_req_list) then ptr_free, self.themis_pos_data_req_list
    return, 1
end

; constructor
function thm_ui_coordinate_systems::init
    ; THEMIS, probe-centered coordinate systems
    themis_coord_sys_list = ['dsl', 'ssl', 'spg']
    
    ; standard Earth-centered coordinate systems
    geomag_coord_sys_list = ['gsm', $ ; Geocentric Solar Magnetospheric
                             'agsm', $ ; aberrated GSM
                             'gse', $ ; Geocentric Solar Ecliptic
                             'gei', $ ; Geocentric Equatorial Inertial
                             'sm', $ ; Solar Magnetic
                             'geo', $ ; Geographic
                             'mag', $ ; Magnetic
                             'j2000' $ ; J2000
                             ]
    
    ; additional coordinate systems
    misc_coord_sys_list = ['enp', $ ; GOES magnetometer centered
                           'rtn', $ ; STEREO (Radial Tangential Normal)
                           'hdz', $ ; ground mag coordinate system
                           'gci' $  ; Geocentric Solar Inertial
                           ]
    
    ; coordinate systems valid for the FGM load routines
    ; no long valid for SCM (removed due to SSL coordinates - not in the CDFs)
    fgm_scm_load_list = ['dsl', 'gsm', 'ssl', 'gse']

    ; coordinate systems valid for FIT/ESA/SCM instruments
    ; As of 4/2014, this should be used for the SCM instrument - egrimes
    fit_esa_load_list = ['dsl',  'gse', 'gsm']
    
    ; coordinate systems that require position data for transformations
    pos_data_req = ['sel', 'sse']
    
    ; coordinate systems that require spacecraft attitude data for transformations
    att_data_req = ['sel']

    ; update the pointers to the lists
    ; no need to append att_data_req because 'SEL' already exists in pos_data_req
    self.coordinate_systems = ptr_new([themis_coord_sys_list, geomag_coord_sys_list, pos_data_req])
    self.fgm_scm_load_list = ptr_new(fgm_scm_load_list)
    self.fit_esa_load_list = ptr_new(fit_esa_load_list)
    self.misc_coord_sys_list = ptr_new(misc_coord_sys_list)
    self.themis_coord_sys_list = ptr_new(themis_coord_sys_list)
    self.geomag_coord_sys_list = ptr_new([geomag_coord_sys_list, pos_data_req])
    self.themis_pos_data_req_list = ptr_new(pos_data_req)
    return, 1
end

; this method creates and returns a list of valid coordinate systems
function thm_ui_coordinate_systems::makeCoordSysList, include_all = include_all, include_none = include_none, $
         include_misc = include_misc, uppercase = uppercase, instrument = instrument
    if ~undefined(instrument) then begin
        instrument = strlowcase(instrument)
        ; check for THEMIS FGM/SCM data
        if instrument eq 'fgm'  then begin
            ret_coords = *self.fgm_scm_load_list
        ; check for THEMIS ESA/FIT data
        endif else if instrument eq 'fit' || instrument eq 'esa' || instrument eq 'scm' || instrument eq 'efi' then begin
            ret_coords = *self.fit_esa_load_list
        endif else begin
            ret_coords = *self.coordinate_systems
        endelse
    endif else begin
        ret_coords = *self.coordinate_systems
    endelse
    
    ret_coords = (~undefined(include_none) ? ['n/a', ret_coords] : ret_coords)
    ret_coords = (~undefined(include_misc) ? [ret_coords, *self.misc_coord_sys_list] : ret_coords)
    ret_coords = (~undefined(include_all) ? [ret_coords, 'all'] : ret_coords)
    ret_coords = (~undefined(uppercase) ? strupcase(ret_coords) : ret_coords)
    return, ret_coords
end

; this method creates and returns coordinate system lists for checking 
; if the spinras & spindec vars are required for transformations
; see spd_ui_req_spin
function thm_ui_coordinate_systems::makeCoordSysListForSpinModel, include_dsl = include_dsl
    if ~undefined(include_dsl) then begin
        ret_coords = ['dsl', *self.geomag_coord_sys_list]
    endif else begin
        ret_coords = *self.geomag_coord_sys_list
    endelse
    return, ret_coords

end

; this method returns THEMIS coordinate systems, with/without 'dsl'. 
; see spd_ui_req_spin
function thm_ui_coordinate_systems::makeCoordSysListForTHEMIS, include_dsl = include_dsl
    if ~undefined(include_dsl) then begin
        ret_coords = *self.themis_coord_sys_list
    endif else begin
        ; assumes the first element in the array is 'dsl'
        ret_coords = (*self.themis_coord_sys_list)[1:n_elements((*self.themis_coord_sys_list))-1]
    endelse
    return, ret_coords
end

; this method returns THEMIS coordinate systems that require position data
; see spd_ui_req_slp
function thm_ui_coordinate_systems::makeCoordSysListForTHEMISReqPos
    return, *self.themis_pos_data_req_list
end

pro thm_ui_coordinate_systems__define

    compile_opt idl2, hidden

    state = {THM_UI_COORDINATE_SYSTEMS, $
            coordinate_systems: ptr_new(0), $
            themis_coord_sys_list: ptr_new(0), $
            geomag_coord_sys_list: ptr_new(0), $
            fgm_scm_load_list: ptr_new(0), $
            fit_esa_load_list: ptr_new(0), $
            themis_pos_data_req_list: ptr_new(0), $
            misc_coord_sys_list: ptr_new(0) $
            }
end