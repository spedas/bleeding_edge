KPL/FK

Mars Atmosphere and Volatile EvolutioN (MAVEN) Frames Kernel
===============================================================================

   This frame kernel contains complete set of frame definitions for the
   MAVEN spacecraft, its structures and science instruments. This frame
   kernel also contains name - to - NAIF ID mappings for MAVEN science
   instruments and s/c structures (see the last section of the file.)


Version and Date
-------------------------------------------------------------------------------

   Version 0.4 -- February 27, 2014 -- Boris Semenov, NAIF
                                       Davin Larson, SEP Team/SSL-UCB

      Deleted MAVEN_IUVS_OCC_BIG and MAVEN_IUVS_OCC_SMALL frames. Added
      MAVEN_IUVS_MAIN_SLIT/-202519 name/ID mapping. 

      Redefined MAVEN_SWIA frame to have the +X axis along the s/c +Z
      axis (nominally towards the Sun.) Added name/ID mappings for 
      MAVEN_SWIA_FRONT/-202143 and MAVEN_SWIA_BACK/-202144.

      Redefined MAVEN_SWEA frame to have the +X axis between anodes 0
      and 15 (consistent with the SWEA flight and ground data analysis
      software). Added name/ID mappings for MAVEN_SWEA_FRONT/-202131 and
      MAVEN_SWEA_BACK/-202132.

      Renamed SEP detectors and frames (SEP_PY -> SEP1, SEP_MY -> SEP2).

      Added MAVEN_SSO/-202912 frames.

      Added lower-priority MAG sensor names (MAVEN_MAG1/-202310 and 
      MAVEN_MAG2/-202410) consistent with the updated SEP names.

      Deleted MAVEN_NGIMS_BASE/-202535 frame and re-defined
      MAVEN_NGIMS/-202530 frame to be relative to and nominally
      co-aligned with the APP frame.

      Fixed some typos.

   Version 0.3 -- October 3, 2012 -- Boris Semenov, NAIF

      Added instrument and structure frames and name-ID mappings.
      Added MSO frame.

   Version 0.2 -- August 26, 2012 -- Boris Semenov, NAIF

      Corrected UHF orientation. Added LGAs. Added diagrams.

   Version 0.1 -- November 17, 2010 -- Boris Semenov, NAIF

      Changed frame IDs to be based on the official flight ID -202.
      Added MAVEN_MME_2000 frame. Added comments.

   Version 0.0 -- May 22, 2009 -- Boris Semenov, NAIF

      Initial Release with spacecraft, HGA and UHF frames based on
      temporary spacecraft ID -33.


References
-------------------------------------------------------------------------------

   1. ``Frames Required Reading''

   2. ``Kernel Pool Required Reading''

   3. ``C-Kernel Required Reading''

   4. E-mail from Gina Signori, LMCO re. s/c, HGA and UHF frames; 05/22/09

   5. MAVEN Coordinate Systems Definition Document, MAV-RP-10-010,
      Revision: D (SIR), May 18, 2012

   6. MAVEN instrument MICDs, latest versions

   7. E-mail from Dr. Jasper Halekas, UC Berkeley, regarding SWIA frame
      definition used in the SWIA baseline level 2 products, 12/20/13.

   8. E-mail from David Mitchell, UC Berkeley, regarding SWEA frame
      definition used in the SWEA flight and ground software, 01/04/14.


Contact Information
-------------------------------------------------------------------------------

   Boris V. Semenov, NAIF/JPL, (818)-354-8136, Boris.Semenov@jpl.nasa.gov


Implementation Notes
-------------------------------------------------------------------------------

   This file is used by the SPICE system as follows: programs that make
   use of this frame kernel must ``load'' the kernel, normally during
   program initialization using the SPICELIB routine FURNSH. This file
   was created and may be updated with a text editor or word processor.


MAVEN Frames
-------------------------------------------------------------------------------

   The following MAVEN frames are defined in this kernel file:

           Name                  Relative to           Type       NAIF ID
      ======================  ===================  ============   =======

   Non Built-in Mars Frames:
   -------------------------
      MAVEN_MME_2000          rel.to J2000         FIXED          -202901

   Dynamic Frames:
   ---------------
      MAVEN_MSO               rel.to J2000         DYNAMIC        -202911
      MAVEN_SSO               rel.to J2000         DYNAMIC        -202912

   Spacecraft frame:
   -----------------
      MAVEN_SPACECRAFT        rel.to MME_2000      CK             -202000

   Antenna frames:
   ---------------
      MAVEN_HGA               rel.to SPACECRAFT    FIXED          -202010
      MAVEN_UHF               rel.to SPACECRAFT    FIXED          -202020
      MAVEN_LGA_FWD           rel.to SPACECRAFT    FIXED          -202030
      MAVEN_LGA_AFT           rel.to SPACECRAFT    FIXED          -202040

   Instrument frames:
   ------------------
      MAVEN_EUV               rel.to SPACECRAFT    FIXED          -202110

      MAVEN_SEP1              rel.to SPACECRAFT    FIXED          -202120
      MAVEN_SEP2              rel.to SPACECRAFT    FIXED          -202125

      MAVEN_SWEA              rel.to SPACECRAFT    FIXED          -202130

      MAVEN_SWIA_BASE         rel.to SPACECRAFT    FIXED          -202140
      MAVEN_SWIA              rel.to SWIA_BASE     FIXED          -202141

      MAVEN_LPW_PY            rel.to SPACECRAFT    FIXED          -202151
      MAVEN_LPW_MY            rel.to SPACECRAFT    FIXED          -202153

   APP and APP-mounted Instrument frames:
   -------------------------------------

      MAVEN_APP_BP            rel.to SPACECRAFT    FIXED          -202501
      MAVEN_APP_IG            rel.to APP_BP        CK             -202503
      MAVEN_APP_OG            rel.to APP_IG        CK             -202505
      MAVEN_APP               rel.to APP_OG        FIXED          -202507

      MAVEN_IUVS_BASE         rel.to APP           FIXED          -202510
      MAVEN_IUVS_LIMB         rel.to IUVS_BASE     FIXED          -202511
      MAVEN_IUVS_LIMB_BOS     rel.to IUVS_BASE     FIXED          -202512
      MAVEN_IUVS_NADIR        rel.to IUVS_BASE     FIXED          -202513
      MAVEN_IUVS_NADIR_BOS    rel.to IUVS_BASE     FIXED          -202514
      MAVEN_IUVS_SCAN         rel.to IUVS_BASE     CK             -202517
      MAVEN_IUVS              rel.to IUVS_SCAN     FIXED          -202518

      MAVEN_STATIC            rel.to APP           FIXED          -202520

      MAVEN_NGIMS             rel.to APP           FIXED          -202530

   Solar Array (SA) and SA-mounted Instrument frames:
   --------------------------------------------------

      MAVEN_SA_PY_IB          rel.to SPACECRAFT    FIXED          -202300
      MAVEN_SA_PY_OB          rel.to SA_PY_IB      FIXED          -202305

      MAVEN_MAG_PY            rel.to SA_PY_OB      FIXED          -202310

      MAVEN_SA_MY_IB          rel.to SPACECRAFT    FIXED          -202400
      MAVEN_SA_MY_OB          rel.to SA_MY_IB      FIXED          -202405

      MAVEN_MAG_MY            rel.to SA_MY_OB      FIXED          -202410

   Structure frames:
   -----------------
      TBD.


MAVEN Frames Hierarchy
-------------------------------------------------------------------------------

   The diagram below shows MAVEN frames hierarchy:


                               "J2000" INERTIAL
       +--------------------------------------------------------------+
       |               |               |               |              |
       |<-pck          |<-dyn          |<-fxd          |<-dyn         |<-pck
       V               |               |               |              V
    "IAU_MARS"         V               V               V        "IAU_EARTH"
    MARS BFR(*)    "MAVEN_MSO"   "MAVEN_MME_2000"  "MAVEN_SSO"   EARTH BFR(*)
    -----------    -----------   ----------------  -----------  ------------
                                       |
                                       |
                                       |
     "MAVEN_LGA_FWD"  "MAVEN_LGA_AFT"  |         "MAVEN_HGA"     "MAVEN_UHF"
     ---------------  ---------------  |         -----------     -----------
       ^               ^               |               ^               ^
       |<-fxd          |<-fxd          |<-ck           |<-fxd          |<-fxd
       |               |               |               |               |
       |  "MAVEN_EUV"  |               |               | "MAVEN_SWEA"  |
       |  -----------  |               |               | ------------  |
       |       ^       |               |               |       ^       |
       |       |<-fxd  |               |               |       |<-fxd  |
       |       |       |               |               |       |       |
       |       |       |      "MAVEN_SPACECRAFT"       |       |       |
       +---------------------------------------------------------------+
       |   |   |       |               |                       |   |   |
       |   |   |       |<-fxd          |                       |   |   |
       |   |   |       V               |                       |   |   |
       |   |   |  "MAVEN_SWIA_BASE"    |                       |   |   |
       |   |   |  -----------------    |                       |   |   |
       |   |   |       |               |                       |   |   |
       |   |   |       |<-fxd          |                       |   |   |
       |   |   |       V               |                       |   |   |
       |   |   |  "MAVEN_SWIA"         |                       |   |   |
       |   |   |  ------------         |                       |   |   |
       |   |   |                       |                       |   |   |
       |   |   |<-fxd                  |                  fxd->|   |   |
       |   |   V                       |                       V   |   |
       |   | "MAVEN_SEP1"              |              "MAVEN_SEP2" |   |
       |   | ------------              |              ------------ |   |
       |   |                           |                           |   |
       |   |<-fxd                      |<-fxd                 fxd->|   |
       |   V                           V                           V   |
       | "MAVEN_LPW_PY"         "MAVEN_APP_BP"          "MAVEN_LPW_MY" |
       | --------------         --------------          -------------- |
       |                               |                               |
       |<-fxd                          |<-ck                      fxd->|
       V                               V                               V
    "MAVEN_SA_PY_IB"            "MAVEN_APP_IG"             "MAVEN_SA_MY_IB" 
    ----------------            --------------             ----------------
       |                               |                               |
       |<-fxd                          |<-ck                      fxd->|
       V                               V                               V
    "MAVEN_SA_PY_OB"            "MAVEN_APP_OG"             "MAVEN_SA_MY_OB" 
    ----------------            --------------             ----------------
       |                               |                               |
       |<-fxd                          |<-fxd                     fxd->|
       V                               V                               V
    "MAVEN_MAG_PY"               "MAVEN_APP"                 "MAVEN_MAG_MY" 
    --------------     +-------------------------------+     --------------
                       |               |               |
                       |<-fxd          |               |<-fxd
                       V               |               V
                 "MAVEN_NGIMS"         |        "MAVEN_STATIC"
                 -------------         |        -------------- 
                                       |
                                       |<-fxd
                                       V
                               "MAVEN_IUVS_BASE"
       +---------------------------------------------------------------+
       |               |               |               |               |
       |               |<-fxd          |<-ck           |<-fxd          |
       |               V               V               V               |
       |  "MAVEN_IUVS_LIMB"    "MAVEN_IUVS_SCAN"   "MAVEN_IUVS_NADIR"  |
       |  -----------------    -----------------   ------------------  |
       |                               |                               |
       |<-fxd                          |<-fxd                          |<-fxd
       V                               V                               V 
    "MAVEN_IUVS_LIMB_BOS"         "MAVEN_IUVS"        "MAVEN_IUVS_NADIR_BOS"
    ---------------------         ------------        ----------------------


   (*) BFR -- body-fixed rotating frame


MME ``2000'' Frame
-------------------------------------------------------------------------------

   The MAVEN_MME_2000 frame is the Mars Mean Equator and IAU Vector of
   J2000 inertial reference frame defined using Mars rotation constants
   from the IAU 2000 report. This frame defined as a fixed offset frame
   with respect to the J2000 frame.

   \begindata

      FRAME_MAVEN_MME_2000         = -202901
      FRAME_-202901_NAME           = 'MAVEN_MME_2000'
      FRAME_-202901_CLASS          = 4
      FRAME_-202901_CLASS_ID       = -202901
      FRAME_-202901_CENTER         = 499
      TKFRAME_-202901_SPEC         = 'MATRIX'
      TKFRAME_-202901_RELATIVE     = 'J2000'
      TKFRAME_-202901_MATRIX       = (

         0.6732521982472339       0.7394129276360180       0.0000000000000000
        -0.5896387605430040       0.5368794307891331       0.6033958972853946
         0.4461587269353556      -0.4062376142607541       0.7974417791532832

                                     )

   \begintext


MAVEN Dynamic Frames
-------------------------------------------------------------------------------

   This section defined dynamic frames of interest to MAVEN science
   investigations.


MAVEN MSO Frame

   The MAVEN_MSO frame is the Mars-Sun-Orbit reference frame. It is
   defined in the same way that the GSE system is defined for Earth.
   The X-axis points from the center of Mars to the center of the Sun.
   The Y-axis points opposite to the direction of the orbital velocity
   component orthogonal to X. The Z-axis completes the right-handed
   system (Z = X x Y). The orientation of this frame is not dependent
   on the position or velocity of the MAVEN spacecraft.

   \begindata

      FRAME_MAVEN_MSO              =  -202911
      FRAME_-202911_NAME           = 'MAVEN_MSO'
      FRAME_-202911_CLASS          =  5
      FRAME_-202911_CLASS_ID       =  -202911
      FRAME_-202911_CENTER         =  499
      FRAME_-202911_RELATIVE       = 'J2000'
      FRAME_-202911_DEF_STYLE      = 'PARAMETERIZED'
      FRAME_-202911_FAMILY         = 'TWO-VECTOR'
      FRAME_-202911_PRI_AXIS       = 'X'
      FRAME_-202911_PRI_VECTOR_DEF = 'OBSERVER_TARGET_POSITION'
      FRAME_-202911_PRI_OBSERVER   = 'MARS'
      FRAME_-202911_PRI_TARGET     = 'SUN'
      FRAME_-202911_PRI_ABCORR     = 'NONE'
      FRAME_-202911_SEC_AXIS       = 'Y'
      FRAME_-202911_SEC_VECTOR_DEF = 'OBSERVER_TARGET_VELOCITY'
      FRAME_-202911_SEC_OBSERVER   = 'MARS'
      FRAME_-202911_SEC_TARGET     = 'SUN'
      FRAME_-202911_SEC_ABCORR     = 'NONE'
      FRAME_-202911_SEC_FRAME      = 'J2000'

   \begintext


MAVEN SSO Frame

   The MAVEN_SSO frame is the MAVEN Spacecraft-Sun-Orbit reference
   frame. It is defined in the same way that the GSE system is defined
   for Earth. The X-axis points from the MAVEN spacecraft to the center
   of the Sun. The Y-axis points opposite to the direction of the
   orbital velocity (relative to the Sun) component orthogonal to X.
   The Z-axis completes the right-handed system (Z = X x Y). The 
   orientation of this frame is dependent on the position and 
   velocity of the MAVEN spacecraft.

   This frame is used during the cruise phase.

   \begindata

      FRAME_MAVEN_SSO              =  -202912
      FRAME_-202912_NAME           = 'MAVEN_SSO'
      FRAME_-202912_CLASS          =  5
      FRAME_-202912_CLASS_ID       =  -202912
      FRAME_-202912_CENTER         =  -202
      FRAME_-202912_RELATIVE       = 'J2000'
      FRAME_-202912_DEF_STYLE      = 'PARAMETERIZED'
      FRAME_-202912_FAMILY         = 'TWO-VECTOR'
      FRAME_-202912_PRI_AXIS       = 'X'
      FRAME_-202912_PRI_VECTOR_DEF = 'OBSERVER_TARGET_POSITION'
      FRAME_-202912_PRI_OBSERVER   = 'MAVEN'
      FRAME_-202912_PRI_TARGET     = 'SUN'
      FRAME_-202912_PRI_ABCORR     = 'NONE'
      FRAME_-202912_SEC_AXIS       = 'Y'
      FRAME_-202912_SEC_VECTOR_DEF = 'OBSERVER_TARGET_VELOCITY'
      FRAME_-202912_SEC_OBSERVER   = 'MAVEN'
      FRAME_-202912_SEC_TARGET     = 'SUN'
      FRAME_-202912_SEC_ABCORR     = 'NONE'
      FRAME_-202912_SEC_FRAME      = 'J2000'

   \begintext


Spacecraft Bus Frame
-------------------------------------------------------------------------------
 
   The spacecraft frame is defined by the s/c design as follows [from 5]:

      -  Z axis is perpendicular to the Launch Vehicle separation
         plane. The positive z direction is from the separation plane
         toward/through the High Gain Antenna.
 
      -  X axis is is in the Launch Vehicle separation plane extending
         from the origin through the scribe line on the outside
         diameter of the Launch Vehicle Ring (nominally toward the
         Articulating Payload Platform).

      -  Y axis completes the right handed frame;

      -  the origin of the frame is in the Launch Vehicle separation
         plane at the center point of the outside diameter of the
         Launch Vehicle Ring.

   These diagrams illustrate the s/c frame:

      +Z s/c side:
      ------------                 ._____. APP
                                   \_____|
                                      | 
                                      |
                                      |  +Xsc
                                      | ^ 
             ._________._________..-----|-----.._________._________.
             |         |         ||  .--|--.  ||         |         |>
       MAG .-|         |     +Ysc   /   |   \ ||         |         |-. MAG
          <  |         |        <-------o    |||         |         |  >
           `-|         |            \       / ||         |         |-'
            <|_________|_________|HGA'-----'  ||_________|_________|
                                  `-----------'
                                  .-'   |   `-.
                               .-'      |      `-.
                            .-'         @         `-.
                         .-'             SWEA        `-.
                  LPW .-'                               `-. LPW

                                                   +Zsc is out of the page.

      -X s/c side:
      ------------

          *.                            _                            .*
        MAG `o.                  HGA  .' `.                       .o' MAG
               `-.                  .'     `.                  .-'  
                  `-.               ---------               .-'
                     `-o_________..-----------.._________o-'
                                  |           |
                                  | +Zsc      |
                                  |     ^     |
                                  |     |     |
                                  |     |     |
                             +Ysc `-----|-----'
                                <-------x -'`-.
                               .-'      |      `-.
                            .-'         @         `-. 
                         .-'             SWEA        `-.
                  LPW .-'                               `-. LPW

                                                     +Xsc is into the page.

   Since the S/C bus attitude is provided by a C kernel (see [3] for
   more information), this frame is defined as a CK-based frame.

   \begindata

      FRAME_MAVEN_SPACECRAFT       = -202000
      FRAME_-202000_NAME            = 'MAVEN_SPACECRAFT'
      FRAME_-202000_CLASS           = 3
      FRAME_-202000_CLASS_ID        = -202000
      FRAME_-202000_CENTER          = -202
      CK_-202000_SCLK               = -202
      CK_-202000_SPK                = -202

   \begintext
 

Antenna Frames
-------------------------------------------------------------------------------

   The MAVEN HGA, UHF, and "forward" and "aft" LGA antenna frames --
   MAVEN_HGA, MAVEN_UHF, MAVEN_LGA_FWD, and MAVEN_LGA_AFT -- are
   defined as follows:

      -  +Z axis is along the antenna boresight

      -  +X axis is along the clock reference direction of the antenna
         pattern

      -  +Y axis completes the right-handed frame

      -  the origin of the frame is at the geometric center of the
         antenna's outer rim or patch


HGA Frame

   MAVEN HGA frame -- MAVEN_HGA, ID -202010 -- is defined as a fixed
   offset frame with respect to and nominally co-aligned with the
   spacecraft frame (see [5]) as shown on this diagram:

      -X s/c side:
      ------------
                                  +Zhga
                                        ^
          *.                            |                            .*
        MAG `o.                       .'|`. HGA                   .o' MAG
               `-.           +Yhga  .'  |  `.                  .-'  
                  `-.           <-------x ---              .-'
                     `-o_________..-----------.._________o-'
                                  |           |
                                  | +Zsc      |
                                  |     ^     |
                                  |     |     |
                                  |     |     |
                             +Ysc `-----|-----'
                                <-------x -'`-.
                               .-       |      `-.
                            .-'         @         `-.      
                         .-'             SWEA        `-.   
                  LPW .-'                               `-. LPW

                                            +Xsc, +Xhga are into the page.

   The keywords below define the HGA frame.

   \begindata

      FRAME_MAVEN_HGA              = -202010
      FRAME_-202010_NAME            = 'MAVEN_HGA'
      FRAME_-202010_CLASS           = 4
      FRAME_-202010_CLASS_ID        = -202010
      FRAME_-202010_CENTER          = -202
      TKFRAME_-202010_SPEC          = 'ANGLES'
      TKFRAME_-202010_RELATIVE      = 'MAVEN_SPACECRAFT'
      TKFRAME_-202010_ANGLES        = ( 0.0, 0.0, 0.0 )
      TKFRAME_-202010_AXES          = ( 1,   2,   3   )
      TKFRAME_-202010_UNITS         = 'DEGREES'

   \begintext


UHF Antenna Frame

   MAVEN UHF frame -- MAVEN_UHF, ID -202020 -- is defined as a fixed
   offset frame with respect to the spacecraft frame. The MAVEN_UHF
   frame is nominally rotated from the spacecraft frame by +130 degrees 
   about Y (see [6]) as shown on this diagram:

      -Y s/c side:
      ------------                 HGA  _
                                   .__.-*-.__.
                             Solar |    MAG  |
                             Array |         |            .___. 
                                  .-----------.===========|  .' APP
                                  |           |           `-'
                                  | +Zsc      |
                                  |     ^     |      
                                  |     |     |     
                                  |     |     | UHF
                                .-.-----|-----x           ---
                             .-'.'   `- x---.'-`> +Xsc    /
                          .-' .'          .'     `.      /
                       .-'   @           v         v    / 40 deg
                LPW .-'    SWEA    +Xuhf      +Zuhf  . /
                                                      `. 

                                           +Ysc, +Yuhf are into the page.

   The angle in the definition is -130 because the rotation in the
   definition is from the UHF frame to the spacecraft frame.

   \begindata

      FRAME_MAVEN_UHF               = -202020
      FRAME_-202020_NAME            = 'MAVEN_UHF'
      FRAME_-202020_CLASS           = 4
      FRAME_-202020_CLASS_ID        = -202020
      FRAME_-202020_CENTER          = -202
      TKFRAME_-202020_SPEC          = 'ANGLES'
      TKFRAME_-202020_RELATIVE      = 'MAVEN_SPACECRAFT'
      TKFRAME_-202020_ANGLES        = ( 0.0, -130.0, 0.0 )
      TKFRAME_-202020_AXES          = ( 1,      2,   3   )
      TKFRAME_-202020_UNITS         = 'DEGREES'

   \begintext


LGA Antenna Frames

   MAVEN LGA frames -- MAVEN_LGA_FWD, ID -202030, and MAVEN_LGA_AFT, ID
   -202040, -- are defined as fixed offset frames with respect to the
   spacecraft frame. The MAVEN_LGA_FWD frame is rotated from the
   spacecraft frame by -22 degrees about Y while the MAVEN_LGA_AFT
   frame is rotated from the spacecraft frame by +158 degrees about Y
   (see [5]) as shown on this diagram:

      -Y s/c side:        
      ------------             22 deg    
                            \<--------->|

                       +Zlgaf ^         _
                               \   .__.-*-.__. Solar
                                \  |    MAG  | Array
                                 \ |         |            .___. 
                                  x-----------.===========|  .' APP
                        LGA "fwd" |           |           `-'
                                  | +Zsc      |
                                  |     ^     |      
                                  |     |     |     
                                  |     |     | LGA "aft"  
                                .-.-----|-----x  
                             .-'.'   `- x------\> +Xsc  
                          .-' .'                \
                       .-'   @                   \    
                LPW .-'    SWEA                   v +Zlgaa
                                           22 deg
                                        |<--------->\

                                +Ysc, +Ylgaf, and +Ylgaa are into the page.

   The angles in the definitions are the opposites of the rotations
   described above because the rotations in the definitions are from
   the LGA frames to the spacecraft frame.

   \begindata

      FRAME_MAVEN_LGA_FWD           = -202030
      FRAME_-202030_NAME            = 'MAVEN_LGA_FWD'
      FRAME_-202030_CLASS           = 4
      FRAME_-202030_CLASS_ID        = -202030
      FRAME_-202030_CENTER          = -202
      TKFRAME_-202030_SPEC          = 'ANGLES'
      TKFRAME_-202030_RELATIVE      = 'MAVEN_SPACECRAFT'
      TKFRAME_-202030_ANGLES        = ( 0.0,   22.0, 0.0 )
      TKFRAME_-202030_AXES          = ( 1,      2,   3   )
      TKFRAME_-202030_UNITS         = 'DEGREES'

      FRAME_MAVEN_LGA_AFT           = -202040
      FRAME_-202040_NAME            = 'MAVEN_LGA_AFT'
      FRAME_-202040_CLASS           = 4
      FRAME_-202040_CLASS_ID        = -202040
      FRAME_-202040_CENTER          = -202
      TKFRAME_-202040_SPEC          = 'ANGLES'
      TKFRAME_-202040_RELATIVE      = 'MAVEN_SPACECRAFT'
      TKFRAME_-202040_ANGLES        = ( 0.0, -158.0, 0.0 )
      TKFRAME_-202040_AXES          = ( 1,      2,   3   )
      TKFRAME_-202040_UNITS         = 'DEGREES'

   \begintext


S/C-mounted Instrument Frames
-------------------------------------------------------------------------------

   This section defines frames for the instruments mounted on the s/c
   bus -- EUV, SEP, SWEA, SWIA and LPW.


EUV Frames

   The EUV frame -- MAVEN_EUV, ID -202110 -- is defined as a fixed offset
   frame with respect to the s/c frame. It has photometer boresights
   along the +Z axis and nominally is co-aligned with the s/c frame as
   shown on this diagram (see [6]):
   
      +Z s/c side:
      ------------                 ._____. APP
                                   \_____|
                                      | 
                                      |
                                      |  +Xsc
                                      | ^ 
             ._________._________..-----|-----.._________._________.
             |         |         +Xeuv -|--.  ||         |         |>
       MAG .-|         |     +Ysc   /^  |   \ ||         |         |-. MAG
          <  |         |        <----|--o    |||         |         |  >
           `-|         |            \|      / ||         |         |-'
            <|_________|_________|   |-----'  ||_________|_________|
                             <-------o--------'
                         +Yeuv    . EUV |   `-.
                               .-'      |      `-.
                            .-'         @         `-.
                         .-'             SWEA        `-.
                  LPW .-'                               `-. LPW

                                           +Zsc and +Zeuv are out of the page.

   The keywords below define the EUV frame.

   \begindata

      FRAME_MAVEN_EUV                 = -202110
      FRAME_-202110_NAME              = 'MAVEN_EUV'
      FRAME_-202110_CLASS             = 4
      FRAME_-202110_CLASS_ID          = -202110
      FRAME_-202110_CENTER            = -202
      TKFRAME_-202110_SPEC            = 'ANGLES'
      TKFRAME_-202110_RELATIVE        = 'MAVEN_SPACECRAFT'
      TKFRAME_-202110_ANGLES          = ( 0.0, 0.0, 0.0 )
      TKFRAME_-202110_AXES            = ( 1,   2,   3   )
      TKFRAME_-202110_UNITS           = 'DEGREES'


   \begintext


SEP Frames

   The SEP frames -- MAVEN_SEP1, ID -202120, and MAVEN_SEP2, ID
   -202125, -- are defined as fixed offset frames with respect to the
   s/c frame.

   The MAVEN_SEP1 frame, for the sensor mounted on the +X/+Y corner of
   the s/c +Z deck, is defined a follows (see [6]):

      -  +X axis is along the nominal boresight of the FOVs pointing
         in the HGA (forward) direction 

      -  +Y axis is nominally along the s/c +X axis

      -  +Z axis completes the right-handed frame

      -  the origin of the frame is at the CG of the sensor assembly.

   The MAVEN_SEP2 frame, for the sensor mounted on the +X/-Y corner of
   the s/c +Z deck, is defined a follows (see [6]):

      -  +X axis is along the nominal boresight of the FOVs pointing
         in the HGA (forward) direction 

      -  +Y axis is nominally along the s/c -X axis

      -  +Z axis completes the right-handed frame

      -  the origin of the frame is at the CG of the sensor assembly.

   This diagram illustrates the SEP frames:

      +X s/c side:
      ------------
                                 45 deg   45 deg
                                `.<---->|<---->.'
                                  `.    |    .'
                                    `.  |  .'

          *.            +Zsep2   +Xsep2  +Xsep1   +Zsep1             .*
        MAG2`o.             ^.         ^ ^         .^             .o' MAG1
               `-.            `.     .'   `.     .'            .-'  
                  `-.           `. .'  HGA  `. .'           .-'
                     `-o_________.x-----------o._________o-'
                            SEP2  |           | SEP1
                                  | +Zsc      |
                                  |     ^     |
                                  |     |     |
                                  |     |     |
                                  `-----|-----' +Ysc
                                  .-'`- o-------> 
                               .-'      |      `-.
                            .-'         @         `-. 
                         .-'             SWEA        `-.
                  LPW .-'                               `-. LPW

                                        +Xsc and +Ysep1  are out of the page.
                                             +Ysep2 is onto the page.

   As seen on the diagram nominally two rotations -- first by -90
   degrees about Z, then by -45 degrees about Y -- are needed to
   co-align the s/c frame with the SEP1 frame and two rotations --
   first by +90 degrees about Z, then by -45 degrees about Y -- are
   needed to co-align the s/c frame with the SEP2 frame.

   The angles in the definitions are the opposites of the rotations
   described above because the rotations in the definitions are from
   the SEP frames to the spacecraft frame.

   \begindata

      FRAME_MAVEN_SEP1                = -202120
      FRAME_-202120_NAME              = 'MAVEN_SEP1'
      FRAME_-202120_CLASS             = 4
      FRAME_-202120_CLASS_ID          = -202120
      FRAME_-202120_CENTER            = -202
      TKFRAME_-202120_SPEC            = 'ANGLES'
      TKFRAME_-202120_RELATIVE        = 'MAVEN_SPACECRAFT'
      TKFRAME_-202120_ANGLES          = (  90.0, 45.0, 0.0 )
      TKFRAME_-202120_AXES            = (   3,    2,   1   )
      TKFRAME_-202120_UNITS           = 'DEGREES'

      FRAME_MAVEN_SEP2                = -202125
      FRAME_-202125_NAME              = 'MAVEN_SEP2'
      FRAME_-202125_CLASS             = 4
      FRAME_-202125_CLASS_ID          = -202125
      FRAME_-202125_CENTER            = -202
      TKFRAME_-202125_SPEC            = 'ANGLES'
      TKFRAME_-202125_RELATIVE        = 'MAVEN_SPACECRAFT'
      TKFRAME_-202125_ANGLES          = ( -90.0, 45.0, 0.0 )
      TKFRAME_-202125_AXES            = (   3,    2,   1   )
      TKFRAME_-202125_UNITS           = 'DEGREES'

   \begintext


SWEA Frames

   The SWEA science frame -- MAVEN_SWEA, ID -202130 -- is defined as a
   fixed offset frame with respect to the s/c frame. Nominally it is
   rotated from the s/c frame by +140 degrees about Z as shown on this
   diagram (see [6],[8]):
   
      +Z s/c side:
      ------------                 ._____. APP
                                   \_____|
                                      | 
                                      |
                                      |  +Xsc
                                      | ^ 
             ._________._________..-----|-----.._________._________.
             |         |         ||  .--|--.  ||         |         |>
       MAG .-|         |     +Ysc   /   |   \ ||         |         |-. MAG
          <  |         |        <-------o    |||         |         |  >
           `-|         |            \       / ||         |         |-'
            <|_________|_________|HGA'-----'  ||_________|_________|
                                   -----------'
                                  .-'   |   `-.
                               .-'      |      `-.
                            .-'         o-.       `-.
                         .-'           /   `-.       `-.
                  LPW .-'             /       `.>       `-. LPW
                                     /         +Yswea
                                    v +Xswea

                                         +Zsc and +Zswea are out of the page.

   The SWEA science frame is defined with respect to the instrument's
   anode layout. SWEA has 16 anodes (numbered 0 to 15) each spanning
   22.5 degrees in the X-Y plane. In flight software and in ground data
   analysis software, the +X axis of the frame is at the boundary
   between anodes 0 and 15. To put +X in that direction, the SWEA
   science frame is rotated by +140 degrees about the Z axis with
   respect to the SWEA instrument frame (omitted from this FK), which,
   as defined in [6], is co-aligned with the spacecraft frame.  Thus, 
   SWEA science frame is rotated from the spacecraft frame by +140 degrees
   about the Z axis.
   
   The angle in the definition below is -140 because the rotation in the
   definition is from the SWEA science frame to the spacecraft frame.

   \begindata

      FRAME_MAVEN_SWEA                = -202130
      FRAME_-202130_NAME              = 'MAVEN_SWEA'
      FRAME_-202130_CLASS             = 4
      FRAME_-202130_CLASS_ID          = -202130
      FRAME_-202130_CENTER            = -202
      TKFRAME_-202130_SPEC            = 'ANGLES'
      TKFRAME_-202130_RELATIVE        = 'MAVEN_SPACECRAFT'
      TKFRAME_-202130_ANGLES          = ( 0.0, 0.0, -140.0 )
      TKFRAME_-202130_AXES            = ( 1,   2,      3   )
      TKFRAME_-202130_UNITS           = 'DEGREES'

   \begintext
   
   During cruise, the SWEA boom is stowed.  To go from the deployed to 
   the stowed boom configuration, rotate by +135 degrees about the +Y
   axis.  Then rotate by +140 degrees about the +Z axis to transform
   to the SWEA science frame.

   \begindata

      FRAME_MAVEN_SWEA_STOW           = -202131
      FRAME_-202131_NAME              = 'MAVEN_SWEA_STOW'
      FRAME_-202131_CLASS             = 4
      FRAME_-202131_CLASS_ID          = -202131
      FRAME_-202131_CENTER            = -202
      TKFRAME_-202131_SPEC            = 'ANGLES'
      TKFRAME_-202131_RELATIVE        = 'MAVEN_SPACECRAFT'
      TKFRAME_-202131_ANGLES          = ( 0.0, -135.0, -140.0 )
      TKFRAME_-202131_AXES            = ( 1,      2,      3   )
      TKFRAME_-202131_UNITS           = 'DEGREES'

   \begintext


SWIA Frames

   The SWIA "base" frame -- MAVEN_SWIA_BASE, ID -202140 -- is defined
   as a fixed offset frame with respect to and is nominally co-aligned
   with the s/c frame (see [6]).

   The SWIA frame -- MAVEN_SWIA, ID -202141 -- is defined as a fixed
   offset frame with respect to and is rotated first by +90 degrees
   about X, then by +90 degrees about Z from the SWIA "base" frame.
   The purpose of this frame is to co-align the frame's +Z axis with
   the instrument's symmetry axis and the frame's +X axis with the s/c +Z
   axis, which nominally points in the direction of the Sun, to allow
   using azimuthal coordinates to represent directions relative to the
   instrument (see [7]).

   This diagram illustrates the SWIA frames:

      +Z s/c side:
      ------------                 ._____. APP
                                   \_____|
                                      | 
                                      |
                                      |  +Xsc
                                      | ^ 
             ._________._________..-----|-----.._________._________.
             |         |         ||  .--|--.  +Xswiab    |         |>
       MAG .-|         |     +Ysc   /   |     ^          |         |-. MAG
          <  |         |        <-------o     |          |         |  >
           `-|         |         |  \         |          |         |-'
            <|_________|_________|HGA`-----'  | _________|_________|
                                      <-------o------->
                                +Yswiab       |       +Zswia
                               .        |     |`-.
                            .-'         @     |   `-.
                         .-'       SWEA       V      `-.
                  LPW .-'                     +Yswia    `-. LPW

                            +Zsc, +Zswiab, and +Xswia are out of the page.
 

   The keywords below define the SWIA frames. 

   \begindata

      FRAME_MAVEN_SWIA_BASE           = -202140
      FRAME_-202140_NAME              = 'MAVEN_SWIA_BASE'
      FRAME_-202140_CLASS             = 4
      FRAME_-202140_CLASS_ID          = -202140
      FRAME_-202140_CENTER            = -202
      TKFRAME_-202140_SPEC            = 'ANGLES'
      TKFRAME_-202140_RELATIVE        = 'MAVEN_SPACECRAFT'
      TKFRAME_-202140_ANGLES          = ( 0.0, 0.0, 0.0 )
      TKFRAME_-202140_AXES            = ( 1,   2,   3   )
      TKFRAME_-202140_UNITS           = 'DEGREES'

      FRAME_MAVEN_SWIA                = -202141
      FRAME_-202141_NAME              = 'MAVEN_SWIA'
      FRAME_-202141_CLASS             = 4
      FRAME_-202141_CLASS_ID          = -202141
      FRAME_-202141_CENTER            = -202
      TKFRAME_-202141_SPEC            = 'ANGLES'
      TKFRAME_-202141_RELATIVE        = 'MAVEN_SWIA_BASE'
      TKFRAME_-202141_ANGLES          = ( -90.0, -90.0, 0.0 )
      TKFRAME_-202141_AXES            = (   1,     3,   2   )
      TKFRAME_-202141_UNITS           = 'DEGREES'

   \begintext


LPW Frames

   The LPW frames -- MAVEN_LPW_PY, ID -202151, and MAVEN_LPW_MY, ID
   -202153, -- are defined as fixed offset frames with respect to the
   s/c frame.

   The MAVEN_LPW_PY frame, for the antenna extended in the s/c +Y
   ("PY") direction, and the MAVEN_LPW_MY frame, for the antenna
   extended in the s/c -Y ("MY") direction, are defined a follows (see
   [6]):

      -  +Z axis is along the antenna rod, pointing from the antenna
         mounting base toward the antenna tip.

      -  +Y axis is normal to the antenna base mounting surface, pointing
         from the mounting surface toward the "top" of the base assembly

      -  +X axis completes the right handed frame

      -  the origin of the frame is at the CG of the antenna assembly.

   This diagram illustrates the LPW frames:

      +Z s/c side:
      ------------                 ._____. APP
                                   \_____|
                                      | 
                                      |
                                      |  +Xsc
                                      | ^ 
             ._________._________..-----|-----.._________._________.
             |         |         ||  .--|--.             |         |>
       MAG .-|         |     +Ysc   /   |     ^ +Xlpwmy  |         |-. MAG
          <  |         |        <-------o    /           |         |  >
           `-|         |            \       /  |         |         |-'
            <|_________|_________|   '---- /  ||_________|_________|
                -------           `---o---o---'          -------
                   ^              .-'  \    `-.             ^
                    \   +Zlpwpy <'      \      `> +Zlpwmy  /
              30 deg \      .            \         -.     / 30 deg
                      v  .-'              v          `-. v
                      .-'         +Xlpwpy               `-. 
                  LPW                                       LPW

                                                 +Zsc, +Ylpwpy, and +Ylpwmy
                                                   are out of the page.

      -X s/c side:
      ------------

          *.                            _                            .*
        MAG `o.                  HGA  .' `.                       .o' MAG
               `-.                  .'     `.                  .-'  
                  `-.               ---------               .-'
                     `-o_________..-----------.._________o-'

                          +Ylpwpy ^   +Zsc    ^ +Ylpwmy
                                   \    ^    /  
                                  | \   |   / |
                                  |  \  |  /  |
                 -------     +Ysc `---o-|-x---'          -------
                    ^           <-------x   `-.             ^
                     \  +Zlpwpy <'      |      `> +Zlpwmy  /
              18 deg  \     .           @          -.     / 18 deg
                       v .-'             SWEA        `-. v
                      .-'                               `-.    
                  LPW                                       LPW

                                                  +Xsc is into the page.
                                                +Ylpwpy is out of the page.
                                                +Ylpwmy is into the page.


   As seen on the diagram nominally three rotations -- first by +90
   degrees about X, then by -150 degrees about Y, and finally by +18
   degrees about X -- are needed to co-align the s/c frame with the LPW
   "PY" frame and three rotations -- first by +90 degrees about X, then
   by -30 degrees about Y, and finally +18 degrees about X -- are
   needed to co-align the s/c frame with the LPW "MY" frame.

   The angles in the definitions are the opposites of the rotations
   described above because the rotations in the definitions are from
   the LPW frames to the spacecraft frame.

   \begindata

      FRAME_MAVEN_LPW_PY              = -202151
      FRAME_-202151_NAME              = 'MAVEN_LPW_PY'
      FRAME_-202151_CLASS             = 4
      FRAME_-202151_CLASS_ID          = -202151
      FRAME_-202151_CENTER            = -202
      TKFRAME_-202151_SPEC            = 'ANGLES'
      TKFRAME_-202151_RELATIVE        = 'MAVEN_SPACECRAFT'
      TKFRAME_-202151_ANGLES          = ( -90.0, 150.0, -18.0 )
      TKFRAME_-202151_AXES            = (   1,     2,     1   )
      TKFRAME_-202151_UNITS           = 'DEGREES'

      FRAME_MAVEN_LPW_MY              = -202153
      FRAME_-202153_NAME              = 'MAVEN_LPW_MY'
      FRAME_-202153_CLASS             = 4
      FRAME_-202153_CLASS_ID          = -202153
      FRAME_-202153_CENTER            = -202
      TKFRAME_-202153_SPEC            = 'ANGLES'
      TKFRAME_-202153_RELATIVE        = 'MAVEN_SPACECRAFT'
      TKFRAME_-202153_ANGLES          = ( -90.0,  30.0, -18.0 )
      TKFRAME_-202153_AXES            = (   1,     2,     1   )
      TKFRAME_-202153_UNITS           = 'DEGREES'

   \begintext


APP and APP-mounted Instrument Frames
-------------------------------------------------------------------------------

   This section defines frames for the Articulated Payload Platform
   (APP) and instruments mounted on it -- IUVS, STATIC, and NGIMS.


APP Frames

   Four frames are defined for APP:

      -  MAVEN_APP_BP, ID -202501, is the APP base-plate frame defined
         as a fixed offset frame relative to and is nominally
         co-aligned with the s/c frame. This frame is called ``BP''
         in [5].

      -  MAVEN_APP_IG, ID -202503, is the APP inner gimbal frame
         defined as a CK-based frame and rotated by the inner gimbal
         angle about Y relative to the MAVEN_APP_BP frame. This frame
         does not exist in [5].

      -  MAVEN_APP_OG, ID -202505, is the APP outer gimbal frame
         defined as a CK-based frame and rotated by the outer gimbal
         angle about X relative to the MAVEN_APP_IG frame. This frame
         is called ``AR'' in [5].

      -  MAVEN_APP, ID -202507, is the APP platform frame defined as a
         fixed offset frame relative to the MAVEN_APP_OG frame and
         nominally rotated from it first by -90 degrees about X, then
         by -90 degrees about Z, and finally by +155 degrees about Y.
         This frame is called ``APP'' in [5] with its axes labeled as 
         I (=X), J (=Y), and K (=Z).

   Nominally at the gimbal angle pair 0.0/-155.0 the axes of the 
   MAVEN_APP frame point as follows:

      -  MAVEN_APP +X (APP +I) along s/c +Z

      -  MAVEN_APP +Y (APP +J) along s/c +X

      -  MAVEN_APP +Z (APP +K) along s/c +Y

   as seen on these diagrams (the MAVEN_APP_IG and MAVEN_APP_OG frames
   are not shown):

      +Z s/c side (0.0/-155.0 APP position):
      --------------------------------------

                                      ^ +Yapp
                                      |
                                      |
                         +Zapp     .__|__. APP
                              <-------o _|
                                      ^ +Xbp
                                      | 
                                      |  +Xsc
                           +Ybp       | ^ 
             ._________.____  <-------o-|-----.._________._________.
             |         |             .--|--.  ||         |         |>
       MAG .-|         |     +Ysc   /   |   \ ||         |         |-. MAG
          <  |         |        <-------o    |||         |         |  >
           `-|         |            \       / ||         |         |-'
            <|_________|_________|HGA'-----'  ||_________|_________|
                                  `-----------'
                                  .-'   |   `-.
                               .-'      |      `-.
                            .-'         @         `-.
                         .-'             SWEA        `-.
                  LPW .-'                               `-. LPW

                                                 +Zsc, +Zpb, and +Xapp 
                                                  are out of the page.

      +X APP side (0.0/-155.0 APP position):
      --------------------------------------

                                   Nadir FOV
                                       ._____.     .
                                       \     /  .-' `.  Limb FOV
                                .-------\   /.-'      `.
                STATIC       .-'  .-----'               `_.
                       -------.   |           IUVS      | |
                      |   |   |   |                     | |
                       -------'   |                     | |
                             `-.  `----  +Yapp   -------' |
                                `---.-- ^ ---.------------
                                    |   |    |   |       |--.
                                    `-- | .  |   |       |  |
                            +Zapp     _ | _| '   `_______.--'
                                <-------o   /                 NGIMS
                                     |_____|
                                       | |
                                       | |
                                      ~ ~ ~ 

                                        ^ +Xsc
                                        |
                                        |
                            +Ysc        |
                                <-------o
                                                  +Zsc and +Xapp are 
                                                    out of the page.


   The angles in the definitions of the fixed offset frames below are
   the opposites of the rotations described above because the rotations
   in the definitions are from the structure frames to the base frames.

   \begindata

      FRAME_MAVEN_APP_BP              = -202501
      FRAME_-202501_NAME              = 'MAVEN_APP_BP'
      FRAME_-202501_CLASS             = 4
      FRAME_-202501_CLASS_ID          = -202501
      FRAME_-202501_CENTER            = -202
      TKFRAME_-202501_SPEC            = 'ANGLES'
      TKFRAME_-202501_RELATIVE        = 'MAVEN_SPACECRAFT'
      TKFRAME_-202501_ANGLES          = ( 0.0, 0.0, 0.0 )
      TKFRAME_-202501_AXES            = ( 1,   2,   3   )
      TKFRAME_-202501_UNITS           = 'DEGREES'

      FRAME_MAVEN_APP_IG              = -202503
      FRAME_-202503_NAME              = 'MAVEN_APP_IG'
      FRAME_-202503_CLASS             = 3
      FRAME_-202503_CLASS_ID          = -202503
      FRAME_-202503_CENTER            = -202
      CK_-202503_SCLK                 = -202
      CK_-202503_SPK                  = -202

      FRAME_MAVEN_APP_OG              = -202505
      FRAME_-202505_NAME              = 'MAVEN_APP_OG'
      FRAME_-202505_CLASS             = 3
      FRAME_-202505_CLASS_ID          = -202505
      FRAME_-202505_CENTER            = -202
      CK_-202505_SCLK                 = -202
      CK_-202505_SPK                  = -202

      FRAME_MAVEN_APP                 = -202507
      FRAME_-202507_NAME              = 'MAVEN_APP'
      FRAME_-202507_CLASS             = 4
      FRAME_-202507_CLASS_ID          = -202507
      FRAME_-202507_CENTER            = -202
      TKFRAME_-202507_SPEC            = 'ANGLES'
      TKFRAME_-202507_RELATIVE        = 'MAVEN_APP_OG'
      TKFRAME_-202507_ANGLES          = ( 90.0, 90.0, -155.0 )
      TKFRAME_-202507_AXES            = (  1,    3,      2   )
      TKFRAME_-202507_UNITS           = 'DEGREES'

   \begintext


IUVS Frames

   The IUVS frames defined by this FK include:

      -  IUVS base frame:

             MAVEN_IUVS_BASE,            ID -202510

      -  frames needed to model instrument pointing based on the
         articulating mirror position:

             MAVEN_IUVS_SCAN,            ID -202517, and
             MAVEN_IUVS,                 ID -202518

      -  frames defined for convenience of specifying various FOVs
         (to align frame's +Z with the FOV center vector):

             FRAME_MAVEN_IUVS_LIMB,      ID -202511, and 
             FRAME_MAVEN_IUVS_NADIR,     ID -202513, 

      -  bright object sensor frames (with frame's +Z in the direction
         of the BOS FOV center vector) :

             FRAME_MAVEN_IUVS_LIMB_BOS,  ID -202512, and 
             FRAME_MAVEN_IUVS_NADIR_BOS, ID -202514
             

   The MAVEN_IUVS_BASE frame is defined as a fixed offset frame
   relative to and is nominally co-aligned with the MAVEN_APP frame.

   The MAVEN_IUVS_SCAN frame is defined as a CK-based frame and is
   rotated from the MAVEN_IUVS_BASE frame about the +X axis by the
   angle needed to align the +Y axis the MAVEN_IUVS_SCAN frame with the
   actual view direction of the instrument for a given scan mirror
   position.

   The MAVEN_IUVS frame is defined as a fixed offset frame relative to
   the MAVEN_IUVS_SCAN frame and is rotated from it by -90 degrees
   about X to align the +Z axis of the MAVEN_IUVS frame with the actual
   view direction of the instrument (+Y of the MAVEN_IUVS_SCAN frame).

   The FOV frames -- FRAME_MAVEN_IUVS_LIMB and FRAME_MAVEN_IUVS_NADIR
   -- are defined as fixed offset frames relative the MAVEN_IUVS_BASE
   frame with their +Z axis pointing through the center of the
   corresponding FOVs and their X axis pointing in the direction of the
   MAVEN_IUVS_BASE frame's X axis. The following rotations are needed
   to co-align the MAVEN_IUVS_BASE frame with each of the FOV frames:

      FRAME_MAVEN_IUVS_LIMB         -167.75 about X

      FRAME_MAVEN_IUVS_NADIR         -90.00 about X
   
   The BOS frames -- FRAME_MAVEN_IUVS_LIMB_BOS and 
   FRAME_MAVEN_IUVS_NADIR_BOS -- are defined as fixed offset frames
   relative the MAVEN_IUVS_BASE frame with their +Z axis pointing
   through the center of the corresponding FOVs and their X axis
   pointing in the direction of the MAVEN_IUVS_BASE frame's X axis. The
   following rotations are needed to co-align the MAVEN_IUVS_BASE frame
   with each of the NOS frames:

      FRAME_MAVEN_IUVS_LIMB_BOS     -150.00 about X (*)

      FRAME_MAVEN_IUVS_NADIR_BOS     -90.00 about X

   (*) -150.00 was estimated from [6].


   This diagram illustrates the IUVS frames:

      +X APP side (0.0/-155.0 APP position, nadir IUVS mirror position):
      ------------------------------------------------------------------

                                           +Zuvs
                                           +Znadir
                                           +Znadirbos
                                           +Yscan       
                                          ^
                                          |
                                          |               ^ +Zlimbbos
                             +Zscan       |     +Y(*)    /    
                                  <-------o------->.    /  .->
                                       \^    /  .-' `. /.-'   +Zlimb
                                 +Ybase |   /.-'      o'.
                STATIC            .-----|              \`-.
                       ----- +Zbase     |               \ |`-> +Ylimbbos
                      |   |     <-------o               |\|
                       -------'   |                     | v +Ylimb
                             `-.  `----  +Yapp   -------' |
                                `---.-- ^ ---.------------
                                    |   |    |   |       |--.
                                    `-- | .  |   |       |  |
                            +Zapp     _ | _| '   `_______.--'
                                <-------o   /                 NGIMS
                                     |_____|
                                       | |
                                       | |
                                      ~ ~ ~ 

                                        ^ +Xsc
                                        |
                                        |
                            +Ysc        |
                                <-------o
                                                  +Zsc, +Xapp and +X of all
                                              IUVS frames are out of the page.

                                          +Yuvs, +Ynadir, and +Ynadirbos
                                      point to the right side of the diagram.

   The angles in the definitions of the fixed offset frames below are
   the opposites of the rotations described above because the rotations
   in the definitions are from the instrument frames to the base frames.

   \begindata

      FRAME_MAVEN_IUVS_BASE           = -202510
      FRAME_-202510_NAME              = 'MAVEN_IUVS_BASE'
      FRAME_-202510_CLASS             = 4
      FRAME_-202510_CLASS_ID          = -202510
      FRAME_-202510_CENTER            = -202
      TKFRAME_-202510_SPEC            = 'ANGLES'
      TKFRAME_-202510_RELATIVE        = 'MAVEN_APP'
      TKFRAME_-202510_ANGLES          = ( 0.0, 0.0, 0.0 )
      TKFRAME_-202510_AXES            = ( 1,   2,   3   )
      TKFRAME_-202510_UNITS           = 'DEGREES'

      FRAME_MAVEN_IUVS_LIMB           = -202511
      FRAME_-202511_NAME              = 'MAVEN_IUVS_LIMB'
      FRAME_-202511_CLASS             = 4
      FRAME_-202511_CLASS_ID          = -202511
      FRAME_-202511_CENTER            = -202
      TKFRAME_-202511_SPEC            = 'ANGLES'
      TKFRAME_-202511_RELATIVE        = 'MAVEN_IUVS_BASE'
      TKFRAME_-202511_ANGLES          = ( 167.75, 0.0, 0.0 )
      TKFRAME_-202511_AXES            = (   1,    2,   3   )
      TKFRAME_-202511_UNITS           = 'DEGREES'

      FRAME_MAVEN_IUVS_LIMB_BOS       = -202512
      FRAME_-202512_NAME              = 'MAVEN_IUVS_LIMB_BOS'
      FRAME_-202512_CLASS             = 4
      FRAME_-202512_CLASS_ID          = -202512
      FRAME_-202512_CENTER            = -202
      TKFRAME_-202512_SPEC            = 'ANGLES'
      TKFRAME_-202512_RELATIVE        = 'MAVEN_IUVS_BASE'
      TKFRAME_-202512_ANGLES          = ( 150.0, 0.0, 0.0 )
      TKFRAME_-202512_AXES            = (   1,   2,   3   )
      TKFRAME_-202512_UNITS           = 'DEGREES'

      FRAME_MAVEN_IUVS_NADIR          = -202513
      FRAME_-202513_NAME              = 'MAVEN_IUVS_NADIR'
      FRAME_-202513_CLASS             = 4
      FRAME_-202513_CLASS_ID          = -202513
      FRAME_-202513_CENTER            = -202
      TKFRAME_-202513_SPEC            = 'ANGLES'
      TKFRAME_-202513_RELATIVE        = 'MAVEN_IUVS_BASE'
      TKFRAME_-202513_ANGLES          = ( 90.0, 0.0, 0.0 )
      TKFRAME_-202513_AXES            = (  1,   2,   3   )
      TKFRAME_-202513_UNITS           = 'DEGREES'

      FRAME_MAVEN_IUVS_NADIR_BOS      = -202514
      FRAME_-202514_NAME              = 'MAVEN_IUVS_NADIR_BOS'
      FRAME_-202514_CLASS             = 4
      FRAME_-202514_CLASS_ID          = -202514
      FRAME_-202514_CENTER            = -202
      TKFRAME_-202514_SPEC            = 'ANGLES'
      TKFRAME_-202514_RELATIVE        = 'MAVEN_IUVS_BASE'
      TKFRAME_-202514_ANGLES          = ( 90.0, 0.0, 0.0 )
      TKFRAME_-202514_AXES            = (  1,   2,   3   )
      TKFRAME_-202514_UNITS           = 'DEGREES'

      FRAME_MAVEN_IUVS_SCAN           = -202517
      FRAME_-202517_NAME              = 'MAVEN_IUVS_SCAN'
      FRAME_-202517_CLASS             = 3
      FRAME_-202517_CLASS_ID          = -202517
      FRAME_-202517_CENTER            = -202
      CK_-202517_SCLK                 = -202
      CK_-202517_SPK                  = -202

      FRAME_MAVEN_IUVS                = -202518
      FRAME_-202518_NAME              = 'MAVEN_IUVS'
      FRAME_-202518_CLASS             = 4
      FRAME_-202518_CLASS_ID          = -202518
      FRAME_-202518_CENTER            = -202
      TKFRAME_-202518_SPEC            = 'ANGLES'
      TKFRAME_-202518_RELATIVE        = 'MAVEN_IUVS_SCAN'
      TKFRAME_-202518_ANGLES          = ( 90.0, 0.0, 0.0 )
      TKFRAME_-202518_AXES            = (  1,   2,   3   )
      TKFRAME_-202518_UNITS           = 'DEGREES'

   \begintext


STATIC Frames

   The STATIC frame -- MAVEN_STATIC, ID -202520 -- is defined
   as a fixed offset frame with respect to and is nominally co-aligned
   with the APP frame (see [6]), as shown in this diagram:


      +X APP side (0.0/-155.0 APP position):
      --------------------------------------

                                   Nadir FOV
               +Ystatic                ._____.     .
                        ^              \     /  .-' `.  Limb FOV
                        |       .-------\   /.-'      `.
                STATIC  |    .-'  .-----'               `_.
                       -|-----.   |           IUVS      | |
                <-------o |   |   |                     | |
            +Zstatic   -------'   |                     | |
                             `-.  `----  +Yapp   -------' |
                                `---.-- ^ ---.------------
                                    |   |    |   |       |--.
                                    `-- | .  |   |       |  |
                            +Zapp     _ | _| '   `_______.--'
                                <-------o   /                 NGIMS
                                     |_____|
                                       | |
                                       | |
                                      ~ ~ ~ 

                                        ^ +Xsc
                                        |
                                        |
                            +Ysc        |
                                <-------o
                                               +Zsc, +Xapp, and +X static 
                                                   are out of the page.

   The keywords below define the STATIC frame.

   \begindata

      FRAME_MAVEN_STATIC              = -202520
      FRAME_-202520_NAME              = 'MAVEN_STATIC'
      FRAME_-202520_CLASS             = 4
      FRAME_-202520_CLASS_ID          = -202520
      FRAME_-202520_CENTER            = -202
      TKFRAME_-202520_SPEC            = 'ANGLES'
      TKFRAME_-202520_RELATIVE        = 'MAVEN_APP'
      TKFRAME_-202520_ANGLES          = ( 0.0, 0.0, 0.0 )
      TKFRAME_-202520_AXES            = ( 1,   2,   3   )
      TKFRAME_-202520_UNITS           = 'DEGREES'

   \begintext


NGIMS Frames

   The NGIMS frame -- MAVEN_NGIMS, ID -202530 -- is defined as a fixed
   offset frame with respect to and is nominally co-aligned with the
   APP frame (see [6]).

   This diagram illustrates the NGIMS frame:

      +X APP side (0.0/-155.0 APP position):
      --------------------------------------

                                   Nadir FOV
                                       ._____.     .
                                       \     /  .-' `.  Limb FOV
                                .-------\   /.-'      `.
                STATIC       .-'  .-----'               `_.
                       -------.   |           IUVS      | |
                      |   |   |   |                     |   +Yngims 
                       -------'   |                     |  ^
                             `-.  `----  +Yapp   -------'  |
                                `---.-- ^ ---.------------ |
                                    |   |    | +Zngims   |-|.
                                    `-- | .  |     <-------o|
                         +Zapp     _ | _| '  '   `_______.--'  
                                <-------o   /                 NGIMS
                                     |_____|
                                       | |
                                       | |
                                      ~ ~ ~ 

                                        ^ +Xsc
                                        |
                                        |
                            +Ysc        |
                                <-------o
                                               +Zsc, +Xapp, and +Xngims
                                                  are out of the page.

   The angles in the definition of the fixed offset frame below are
   the opposites of the rotations described above because the rotations
   in the definition are from the instrument frame to the base frame.

   \begindata

      FRAME_MAVEN_NGIMS               = -202530
      FRAME_-202530_NAME              = 'MAVEN_NGIMS'
      FRAME_-202530_CLASS             = 4
      FRAME_-202530_CLASS_ID          = -202530
      FRAME_-202530_CENTER            = -202
      TKFRAME_-202530_SPEC            = 'ANGLES'
      TKFRAME_-202530_RELATIVE        = 'MAVEN_APP'
      TKFRAME_-202530_ANGLES          = ( 0.0, 0.0, 0.0 )
      TKFRAME_-202530_AXES            = ( 1,   2,   3   )
      TKFRAME_-202530_UNITS           = 'DEGREES'

   \begintext


Solar Array (SA) and MAG Frames
-------------------------------------------------------------------------------

   This section defines frames for solar arrays and instruments mounted on 
   the solar arrays -- MAG.


Solar Array Frames

   The solar array (SA) inboard panel frames -- MAVEN_SA_PY_IB, ID
   -202300, and MAVEN_SA_MY_IB, ID -202400, -- are defined as fixed
   offset frames with respect to the s/c frame.

   The SA outboard panel frames -- MAVEN_SA_PY_OB, ID -202305, and
   MAVEN_SA_MY_OB, ID -202405, -- are defined as fixed offset frames
   with respect to the corresponding inboard frames.

   All SA frames are defined as follows:

      -  +Z axis is along the normal to the panel active cell side

      -  +Y axis is along the panel edge parallel to the s/c YZ plane,
         pointing from the s/c toward the end of the array

      -  +X axis completes the right handed frame

      -  the origin of the frame is at the geometric center of the
         panel.

   This diagram illustrates the SA frames:
   
      -X s/c side:
      ------------
                       +Zsapyob                   +Zsamyob     
                     ^                                     ^
       +Ysapyob     /        +Zsapyib       +Zsamyib        \    +Ysamyob
          *<       /        ^           _           ^        \       >*
        MAG `-.   /         |    HGA  .' `.         |         \   .-'   MAG
             / `-x          |       .'     `.       |          o-' \
     20 deg /     `-.       |       ---------       |       .-'     \ 20 deg
          ---       <-------x____..-----------..____o------->       ---
              +Ysapyib            |           |           +Ysamyib
                                  | +Zsc      |
                                  |     ^     |
                                  |     |     |
                                  |     |     |
                             +Ysc `-----|-----'
                                <-------x -'`-.
                               .-'      |      `-.
                            .-'         @         `-. 
                         .-'             SWEA        `-.
                  LPW .-'                               `-. LPW

                                                  +Xsc is into the page.
                                     +Xsapyib and +Xsapyob are into the page.
                                     +Xsamyib and +Xsamyob are out of the page.

   As seen on the diagram

      -  the MAVEN_SA_PY_IB frame is co-aligned with the s/c frame

      -  the MAVEN_SA_PY_OB frame is rotated by +20 degrees about X
         relative to the MAVEN_SA_PY_IB frame

      -  the MAVEN_SA_MY_IB frame is rotated rotated by 180 degrees about Z
         relative to the s/c frame

      -  the MAVEN_SA_MY_OB frame is rotated by +20 degrees about X
         relative to the MAVEN_SA_MY_IB frame

   The angles in the definitions are the opposites of the rotations
   described above because the rotations in the definitions are from
   the structure frames to the base frames.

   \begindata

      FRAME_MAVEN_SA_PY_IB            = -202300
      FRAME_-202300_NAME              = 'MAVEN_SA_PY_IB'
      FRAME_-202300_CLASS             = 4
      FRAME_-202300_CLASS_ID          = -202300
      FRAME_-202300_CENTER            = -202
      TKFRAME_-202300_SPEC            = 'ANGLES'
      TKFRAME_-202300_RELATIVE        = 'MAVEN_SPACECRAFT'
      TKFRAME_-202300_ANGLES          = ( 0.0, 0.0, 0.0 )
      TKFRAME_-202300_AXES            = ( 1,   2,   3   )
      TKFRAME_-202300_UNITS           = 'DEGREES'

      FRAME_MAVEN_SA_PY_OB            = -202305
      FRAME_-202305_NAME              = 'MAVEN_SA_PY_OB'
      FRAME_-202305_CLASS             = 4
      FRAME_-202305_CLASS_ID          = -202305
      FRAME_-202305_CENTER            = -202
      TKFRAME_-202305_SPEC            = 'ANGLES'
      TKFRAME_-202305_RELATIVE        = 'MAVEN_SA_PY_IB'
      TKFRAME_-202305_ANGLES          = ( -20.0, 0.0, 0.0 )
      TKFRAME_-202305_AXES            = (   1,   2,   3   )
      TKFRAME_-202305_UNITS           = 'DEGREES'

      FRAME_MAVEN_SA_MY_IB            = -202400
      FRAME_-202400_NAME              = 'MAVEN_SA_MY_IB'
      FRAME_-202400_CLASS             = 4
      FRAME_-202400_CLASS_ID          = -202400
      FRAME_-202400_CENTER            = -202
      TKFRAME_-202400_SPEC            = 'ANGLES'
      TKFRAME_-202400_RELATIVE        = 'MAVEN_SPACECRAFT'
      TKFRAME_-202400_ANGLES          = ( 0.0, 0.0, 180.0 )
      TKFRAME_-202400_AXES            = ( 1,   2,     3   )
      TKFRAME_-202400_UNITS           = 'DEGREES'

      FRAME_MAVEN_SA_MY_OB            = -202405
      FRAME_-202405_NAME              = 'MAVEN_SA_MY_OB'
      FRAME_-202405_CLASS             = 4
      FRAME_-202405_CLASS_ID          = -202405
      FRAME_-202405_CENTER            = -202
      TKFRAME_-202405_SPEC            = 'ANGLES'
      TKFRAME_-202405_RELATIVE        = 'MAVEN_SA_MY_IB'
      TKFRAME_-202405_ANGLES          = ( -20.0, 0.0, 0.0 )
      TKFRAME_-202405_AXES            = (   1,   2,   3   )
      TKFRAME_-202405_UNITS           = 'DEGREES'

   \begintext


MAG Frames

   The MAG sensor frames -- MAVEN_MAG_PY, ID -202310, and MAVEN_MAG_PY,
   ID -202410, -- are defined as fixed offset frames with respect to
   the corresponding outboard SA panel frames as follows (see [6]):

      -  +Y axis is normal to the sensor mounting plate and points from
         the plate toward the top of the sensor,

      -  +Z axis is normal to the sensor side opposite to the cable 
         connector

      -  +X axis completes the right handed frame

      -  the origin of the frame is at the geometric center of the
         sensor.

   This diagram illustrates the SA and MAG frames:
   
      -X s/c side:
      ------------

              ^ +Zmagpy                                   +Zmagmy ^
             /         +Zsapyob                   +Zsamyob         \   
   +Ymagpy  /        ^                                     ^        \  +Ymagmy
     <-.   / MAGpy  /                                       \  MAGmy \   .->
        `-x<       /                    _                    \       >o-'
   +Ysapyob `-.   /              HGA  .' `.                   \   .-' +Ysamyob
             / `-x                  .'     `.                  o-' \
     20 deg /     `-.               ---------               .-'     \ 20 deg
          ---        `-o_________..-----------.._________o-'        ---
                                  |           |
                                  | +Zsc      |
                                  |     ^     |
                                  |     |     |
                                  |     |     |
                             +Ysc `-----|-----'
                                <-------x -'`-.
                               .-'      |      `-.
                            .-'         @         `-. 
                         .-'             SWEA        `-.
                  LPW .-'                               `-. LPW

                                                 +Xsc is into the page.
                                     +Xsapyob and +Xmagpy are into the page.
                                     +Xsamyob and +Xmagmy are out of the page.

   As seen on the diagram the MAG sensor frames are nominally co-aligned 
   with the corresponding outboard SA panel frames.

   \begindata

      FRAME_MAVEN_MAG_PY              = -202310
      FRAME_-202310_NAME              = 'MAVEN_MAG_PY'
      FRAME_-202310_CLASS             = 4
      FRAME_-202310_CLASS_ID          = -202310
      FRAME_-202310_CENTER            = -202
      TKFRAME_-202310_SPEC            = 'ANGLES'
      TKFRAME_-202310_RELATIVE        = 'MAVEN_SA_PY_OB'
      TKFRAME_-202310_ANGLES          = ( 0.0, 0.0, 0.0 )
      TKFRAME_-202310_AXES            = ( 1,   2,   3   )
      TKFRAME_-202310_UNITS           = 'DEGREES'

      FRAME_MAVEN_MAG_MY              = -202410
      FRAME_-202410_NAME              = 'MAVEN_MAG_MY'
      FRAME_-202410_CLASS             = 4
      FRAME_-202410_CLASS_ID          = -202410
      FRAME_-202410_CENTER            = -202
      TKFRAME_-202410_SPEC            = 'ANGLES'
      TKFRAME_-202410_RELATIVE        = 'MAVEN_SA_MY_OB'
      TKFRAME_-202410_ANGLES          = ( 0.0, 0.0, 0.0 )
      TKFRAME_-202410_AXES            = ( 1,   2,   3   )
      TKFRAME_-202410_UNITS           = 'DEGREES'

   \begintext


MAVEN NAIF ID Codes -- Definitions
========================================================================

   This section contains name to NAIF ID mappings for the MAVEN mission.
   Once the contents of this file is loaded into the KERNEL POOL, these 
   mappings become available within SPICE, making it possible to use 
   names instead of ID code in the high level SPICE routine calls. 

   Spacecraft:
   -----------

      MAVEN                           -202

      MAVEN_SPACECRAFT                -202000
      MAVEN_SPACECRAFT_BUS            -202000
      MAVEN_SC_BUS                    -202000


   Antennas:
   ---------

      MAVEN_HGA                       -202010
      MAVEN_UHF                       -202020
      MAVEN_LGA_FWD                   -202030
      MAVEN_LGA_AFT                   -202040


   S/C-mounted Science Instruments (PY=+Y, MY=-Y):
   -----------------------------------------------

      MAVEN_EUV                       -202110
      MAVEN_EUV1                      -202111
      MAVEN_EUV2                      -202112
      MAVEN_EUV3                      -202113

      MAVEN_SEP1                      -202120
      MAVEN_SEP1_FWD1                 -202121
      MAVEN_SEP1_FWD2                 -202122
      MAVEN_SEP1_AFT1                 -202123
      MAVEN_SEP1_AFT2                 -202124
      MAVEN_SEP2                      -202125
      MAVEN_SEP2_FWD1                 -202126
      MAVEN_SEP2_FWD2                 -202127
      MAVEN_SEP2_AFT1                 -202128
      MAVEN_SEP2_AFT2                 -202129

      MAVEN_SWEA                      -202130
      MAVEN_SWEA_FRONT                -202131
      MAVEN_SWEA_BACK                 -202132

      MAVEN_SWIA_BASE                 -202140
      MAVEN_SWIA                      -202141
      MAVEN_SWIA_SWTSPOT              -202142
      MAVEN_SWIA_FRONT                -202143
      MAVEN_SWIA_BACK                 -202144

      MAVEN_LPW                       -202150
      MAVEN_LPW_PY                    -202151
      MAVEN_LPW_PY_TIP                -202152
      MAVEN_LPW_MY                    -202153
      MAVEN_LPW_MY_TIP                -202154


   Solar Arrays and MAG (PY=+Y, MY=-Y, IB=inboard, OB=outboard ):
   --------------------------------------------------------------

      MAVEN_SA_PY_IB                  -202300
      MAVEN_SA_PY_IB_C1               -202301
      MAVEN_SA_PY_IB_C2               -202302
      MAVEN_SA_PY_IB_C3               -202303
      MAVEN_SA_PY_IB_C4               -202304

      MAVEN_SA_PY_OB                  -202305
      MAVEN_SA_PY_OB_C1               -202306
      MAVEN_SA_PY_OB_C2               -202307
      MAVEN_SA_PY_OB_C3               -202308
      MAVEN_SA_PY_OB_C4               -202309

      MAVEN_MAG1                      -202310
      MAVEN_MAG_PY                    -202310

      MAVEN_SA_MY_IB                  -202400
      MAVEN_SA_MY_IB_C1               -202401
      MAVEN_SA_MY_IB_C2               -202402
      MAVEN_SA_MY_IB_C3               -202403
      MAVEN_SA_MY_IB_C4               -202404

      MAVEN_SA_MY_OB                  -202405
      MAVEN_SA_MY_OB_C1               -202406
      MAVEN_SA_MY_OB_C2               -202407
      MAVEN_SA_MY_OB_C3               -202408
      MAVEN_SA_MY_OB_C4               -202409
      
      MAVEN_MAG2                      -202410
      MAVEN_MAG_MY                    -202410


   APP and APP-mounted Instruments:
   --------------------------------

      MAVEN_APP_BP                    -202501
      MAVEN_APP_IG                    -202503
      MAVEN_APP_OG                    -202505
      MAVEN_APP                       -202507
      
      MAVEN_IUVS_BASE                 -202510
      MAVEN_IUVS_LIMB                 -202511
      MAVEN_IUVS_LIMB_BOS             -202512
      MAVEN_IUVS_NADIR                -202513
      MAVEN_IUVS_NADIR_BOS            -202514
      MAVEN_IUVS_OCC_BIG              -202515
      MAVEN_IUVS_OCC_SMALL            -202516
      MAVEN_IUVS                      -202518
      MAVEN_IUVS_MAIN_SLIT            -202519

      MAVEN_STATIC                    -202520
      MAVEN_STATIC_SWTSPOT            -202521

      MAVEN_NGIMS                     -202530
      MAVEN_NGIMS_OPEN                -202531
      MAVEN_NGIMS_CLOSED              -202532
      MAVEN_NGIMS_EXHAUST             -202533


   The mappings summarized in the table above are implemented by the
   keywords below.

   \begindata

      NAIF_BODY_NAME += ( 'MAVEN'                          )
      NAIF_BODY_CODE += ( -202                             )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SPACECRAFT'               )
      NAIF_BODY_CODE += ( -202000                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SPACECRAFT_BUS'           )
      NAIF_BODY_CODE += ( -202000                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SC_BUS'                   )
      NAIF_BODY_CODE += ( -202000                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_HGA'                      )
      NAIF_BODY_CODE += ( -202010                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_UHF'                      )
      NAIF_BODY_CODE += ( -202020                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_LGA_FWD'                  )
      NAIF_BODY_CODE += ( -202030                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_LGA_AFT'                  )
      NAIF_BODY_CODE += ( -202040                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_EUV'                      )
      NAIF_BODY_CODE += ( -202110                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_EUV1'                     )
      NAIF_BODY_CODE += ( -202111                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_EUV2'                     )
      NAIF_BODY_CODE += ( -202112                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_EUV3'                     )
      NAIF_BODY_CODE += ( -202113                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SEP_PY'                   )
      NAIF_BODY_CODE += ( -202120                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SEP_PY_FWD1'              )
      NAIF_BODY_CODE += ( -202121                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SEP_PY_FWD2'              )
      NAIF_BODY_CODE += ( -202122                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SEP_PY_AFT1'              )
      NAIF_BODY_CODE += ( -202123                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SEP_PY_AFT2'              )
      NAIF_BODY_CODE += ( -202124                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SEP_MY'                   )
      NAIF_BODY_CODE += ( -202125                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SEP_MY_FWD1'              )
      NAIF_BODY_CODE += ( -202126                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SEP_MY_FWD2'              )
      NAIF_BODY_CODE += ( -202127                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SEP_MY_AFT1'              )
      NAIF_BODY_CODE += ( -202128                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SEP_MY_AFT2'              )
      NAIF_BODY_CODE += ( -202129                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SEP1'                     )
      NAIF_BODY_CODE += ( -202120                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SEP1_FWD1'                )
      NAIF_BODY_CODE += ( -202121                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SEP1_FWD2'                )
      NAIF_BODY_CODE += ( -202122                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SEP1_AFT1'                )
      NAIF_BODY_CODE += ( -202123                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SEP1_AFT2'                )
      NAIF_BODY_CODE += ( -202124                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SEP2'                     )
      NAIF_BODY_CODE += ( -202125                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SEP2_FWD1'                )
      NAIF_BODY_CODE += ( -202126                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SEP2_FWD2'                )
      NAIF_BODY_CODE += ( -202127                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SEP2_AFT1'                )
      NAIF_BODY_CODE += ( -202128                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SEP2_AFT2'                )
      NAIF_BODY_CODE += ( -202129                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SWEA'                     )
      NAIF_BODY_CODE += ( -202130                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SWEA_FRONT'               )
      NAIF_BODY_CODE += ( -202131                          )

      NAIF_BODY_NAME += ( 'MAVEN_SWEA_BACK'                )
      NAIF_BODY_CODE += ( -202132                          )

      NAIF_BODY_NAME += ( 'MAVEN_SWIA_BASE'                )
      NAIF_BODY_CODE += ( -202140                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SWIA'                     )
      NAIF_BODY_CODE += ( -202141                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SWIA_SWTSPOT'             )
      NAIF_BODY_CODE += ( -202142                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SWIA_FRONT'               )
      NAIF_BODY_CODE += ( -202143                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SWIA_BACK'                )
      NAIF_BODY_CODE += ( -202144                          )

      NAIF_BODY_NAME += ( 'MAVEN_LPW'                      )
      NAIF_BODY_CODE += ( -202150                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_LPW_PY'                   )
      NAIF_BODY_CODE += ( -202151                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_LPW_PY_TIP'               )
      NAIF_BODY_CODE += ( -202152                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_LPW_MY'                   )
      NAIF_BODY_CODE += ( -202153                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_LPW_MY_TIP'               )
      NAIF_BODY_CODE += ( -202154                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SA_PY_IB'                 )
      NAIF_BODY_CODE += ( -202300                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SA_PY_IB_C1'              )
      NAIF_BODY_CODE += ( -202301                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SA_PY_IB_C2'              )
      NAIF_BODY_CODE += ( -202302                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SA_PY_IB_C3'              )
      NAIF_BODY_CODE += ( -202303                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SA_PY_IB_C4'              )
      NAIF_BODY_CODE += ( -202304                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SA_PY_OB'                 )
      NAIF_BODY_CODE += ( -202305                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SA_PY_OB_C1'              )
      NAIF_BODY_CODE += ( -202306                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SA_PY_OB_C2'              )
      NAIF_BODY_CODE += ( -202307                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SA_PY_OB_C3'              )
      NAIF_BODY_CODE += ( -202308                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SA_PY_OB_C4'              )
      NAIF_BODY_CODE += ( -202309                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_MAG1'                     )
      NAIF_BODY_CODE += ( -202310                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_MAG_PY'                   )
      NAIF_BODY_CODE += ( -202310                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SA_MY_IB'                 )
      NAIF_BODY_CODE += ( -202400                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SA_MY_IB_C1'              )
      NAIF_BODY_CODE += ( -202401                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SA_MY_IB_C2'              )
      NAIF_BODY_CODE += ( -202402                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SA_MY_IB_C3'              )
      NAIF_BODY_CODE += ( -202403                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SA_MY_IB_C4'              )
      NAIF_BODY_CODE += ( -202404                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SA_MY_OB'                 )
      NAIF_BODY_CODE += ( -202405                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SA_MY_OB_C1'              )
      NAIF_BODY_CODE += ( -202406                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SA_MY_OB_C2'              )
      NAIF_BODY_CODE += ( -202407                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SA_MY_OB_C3'              )
      NAIF_BODY_CODE += ( -202408                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_SA_MY_OB_C4'              )
      NAIF_BODY_CODE += ( -202409                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_MAG2'                     )
      NAIF_BODY_CODE += ( -202410                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_MAG_MY'                   )
      NAIF_BODY_CODE += ( -202410                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_APP_BP'                   )
      NAIF_BODY_CODE += ( -202501                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_APP_IG'                   )
      NAIF_BODY_CODE += ( -202503                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_APP_OG'                   )
      NAIF_BODY_CODE += ( -202505                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_APP'                      )
      NAIF_BODY_CODE += ( -202507                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_IUVS_BASE'                )
      NAIF_BODY_CODE += ( -202510                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_IUVS_LIMB'                )
      NAIF_BODY_CODE += ( -202511                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_IUVS_LIMB_BOS'            )
      NAIF_BODY_CODE += ( -202512                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_IUVS_NADIR'               )
      NAIF_BODY_CODE += ( -202513                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_IUVS_NADIR_BOS'           )
      NAIF_BODY_CODE += ( -202514                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_IUVS_OCC_BIG'             )
      NAIF_BODY_CODE += ( -202515                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_IUVS_OCC_SMALL'           )
      NAIF_BODY_CODE += ( -202516                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_IUVS'                     )
      NAIF_BODY_CODE += ( -202518                          )

      NAIF_BODY_NAME += ( 'MAVEN_IUVS_MAIN_SLIT'           )
      NAIF_BODY_CODE += ( -202519                          )

      NAIF_BODY_NAME += ( 'MAVEN_STATIC'                   )
      NAIF_BODY_CODE += ( -202520                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_STATIC_SWTSPOT'           )
      NAIF_BODY_CODE += ( -202521                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_NGIMS'                    )
      NAIF_BODY_CODE += ( -202530                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_NGIMS_OPEN'               )
      NAIF_BODY_CODE += ( -202531                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_NGIMS_CLOSED'             )
      NAIF_BODY_CODE += ( -202532                          )
                                                            
      NAIF_BODY_NAME += ( 'MAVEN_NGIMS_EXHAUST'            )
      NAIF_BODY_CODE += ( -202533                          )
                                                            
   \begintext

End of FK File.
