
S. YOKOTA

Selenocentric Solar Ecliptic coordinates (SSE)
---------------------------------------

   Definition:
   -----------
   The Geocentric Solar Ecliptic frame is defined as follows (from [3]):

      -  X-Y plane is defined by the Earth Mean Ecliptic plane of date:
         the +Z axis, primary vector, is the normal vector to this plane,
         always pointing toward the North side of the invariant plane;

      -  +X axis is the component of the Earth-Sun vector that is orthogonal
         to the +Z axis;

      -  +Y axis completes the right-handed system;

      -  the origin of this frame is the Sun's center of mass.

   All the vectors are geometric: no aberration corrections are used.


   Required Data:
   --------------
   This frame is defined as a two-vector frame using two different types
   of specifications for the primary and secondary vectors.

   The primary vector is defined as a constant vector in the ECLIPDATE
   frame and therefore, no additional data is required to compute this
   vector.

   The secondary vector is defined as an 'observer-target position' vector,
   therefore, the ephemeris data required to compute the Moon-Sun vector
   in J2000 frame have to be loaded prior to using this frame.


   Remarks:
   --------
   SPICE imposes a constraint in the definition of dynamic frames:

   When the definition of a parameterized dynamic frame F1 refers to a
   second frame F2 the referenced frame F2 may be dynamic, but F2 must not
   make reference to any dynamic frame. For further information on this
   topic, please refer to [1].

   Therefore, no other dynamic frame should make reference to this frame.

   Since the secondary vector of this frame is defined as an
   'observer-target position' vector, the usage of different planetary
   ephemerides conduces to different implementations of this frame,
   but only when these data lead to different projections of the
   Earth-Sun vector on the Earth Ecliptic plane of date.

   As an example, note that the average difference in position of the +X
   axis of this frame, when using DE405 vs. DE403 ephemerides, is about
   14.3 micro-radians, with a maximum of 15.0 micro-radians.



      FRAME_SSE                     =  1500301
      FRAME_1500301_NAME            = 'SSE' 
      FRAME_1500301_CLASS           =  5
      FRAME_1500301_CLASS_ID        =  1500301
      FRAME_1500301_CENTER          =  301
      FRAME_1500301_RELATIVE        = 'J2000'
      FRAME_1500301_DEF_STYLE       = 'PARAMETERIZED'
      FRAME_1500301_FAMILY          = 'TWO-VECTOR'
      FRAME_1500301_PRI_AXIS        = 'Z'
      FRAME_1500301_PRI_VECTOR_DEF  = 'CONSTANT'
      FRAME_1500301_PRI_FRAME       = 'ECLIPDATE'
      FRAME_1500301_PRI_SPEC        = 'RECTANGULAR'
      FRAME_1500301_PRI_VECTOR      = ( 0, 0, 1 )
      FRAME_1500301_SEC_AXIS        = 'X'
      FRAME_1500301_SEC_VECTOR_DEF  = 'OBSERVER_TARGET_POSITION'
      FRAME_1500301_SEC_OBSERVER    = 'MOON'
      FRAME_1500301_SEC_TARGET      = 'SUN'  
      FRAME_1500301_SEC_ABCORR      = 'NONE'

  \begindata

      FRAME_SSE                     =  1500301
      FRAME_1500301_NAME            = 'SSE' 
      FRAME_1500301_CLASS           =  5
      FRAME_1500301_CLASS_ID        =  1500301
      FRAME_1500301_CENTER          =  301
      FRAME_1500301_RELATIVE        = 'J2000'
      FRAME_1500301_DEF_STYLE       = 'PARAMETERIZED'
      FRAME_1500301_FAMILY          = 'TWO-VECTOR'
      FRAME_1500301_PRI_AXIS        = 'X'
      FRAME_1500301_PRI_VECTOR_DEF  = 'OBSERVER_TARGET_POSITION'
      FRAME_1500301_PRI_OBSERVER    = 'MOON'
      FRAME_1500301_PRI_TARGET      = 'SUN'
      FRAME_1500301_PRI_ABCORR      = 'NONE'
      FRAME_1500301_PRI_VECTOR      = ( 0, 0, 1 )
      FRAME_1500301_SEC_AXIS        = 'Y'
      FRAME_1500301_SEC_VECTOR_DEF  = 'OBSERVER_TARGET_VELOCITY'
      FRAME_1500301_SEC_OBSERVER    = 'MOON'
      FRAME_1500301_SEC_TARGET      = 'SUN'  
      FRAME_1500301_SEC_ABCORR      = 'NONE'
      FRAME_1500301_SEC_FRAME       = 'J2000'

  \begintext
