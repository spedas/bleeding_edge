KPL/FK

Mars Atmosphere and Volatile EvolutioN (MAVEN) Frames Kernel - Miscellaneous
===============================================================================

   This frame kernel contains an additional set of frame definitions for the
   MAVEN spacecraft, its structures and science instruments. This frame
   kernel also contains name - to - NAIF ID mappings for MAVEN science
   instruments and s/c structures (see the last section of the file.)


Version and Date
-------------------------------------------------------------------------------

   Version 0.1 -- April 12, 2014 --     Davin Larson, SEP Team/SSL-UCB

      Initial Release



Contact Information
-------------------------------------------------------------------------------



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
      MSO               rel.to J2000         DYNAMIC        -202911

   \begindata

      FRAME_MSO              =  -202911
      FRAME_-202911_NAME           = 'MSO'
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

      SUNZ               rel.to J2000         DYNAMIC        -202913

   \begindata

      FRAME_SUNZ              =  -202913
      FRAME_-202913_NAME           = 'SUNZ'
      FRAME_-202913_CLASS          =  5
      FRAME_-202913_CLASS_ID       =  -202913
      FRAME_-202913_CENTER         =  499
      FRAME_-202913_RELATIVE       = 'J2000'
      FRAME_-202913_DEF_STYLE      = 'PARAMETERIZED'
      FRAME_-202913_FAMILY         = 'TWO-VECTOR'
      FRAME_-202913_PRI_AXIS       = 'Z'
      FRAME_-202913_PRI_VECTOR_DEF = 'OBSERVER_TARGET_POSITION'
      FRAME_-202913_PRI_OBSERVER   = 'MARS'
      FRAME_-202913_PRI_TARGET     = 'SUN'
      FRAME_-202913_PRI_ABCORR     = 'NONE'
      FRAME_-202913_SEC_AXIS       = 'Y'
      FRAME_-202913_SEC_VECTOR_DEF = 'OBSERVER_TARGET_VELOCITY'
      FRAME_-202913_SEC_OBSERVER   = 'MARS'
      FRAME_-202913_SEC_TARGET     = 'SUN'
      FRAME_-202913_SEC_ABCORR     = 'NONE'
      FRAME_-202913_SEC_FRAME      = 'J2000'

   \begintext

      MSUNZ               rel.to J2000         DYNAMIC        -202914

   \begindata

      FRAME_MSUNZ              =  -202914
      FRAME_-202914_NAME           = 'MSUNZ'
      FRAME_-202914_CLASS          =  5
      FRAME_-202914_CLASS_ID       =  -202914
      FRAME_-202914_CENTER         =  499
      FRAME_-202914_RELATIVE       = 'J2000'
      FRAME_-202914_DEF_STYLE      = 'PARAMETERIZED'
      FRAME_-202914_FAMILY         = 'TWO-VECTOR'
      FRAME_-202914_PRI_AXIS       = 'Z'
      FRAME_-202914_PRI_VECTOR_DEF = 'OBSERVER_TARGET_POSITION'
      FRAME_-202914_PRI_OBSERVER   = 'MARS'
      FRAME_-202914_PRI_TARGET     = 'SUN'
      FRAME_-202914_PRI_ABCORR     = 'NONE'
      FRAME_-202914_SEC_AXIS       = '-Y'
      FRAME_-202914_SEC_VECTOR_DEF = 'OBSERVER_TARGET_VELOCITY'
      FRAME_-202914_SEC_OBSERVER   = 'MARS'
      FRAME_-202914_SEC_TARGET     = 'SUN'
      FRAME_-202914_SEC_ABCORR     = 'NONE'
      FRAME_-202914_SEC_FRAME      = 'J2000'

   \begintext


      MAVEN_MMO                rel.to J2000         DYNAMIC        -202915

   \begindata

      FRAME_MAVEN_MMO              =  -202915
      FRAME_-202915_NAME           = 'MAVEN_MMO'
      FRAME_-202915_CLASS          =  5
      FRAME_-202915_CLASS_ID       =  -202915
      FRAME_-202915_CENTER         =  499
      FRAME_-202915_RELATIVE       = 'J2000'
      FRAME_-202915_DEF_STYLE      = 'PARAMETERIZED'
      FRAME_-202915_FAMILY         = 'TWO-VECTOR'
      FRAME_-202915_PRI_AXIS       = 'X'
      FRAME_-202915_PRI_VECTOR_DEF = 'OBSERVER_TARGET_POSITION'
      FRAME_-202915_PRI_OBSERVER   = 'MAVEN'
      FRAME_-202915_PRI_TARGET     = 'MARS'
      FRAME_-202915_PRI_ABCORR     = 'NONE'
      FRAME_-202915_SEC_AXIS       = 'Y'
      FRAME_-202915_SEC_VECTOR_DEF = 'OBSERVER_TARGET_VELOCITY'
      FRAME_-202915_SEC_OBSERVER   = 'MAVEN'
      FRAME_-202915_SEC_TARGET     = 'MARS'
      FRAME_-202915_SEC_ABCORR     = 'NONE'
      FRAME_-202915_SEC_FRAME      = 'J2000'

   \begintext





   Spacecraft frame:
   -----------------
      MAVEN_SPACECRAFT        rel.to MME_2000      CK             -202000


MAVEN Dynamic Frames
-------------------------------------------------------------------------------

   This section defined dynamic frames of interest to MAVEN science
   investigations.



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


S/C Alternate Frame
-------------------------------------------------------------------------------
This frame is co-aligned with the MAVEN_SSO frame during nominal sun pointing orientation

   \begindata

      FRAME_MAVEN_SCALT           = -202050
      FRAME_-202050_NAME            = 'MAVEN_SCALT'
      FRAME_-202050_CLASS           = 4
      FRAME_-202050_CLASS_ID        = -202050
      FRAME_-202050_CENTER          = -202
      TKFRAME_-202050_SPEC          = 'ANGLES'
      TKFRAME_-202050_RELATIVE      = 'MAVEN_SPACECRAFT'
      TKFRAME_-202050_ANGLES        = ( 180.0, -90.0,   90.0 )
      TKFRAME_-202050_AXES          = ( 1,         2,    1   )
      TKFRAME_-202050_UNITS         = 'DEGREES'

   \begintext






   As seen on the diagram the MAG sensor frames are nominally co-aligned 
   with the corresponding outboard SA panel frames.

   \begindata

      FRAME_MAVEN_MAG1              = -202311
      FRAME_-202311_NAME              = 'MAVEN_MAG1'
      FRAME_-202311_CLASS             = 4
      FRAME_-202311_CLASS_ID          = -202311
      FRAME_-202311_CENTER            = -202
      TKFRAME_-202311_SPEC            = 'ANGLES'
      TKFRAME_-202311_RELATIVE        = 'MAVEN_SA_PY_OB'
      TKFRAME_-202311_ANGLES          = ( 0.0, 0.0, 0.0 )
      TKFRAME_-202311_AXES            = ( 1,   2,   3   )
      TKFRAME_-202311_UNITS           = 'DEGREES'

      FRAME_MAVEN_MAG2              = -202411
      FRAME_-202411_NAME              = 'MAVEN_MAG2'
      FRAME_-202411_CLASS             = 4
      FRAME_-202411_CLASS_ID          = -202411
      FRAME_-202411_CENTER            = -202
      TKFRAME_-202411_SPEC            = 'ANGLES'
      TKFRAME_-202411_RELATIVE        = 'MAVEN_SA_MY_OB'
      TKFRAME_-202411_ANGLES          = ( 0.0, 0.0, 0.0 )
      TKFRAME_-202411_AXES            = ( 1,   2,   3   )
      TKFRAME_-202411_UNITS           = 'DEGREES'

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
      TKFRAME_-202520_ANGLES          = ( 180.0, 0.0, 180.0 )
      TKFRAME_-202520_AXES            = ( 1,   2,   3   )
      TKFRAME_-202520_UNITS           = 'DEGREES'

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


   The mappings summarized in the table above are implemented by the
   keywords below.

   \begindata
   
      NAIF_BODY_NAME += ( 'MAVEN_SCALT'                  )
      NAIF_BODY_CODE += ( -202050                        )

      NAIF_BODY_NAME += ( 'SUNZ'                  )
      NAIF_BODY_CODE += ( -202913                        )

      NAIF_BODY_NAME += ( 'MSUNZ'                  )
      NAIF_BODY_CODE += ( -202914                        )

      NAIF_BODY_NAME += ( 'MAVEN_MMO'                  )
      NAIF_BODY_CODE += ( -202915                        )

      NAIF_BODY_NAME += ( 'MAVEN_MAG1'                     )
      NAIF_BODY_CODE += ( -202311                          )
                                                            

      NAIF_BODY_NAME += ( 'MAVEN_MAG2'                     )
      NAIF_BODY_CODE += ( -202411                          )
                                                            

                                                            
      NAIF_BODY_NAME   +=  ( 'SIDING_SPRING' )
      NAIF_BODY_CODE   +=  ( 1003228 )

      NAIF_BODY_NAME   +=  ( 'CSS' )
      NAIF_BODY_CODE   +=  ( 1003228 )



                                                            
   \begintext

End of FK File.
