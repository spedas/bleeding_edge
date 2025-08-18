; FAST crib for loading and plotting FAST esa data using level 2 CDFs
; and creating density, velocity and temperature.
; Just copy this file and paste it into IDL for a quick demo of FAST
; software
; or run the file using the .run command
; For loading EES, IES, EEB, IEB, use		fa_load_esa_l2.pro
;***********************************************************************************************************
; select an orbit number or orbit range or time range

fa_orbitrange,2371 ;fa_orbitrange gnerates a time range for the given orbital range

;fa_orbitrange,1801
;fa_orbitrange,2301
;fa_orbitrange,2001
;fa_orbitrange,[1801,1802]
;fa_orbitrange,[1801,1804]

; A time range may also be used, using the timerange, and timespan commands
;trange=timerange(['97-02-21/3:00','97-02-21/7:00']) & dt=trange[1]-trange[0] & timespan,trange[0],dt,/seconds
;***********************************************************************************************************
; I find the following helpful, but not necessary
!y.margin=[4,4]		; default is [4,2]
!x.margin=[10,5]	; default is [10,3]

;***********************************************************************************************************
; initialize software

;fa_init sets up the !fast env variable, which sets up the local
;environment for downloading, and saving data. Note that all of
;the data needed should be downloaded automatically.

fa_init 
;IDL> help, !fast
;** Structure RETRIEVE_STRUCT, 23 tags, length=136, data length=120:
;   INIT            INT              1
;   LOCAL_DATA_DIR  STRING    'c:/data/\fast/'
;   REMOTE_DATA_DIR STRING    'http://themis.ssl.berkeley.edu/data/fast/'
;   PROGRESS        INT              1
;   USER_AGENT      STRING    ''
;   FILE_MODE       INT            438
;   DIR_MODE        INT            511
;   PRESERVE_MTIME  INT              1
;   PROGOBJ         OBJREF    <NullObject>
;   MIN_AGE_LIMIT   LONG               300
;   NO_SERVER       INT              0
;   NO_DOWNLOAD     INT              0
;   NO_UPDATE       INT              0
;   NO_CLOBBER      INT              0
;   ARCHIVE_EXT     STRING    ''
;   ARCHIVE_DIR     STRING    ''
;   IGNORE_FILESIZE INT              0
;   IGNORE_FILEDATE INT              0
;   DOWNLOADONLY    INT              0
;   USE_WGET        INT              0
;   NOWAIT          INT              0
;   VERBOSE         INT              2
;   FORCE_DOWNLOAD  INT              0

;load color table 43, a specialized color table for FAST, loadct2 is s
;procedure that sets special values for colors 0 through 6 and 255, for ease
;in plotting
loadct2,43
cols=get_colors()               ;
;IDL> help, cols
;** Structure <182c5d90>, 8 tags, length=8, data length=8, refs=1:
;   BLACK           BYTE         0
;   MAGENTA         BYTE         1
;   BLUE            BYTE         2
;   CYAN            BYTE         3
;   GREEN           BYTE         4
;   YELLOW          BYTE         5
;   RED             BYTE         6
;   WHITE           BYTE       255

;***********************************************************************************************************
; initialize the time range and orbit numbers if not already set
; this was done above, but can be done again
trange=timerange()
print,time_string(trange)
orbits=fa_time_to_orbit(trange)
print,'ORBITS: ', orbits
if orbits[0] eq orbits[1] then orbit = string(orbits[0]) else orbit=string(orbits[0])+'-'+string(orbits[1])

; Load orbit data, includes tplot variables for spacecraft position
; 'r' (GEI coordinates, km), velocity 'v' (GEI, km/s), altitude,
; 'alt'(km), magnetic local time, 'mlt'(hours), footprint latitude and
; longitude, 'flat','flong' (degrees), RA and DEC of spin axis
; 'fa_spin_ra', 'fa_spin_dec' (GEI coordinates, degrees), and
; invariant latitude (degrees)

fa_k0_load,'orb'

;***********************************************************************************************************
; load eesa and iesa survey data, downloads automatically, creates
; tplot variables for energy flux, 'fa_ees_l2_en_quick' and
; 'fa_ies_l2_en_quick'. The full 2d data structures are loaded into
; common blocks, that are accessed by the other programs. See
; fa_esa_cmn_l2gen.pro for an example of the FAST L2 2d data structure.

fa_esa_load_l2,datatype=['ees','ies'],/tplot

; helpful options for plotting
gap_time=5.
options,'fa_ees_l2_en_quick',datagap=gap_time
options,'fa_ies_l2_en_quick',datagap=gap_time

; plot the eflux data using the tplot command
tplot,['fa_ees_l2_en_quick','fa_ies_l2_en_quick'],$
      title='FAST Orbit= '+orbit,$ ;the title keyword puts a title at the top
      var_label=['alt','ilat','mlt'] ;the var_label keyword shows values of these variables at the bottom of the plot

wait,5                          ;wait a bit
;*************************************************************************************
; Generate some line plots of electron and ion density
; The program get_2dt is a wrapper of other IDL programs that create
; the moments for individual time intervals, here we use it to call
; the program n_2d_new, which calculates the density. The input name1
; is the name of the output tplot variable for electron
; survey density, and the input get_dat tells the get_2dt program to
; access the data using the helper routine get_fa2_ees.pro. The
; gap_time keyword is the minimum size of data gaps. The energy
; keyword sets the energy range.
name1='Ne_s'
get_dat='fa2_ees'
get_2dt,'n_2d_new',get_dat,name=name1,gap_time=gap_time,energy=[25.,33000.]
name1='Ne_s'
ylim,name1,1.e-2,1.e4,1 ;ylimits sets the limits for the density plots to [.01, 1.0e4], and logarithmic scaling

; The options program sets up plotting options for the tplot variable name1
options,name1,'ytitle','Ne (cm!U-3!N)' ;ytitle

;Ok, let's do the ion density
name1='Ni_s'
get_dat='fa2_ies'
get_2dt,'n_2d_new',get_dat,name=name1,gap_time=gap_time,energy=[25.,33000.]
name1='Ni_s'
ylim,name1,1.e-2,1.e4,1
options,name1,'ytitle','Ni (cm!U-3!N)'

tplot,['Ne_s','Ni_s']

wait,5
;*************************************************************************************
; generate some line plots of electron and ion velocity, using the
; 'v_2d_new' program

name1='Ve_s'
get_dat='fa2_ees'
get_2dt,'v_2d_new',get_dat,name=name1,gap_time=gap_time,energy=[25.,33000.]
name1='Ve_s'
options,name1,'ytitle','Ve (km/s)'

name1='Vi_s'
get_dat='fa2_ies'
get_2dt,'v_2d_new',get_dat,name=name1,gap_time=gap_time,energy=[25.,33000.]
name1='Vi_s'
options,name1,'ytitle','Vi (km/s)'

;Note that the velocity has three components, but only one is
;non-zero, so maybe that is a total velocity?
tplot,['Ve_s','Vi_s']

wait,5
;*************************************************************************************
; generate some line plots of electron and ion temperature, using the
; program 't_2d_new'. Note that output has 4 dimensions, for
; x,y,z,average (x,y,z are in GEI coordinates)

name1='Te_s'
get_dat='fa2_ees'
get_2dt,'t_2d_new',get_dat,name=name1,gap_time=gap_time,energy=[25.,33000.]
name1='Te_s'
	options,name1,'ytitle','Te (km/s)'

name1='Ti_s'
get_dat='fa2_ies'
get_2dt,'t_2d_new',get_dat,name=name1,gap_time=gap_time,energy=[25.,33000.]
name1='Ti_s'
	options,name1,'ytitle','Ti (km/s)'

tplot,['Te_s','Ti_s']

wait,5

;*************************************************************************************
;Here is a list of all of the *_2d_new functions (note that the base
;SW directory may be different; here it is 'C:\SPEDAS')
;
;C:\SPEDAS\general\missions\fast\fa_esa\functions\ec_2d_new.pro --
;characteristic energy

;C:\SPEDAS\general\missions\fast\fa_esa\functions\j_2d_new.pro --
;field-aligned flux

;C:\SPEDAS\general\missions\fast\fa_esa\functions\je_2d_new.pro --
;field-aligned energy flux

;C:\SPEDAS\general\missions\fast\fa_esa\functions\jo_2d_new.pro --
;omni-directional flux

;C:\SPEDAS\general\missions\fast\fa_esa\functions\n_2d_new.pro --
;density

;C:\SPEDAS\general\missions\fast\fa_esa\functions\p_2d_new.pro --
;pressure tensor

;C:\SPEDAS\general\missions\fast\fa_esa\functions\t_2d_new.pro --
;temperature

;C:\SPEDAS\general\missions\fast\fa_esa\functions\v_2d_new.pro --
;velocity

;*************************************************************************************
; Other useful functions to understand
;tlimit
;ctime
;get_data
;store_data
;makepng
;plot_fa_crossing,orbit=1800
;
;See the programs in
; C:\SPEDAS\general\examples
;for examples
; e.g. .run crib_tplot.pro

End
