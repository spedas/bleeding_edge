;+ 
; NAME: 
;     spd_ui_coordinate_systems
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
;
;
; EXAMPLES:
;     To make a simple list of general purpose coordinate systems:
;        SPEDAS> coordSysObj = obj_new('spd_ui_coordinate_systems') ; create the object
;        SPEDAS> print, coordSysObj->makeCoordSysList(/uppercase) ; make the list
;           GSM AGSM GSE GEI SM GEO MAG
;        SPEDAS> print, coordSysObj->makeCoordSysList(/uppercase, /include_none) ; include N/A 
;           N/A GSM AGSM GSE GEI SM GEO MAG
;        SPEDAS> print, coordSysObj->makeCoordSysList(/include_misc) ; include miscellaneous coordinates
;           gsm agsm gse gei sm geo mag enp rtn hdz gci dsl ssl spg sse sel
;        SPEDAS> obj_destroy, coordSysObj ; delete the object
;
;
; NOTE: 
;      All coordinate system lists exist in this object's constructor, with pointers
;        to the lists in the objects state structure
;        
;      Changes to this object should be reflected in the corresponding test procedure, spd_ui_test_coordinate_systems_obj
;
;      This routine was forked from the THEMIS coord object (thm_ui_coordinate_systems)
;
;
;$LastChangedBy: crussell $
;$LastChangedDate: 2015-09-23 08:48:08 -0700 (Wed, 23 Sep 2015) $
;$LastChangedRevision: 18883 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_coordinate_systems__define.pro $
;-


; destructor
pro spd_ui_coordinate_systems::Cleanup
    ptr_free, self.coordinate_systems
    ptr_free, self.misc_coord_sys_list
end


; constructor
function spd_ui_coordinate_systems::init

    ; standard Earth-centered coordinate systems
    geomag_coord_sys_list = ['gsm', $ ; Geocentric Solar Magnetospheric
                             'agsm', $ ; aberrated GSM
                             'gse', $ ; Geocentric Solar Ecliptic
                             'gei', $ ; Geocentric Equatorial Inertial
                             'sm', $ ; Solar Magnetic
                             'geo', $ ; Geographic
                             'mag', $ ; Magnetic
                             'j2000' $ ; J2000 (mean of date)                             
                             ]
    
    ; additional coordinate systems
    misc_coord_sys_list = ['enp', $ ; GOES magnetometer centered
                           'rtn', $ ; STEREO (Radial Tangential Normal)
                           'hdz', $ ; ground mag coordinate system
                           'gci', $ ; Geocentric Solar Inertial
                           'dsl', $ ; THEMIS Despun Sun L-vectorZ
                           'ssl', $ ; THEMIS Spinning SunSensor-L-vectorZ
                           'spg', $ ; THEMIS Spinning Probe Geometric
                           'sse', $ ; Selenocentric Solar Ecliptic
                           'sel' $  ; Body-fixed Selenographic
                           ]

    ; update the pointers to the lists
    ; elements of these lists need not be exclusive
    self.coordinate_systems = ptr_new(geomag_coord_sys_list, /no_copy)
    self.misc_coord_sys_list = ptr_new(misc_coord_sys_list, /no_copy)

    return, 1
end


; this method creates and returns a list of valid coordinate systems
function spd_ui_coordinate_systems::makeCoordSysList, $
                                    include_all = include_all, $
                                    include_none = include_none, $
                                    include_misc = include_misc, $
                                    uppercase = uppercase

    ret_coords = *self.coordinate_systems
   
    ret_coords = (~undefined(include_none) ? ['n/a', ret_coords] : ret_coords)
    ret_coords = (~undefined(include_misc) ? [ret_coords, *self.misc_coord_sys_list] : ret_coords)
    ret_coords = (~undefined(include_all) ? [ret_coords, 'all'] : ret_coords)
    ret_coords = (~undefined(uppercase) ? strupcase(ret_coords) : ret_coords)

    return, ret_coords
end


; definition
pro spd_ui_coordinate_systems__define

    compile_opt idl2, hidden

    state = {SPD_UI_COORDINATE_SYSTEMS, $
            coordinate_systems: ptr_new(), $
            misc_coord_sys_list: ptr_new() $
            }
end