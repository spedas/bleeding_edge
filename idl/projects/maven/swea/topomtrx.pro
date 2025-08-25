;+
;PROCEDURE:   topomtrx
;
;PURPOSE: This routine provides topology matrix or a table of topology 
;         for 6 given dimensions, defined by shape parameters, voids,
;         and PAD info, which are:
;                  0 - upward shape: 0: phe, 1: swe, 2:nan
;                  1 - downward shape: 0: phe, 1: swe, 2:nan
;                  2 - void: 0: yes, 1: no, 2:nan 
;                  3 - upward PAD: 0: not loss cone, 1: loss cone, 2:nan 
;                  4 - downward PAD: 0: not loss cone, 1: loss cone, 2:nan 
;                  5 - day/night: currently not used
;         8 topology results are provided:
;                  0 Unknown
;                  1 Dayside Closed
;                  2 Day-Night Closed
;                  3 Night Closed -- Trapped/two-sided loss cone
;                  4 Night CLosed -- Void
;                  5 Day Open
;                  6 Night Open
;                  7 Draped
;
;USAGE:
;  result = topomtrx()
;
;INPUTS:
;       None
;
;KEYWORDS:
;       None
;                      
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
; $LastChangedRevision: 33563 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/topomtrx.pro $
;
;CREATED BY:    Shaosui Xu, 11/03/2017
;FILE: topomtrx.pro
;-

Function topomtrx;, tbl=tbl
    ;if (size(tbl,/type) eq 0) then $
    tbl=[0,1,2,3,4,5,6,7]
    mtrx = fltarr(3,3,3,3,3,4) ;total 81*3=243, ignoring last dimension
    ; mtrx has 6 dimensions
    ; 0 - upward shape: 0: phe, 1: swe, 2:nan
    ; 1 - downward shape: 0: phe, 1: swe, 2:nan
    ; 2 - void: 0: yes, 1: no, 2:nan 
    ; 3 - upward PAD: 0: not loss cone, 1: loss cone, 2:nan 
    ; 4 - downward PAD: 0: not loss cone, 1: loss cone, 2:nan 
    ; 5 - flux ratio 100-300 eV of away/toward: 0: <0.75, loss cone, 1: not loss cone
    ;                                2: nan
    ;;;; "5 - day/night: currently not used" replaced

    ;1 Dayside Closed
    ;2 Day-Night Closed
    ;3 Night Closed -- Trapped
    ;4 Night CLosed -- Void
    ;5 Day Open
    ;6 Night Open
    ;7 Draped
    ;
    ;fill out NANs first
    ;so that it will be rewrite by other known topo
    mtrx[2,*,*,*,*,*] = tbl[0] ;81
    mtrx[0:1,2,*,*,*,*] = tbl[0] ;54
    mtrx[0:1,0:1,2,*,*,*] = tbl[0] ;36
    mtrx[0:1,0:1,0:1,2,*,*] = tbl[0] ;24
    mtrx[0:1,0:1,0:1,0:1,2,*] = tbl[0] ;16

    ;day-night closed loops
    ;1. dn phe + up sw/backscatter + up lc
    mtrx[1,0,1,1,0,*]=tbl[2] ;1
    ;2. up phe + dn sw/backscatter + dn lc
    mtrx[0,1,1,0,1,*]=tbl[2] ;1

    ;two rare situations
    ;2. dn phe + up sw e + dn lc
    ;be classifed as open to day
    mtrx[1,0,1,0,1,*]=tbl[5] ;1
    mtrx[1,0,1,2,1,*]=tbl[5]
    ;3. dn phe + up sw e + isotripic
    ;be classifed as day-to-night closed, thought to be lc=90
    ;add another scenario: open-to-day,where high
    ;energy is isotropic when phe and sw e- fluxes
    ; are comparable
    mtrx[1,0,1,0,0,1:2]=tbl[5] ;no loss cone  
    mtrx[1,0,1,0,0,0]=tbl[2] ;flx ratio <1, lc=90
    ;mtrx[1,0,1,0,0,*]=tbl[5]

    ;open to day
    ;up phe + dn swe + 1-sided lc up
    mtrx[0,1,1,1,0,*]=tbl[5] ;1
    ;up phe + dn swe + isotrpic
    mtrx[0,1,1,0,0,*]=tbl[5] ;1

    ;open to night
    ;up swe + dn swe + 1-sided lc up
    mtrx[1,1,1,1,0,*]=tbl[6] ;1

    ;draped
    ;up swe + dn swe + 1-sided lc dn
    mtrx[1,1,1,0,1,*]=tbl[7] ;1
    ;up swe + dn swe + isotropic
    mtrx[1,1,1,0,0,*]=tbl[7] ;1

    ;closed loops on nightside
    ;1. double-sided loss cone
    mtrx[*,*,1,1,1,*]=tbl[3] ;9/4

    ;;now we need to consider if pad 
    ;;unavailable but shape is
    ;;open to day, up phe + dn swe-
    ;mtrx[0,1,1,2,0,*]=tbl[5];only one-side PAD score available
    ;mtrx[0,1,1,*,2,*]=tbl[5]
    ;; ;up swe- + dn swe-
    ;; ;flux ratio > thrd(0.75): draped
    ;; mtrx[1,1,1,2,2,1]=tbl[7]
    ;; ;flux ratio < thrd(0.75): open to night
    ;; mtrx[1,1,1,2,2,0]=tbl[6]
    ;; ;up swe- + dn phe + flux ratio < thrd(0.75); x-term closed
    ;; mtrx[1,0,1,2,2,0]=tbl[2]

    ;phe in both direction, dayside closed loops
    mtrx[0,0,1,*,*,*]=tbl[1] ;9/4-1
    ;mtrx[0,0,1,0,1,*]=tbl[2]
    ;mtrx[0,0,1,1,0,*]=tbl[2]
    mtrx[0,0,1,*,*,2]=tbl[2] ;x-term if upward-beamed
    mtrx[0,0,1,*,*,0]=tbl[2]
    ;closed loops on nightside
    ;2. e- void
    mtrx[*,*,0,*,*,*]=tbl[4] ;81/16

    return, mtrx
end
