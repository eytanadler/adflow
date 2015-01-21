   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.10 (r5363) -  9 Sep 2014 09:53
   !
   !  Differentiation of bceulerwall in reverse (adjoint) mode (with options i4 dr8 r8 noISIZE):
   !   gradient     of useful results: *rev *p *gamma *w *rlv *si
   !                *sj *sk tref rgas
   !   with respect to varying inputs: *rev *p *gamma *w *rlv *si
   !                *sj *sk *(*bcdata.norm) tref rgas
   !   Plus diff mem management of: rev:in p:in gamma:in w:in rlv:in
   !                si:in sj:in sk:in bcdata:in *bcdata.norm:in
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          bcEulerWall.f90                                 *
   !      * Author:        Edwin van der Weide                             *
   !      * Starting date: 03-07-2003                                      *
   !      * Last modified: 06-12-2005                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   SUBROUTINE BCEULERWALL_B(secondhalo, correctfork)
   !
   !      ******************************************************************
   !      *                                                                *
   !      * bcEulerWall applies the inviscid wall boundary condition to    *
   !      * a block. It is assumed that the pointers in blockPointers are  *
   !      * already set to the correct block on the correct grid level.    *
   !      *                                                                *
   !      ******************************************************************
   !
   USE BLOCKPOINTERS
   USE BCTYPES
   USE CONSTANTS
   USE FLOWVARREFSTATE
   USE INPUTDISCRETIZATION
   USE INPUTPHYSICS
   USE ITERATION
   IMPLICIT NONE
   !
   !      Subroutine arguments.
   !
   LOGICAL, INTENT(IN) :: secondhalo, correctfork
   !
   !      Local variables.
   !
   INTEGER(kind=inttype) :: nn, j, k, l
   INTEGER(kind=inttype) :: jm1, jp1, km1, kp1
   INTEGER(kind=inttype) :: walltreatment
   REAL(kind=realtype) :: sixa, siya, siza, sjxa, sjya, sjza
   REAL(kind=realtype) :: sixad, siyad, sizad, sjxad, sjyad, sjzad
   REAL(kind=realtype) :: skxa, skya, skza, a1, b1
   REAL(kind=realtype) :: skxad, skyad, skzad
   REAL(kind=realtype) :: rxj, ryj, rzj, rxk, ryk, rzk
   REAL(kind=realtype) :: rxjd, ryjd, rzjd, rxkd, rykd, rzkd
   REAL(kind=realtype) :: dpj, dpk, ri, rj, rk, qj, qk, vn
   REAL(kind=realtype) :: dpjd, dpkd, rid, rjd, rkd, qjd, qkd, vnd
   REAL(kind=realtype) :: uux, uuy, uuz
   REAL(kind=realtype) :: uuxd, uuyd, uuzd
   REAL(kind=realtype), DIMENSION(imaxdim, jmaxdim, nw) :: ww1, ww2
   REAL(kind=realtype), DIMENSION(imaxdim, jmaxdim, nw) :: ww1d, ww2d
   REAL(kind=realtype), DIMENSION(imaxdim, jmaxdim) :: pp1, pp2
   REAL(kind=realtype), DIMENSION(imaxdim, jmaxdim) :: pp1d, pp2d
   REAL(kind=realtype), DIMENSION(imaxdim, jmaxdim) :: pp3, pp4
   REAL(kind=realtype), DIMENSION(imaxdim, jmaxdim) :: pp3d, pp4d
   REAL(kind=realtype), DIMENSION(imaxdim, jmaxdim) :: rlv1, rlv2
   REAL(kind=realtype), DIMENSION(imaxdim, jmaxdim) :: rlv1d, rlv2d
   REAL(kind=realtype), DIMENSION(imaxdim, jmaxdim) :: rev1, rev2
   REAL(kind=realtype), DIMENSION(imaxdim, jmaxdim) :: rev1d, rev2d
   REAL(kind=realtype), DIMENSION(imaxdim, jmaxdim, 3) :: ssi, ssj, ssk
   REAL(kind=realtype), DIMENSION(imaxdim, jmaxdim, 3) :: ssid, ssjd, &
   & sskd
   REAL(kind=realtype), DIMENSION(imaxdim, jmaxdim, 3) :: ss
   INTRINSIC MAX
   INTRINSIC MIN
   REAL(kind=realtype) :: DIM
   REAL(kind=realtype) :: tmp
   INTEGER :: ad_from
   INTEGER :: ad_to
   INTEGER :: ad_from0
   INTEGER :: ad_to0
   INTEGER :: ad_from1
   INTEGER :: ad_to1
   INTEGER :: ad_from2
   INTEGER :: ad_to2
   INTEGER :: ad_from3
   INTEGER :: ad_to3
   INTEGER :: ad_from4
   INTEGER :: ad_to4
   INTEGER :: ad_from5
   INTEGER :: ad_to5
   INTEGER :: ad_from6
   INTEGER :: ad_to6
   INTEGER :: branch
   INTEGER :: ad_from7
   INTEGER :: ad_to7
   INTEGER :: ad_from8
   INTEGER :: ad_to8
   REAL(kind=realtype) :: temp1
   REAL(kind=realtype) :: temp0
   REAL(kind=realtype) :: tmpd
   REAL(kind=realtype) :: tempd
   REAL(kind=realtype) :: tempd3
   REAL(kind=realtype) :: tempd2
   REAL(kind=realtype) :: tempd1
   REAL(kind=realtype) :: tempd0
   INTEGER :: ii1
   REAL(kind=realtype) :: temp
   INTEGER(kind=inttype) :: max2
   INTEGER(kind=inttype) :: max1
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Begin execution                                                *
   !      *                                                                *
   !      ******************************************************************
   !
   ! Make sure that on the coarser grids the constant pressure
   ! boundary condition is used.
   walltreatment = wallbctreatment
   IF (currentlevel .GT. groundlevel) walltreatment = constantpressure
   ! Loop over the boundary condition subfaces of this block.
   bocos:DO nn=1,nbocos
   ! Check for Euler wall boundary condition.
   IF (bctype(nn) .EQ. eulerwall) THEN
   ! Set the pointers for the unit normal and the normal
   ! velocity to make the code more readable.
   ! Modify to use actual pointer - Peter Lyu
   !norm  => BCData(nn)%norm
   !rface => BCData(nn)%rface
   ! Nullify the pointers and set them to the correct subface.
   ! They are nullified first, because some compilers require
   ! that.
   !nullify(ww1, ww2, pp1, pp2, rlv1, rlv2, rev1, rev2)
   CALL PUSHREAL8ARRAY(pp2, imaxdim*jmaxdim)
   CALL PUSHREAL8ARRAY(ww2, imaxdim*jmaxdim*nw)
   CALL SETBCPOINTERSBWD(nn, ww1, ww2, pp1, pp2, rlv1, rlv2, rev1&
   &                        , rev2, 0)
   !
   !          **************************************************************
   !          *                                                            *
   !          * Determine the boundary condition treatment and compute the *
   !          * undivided pressure gradient accordingly. This gradient is  *
   !          * temporarily stored in the halo pressure.                   *
   !          *                                                            *
   !          **************************************************************
   !
   SELECT CASE  (walltreatment) 
   CASE (constantpressure) 
   ad_from0 = bcdata(nn)%jcbeg
   ! Constant pressure. Set the gradient to zero.
   DO k=ad_from0,bcdata(nn)%jcend
   ad_from = bcdata(nn)%icbeg
   DO j=ad_from,bcdata(nn)%icend
   pp1(j, k) = zero
   END DO
   CALL PUSHINTEGER4(j - 1)
   CALL PUSHINTEGER4(ad_from)
   END DO
   CALL PUSHINTEGER4(k - 1)
   CALL PUSHINTEGER4(ad_from0)
   CALL PUSHCONTROL3B(3)
   CASE (linextrapolpressure) 
   !===========================================================
   ! Linear extrapolation. First set the additional pointer
   ! for pp3, depending on the block face.
   CALL SETPP3PP4BWD(nn, pp3, pp4)
   ad_from2 = bcdata(nn)%jcbeg
   ! Compute the gradient.
   DO k=ad_from2,bcdata(nn)%jcend
   ad_from1 = bcdata(nn)%icbeg
   DO j=ad_from1,bcdata(nn)%icend
   pp1(j, k) = pp3(j, k) - pp2(j, k)
   END DO
   CALL PUSHINTEGER4(j - 1)
   CALL PUSHINTEGER4(ad_from1)
   END DO
   CALL PUSHINTEGER4(k - 1)
   CALL PUSHINTEGER4(ad_from2)
   CALL PUSHREAL8ARRAY(p, SIZE(p, 1)*SIZE(p, 2)*SIZE(p, 3))
   CALL RESETPP3PP4BWD(nn, pp3, pp4)
   CALL PUSHCONTROL3B(2)
   CASE (quadextrapolpressure) 
   !===========================================================
   ! Quadratic extrapolation. First set the additional
   ! pointers for pp3 and pp4, depending on the block face.
   CALL SETPP3PP4BWD(nn, pp3, pp4)
   ad_from4 = bcdata(nn)%jcbeg
   ! Compute the gradient.
   DO k=ad_from4,bcdata(nn)%jcend
   ad_from3 = bcdata(nn)%icbeg
   DO j=ad_from3,bcdata(nn)%icend
   pp1(j, k) = two*pp3(j, k) - 1.5_realType*pp2(j, k) - half*&
   &             pp4(j, k)
   END DO
   CALL PUSHINTEGER4(j - 1)
   CALL PUSHINTEGER4(ad_from3)
   END DO
   CALL PUSHINTEGER4(k - 1)
   CALL PUSHINTEGER4(ad_from4)
   CALL PUSHREAL8ARRAY(p, SIZE(p, 1)*SIZE(p, 2)*SIZE(p, 3))
   CALL RESETPP3PP4BWD(nn, pp3, pp4)
   CALL PUSHCONTROL3B(1)
   CASE (normalmomentum) 
   !===========================================================
   ! Pressure gradient is computed using the normal momentum
   ! equation. First set a couple of additional variables for
   ! the normals, depending on the block face. Note that the
   ! construction 1: should not be used in these pointers,
   ! because element 0 is needed. Consequently there will be
   ! an offset of 1 for these normals. This is commented in
   ! the code. For moving faces also the grid velocity of
   ! the 1st cell center from the wall is needed.
   CALL SETSSBWD(nn, ssi, ssj, ssk, ss)
   ad_from6 = bcdata(nn)%jcbeg
   ! Loop over the faces of the generic subface.
   DO k=ad_from6,bcdata(nn)%jcend
   ! Store the indices k+1, k-1 a bit easier and make
   ! sure that they do not exceed the range of the arrays.
   CALL PUSHINTEGER4(km1)
   km1 = k - 1
   IF (bcdata(nn)%jcbeg .LT. km1) THEN
   km1 = km1
   ELSE
   km1 = bcdata(nn)%jcbeg
   END IF
   CALL PUSHINTEGER4(kp1)
   kp1 = k + 1
   IF (bcdata(nn)%jcend .GT. kp1) THEN
   kp1 = kp1
   ELSE
   kp1 = bcdata(nn)%jcend
   END IF
   IF (1_intType .LT. kp1 - km1) THEN
   max1 = kp1 - km1
   ELSE
   max1 = 1_intType
   END IF
   ! Compute the scaling factor for the central difference
   ! in the k-direction.
   CALL PUSHREAL8(b1)
   b1 = one/max1
   ad_from5 = bcdata(nn)%icbeg
   ! The j-loop.
   DO j=ad_from5,bcdata(nn)%icend
   ! The indices j+1 and j-1. Make sure that they
   ! do not exceed the range of the arrays.
   CALL PUSHINTEGER4(jm1)
   jm1 = j - 1
   IF (bcdata(nn)%icbeg .LT. jm1) THEN
   jm1 = jm1
   ELSE
   jm1 = bcdata(nn)%icbeg
   END IF
   CALL PUSHINTEGER4(jp1)
   jp1 = j + 1
   IF (bcdata(nn)%icend .GT. jp1) THEN
   jp1 = jp1
   ELSE
   jp1 = bcdata(nn)%icend
   END IF
   IF (1_intType .LT. jp1 - jm1) THEN
   max2 = jp1 - jm1
   ELSE
   max2 = 1_intType
   END IF
   ! Compute the scaling factor for the central
   ! difference in the j-direction.
   CALL PUSHREAL8(a1)
   a1 = one/max2
   ! Compute (twice) the average normal in the generic i,
   ! j and k-direction. Note that in j and k-direction
   ! the average in the original indices should be taken
   ! using j-1 and j (and k-1 and k). However due to the
   ! usage of pointers ssj and ssk there is an offset in
   ! the indices of 1 and therefore now the correct
   ! average is obtained with the indices j and j+1
   ! (k and k+1).
   CALL PUSHREAL8(sixa)
   sixa = two*ssi(j, k, 1)
   CALL PUSHREAL8(siya)
   siya = two*ssi(j, k, 2)
   CALL PUSHREAL8(siza)
   siza = two*ssi(j, k, 3)
   CALL PUSHREAL8(sjxa)
   sjxa = ssj(j, k, 1) + ssj(j+1, k, 1)
   CALL PUSHREAL8(sjya)
   sjya = ssj(j, k, 2) + ssj(j+1, k, 2)
   CALL PUSHREAL8(sjza)
   sjza = ssj(j, k, 3) + ssj(j+1, k, 3)
   CALL PUSHREAL8(skxa)
   skxa = ssk(j, k, 1) + ssk(j, k+1, 1)
   CALL PUSHREAL8(skya)
   skya = ssk(j, k, 2) + ssk(j, k+1, 2)
   CALL PUSHREAL8(skza)
   skza = ssk(j, k, 3) + ssk(j, k+1, 3)
   ! Compute the difference of the normal vector and
   ! pressure in j and k-direction. As the indices are
   ! restricted to the 1st halo-layer, the computation
   ! of the internal halo values is not consistent;
   ! however this is not really a problem, because these
   ! values are overwritten in the communication pattern.
   rxj = a1*(bcdata(nn)%norm(jp1, k, 1)-bcdata(nn)%norm(jm1, k&
   &             , 1))
   ryj = a1*(bcdata(nn)%norm(jp1, k, 2)-bcdata(nn)%norm(jm1, k&
   &             , 2))
   rzj = a1*(bcdata(nn)%norm(jp1, k, 3)-bcdata(nn)%norm(jm1, k&
   &             , 3))
   CALL PUSHREAL8(dpj)
   dpj = a1*(pp2(jp1, k)-pp2(jm1, k))
   rxk = b1*(bcdata(nn)%norm(j, kp1, 1)-bcdata(nn)%norm(j, km1&
   &             , 1))
   ryk = b1*(bcdata(nn)%norm(j, kp1, 2)-bcdata(nn)%norm(j, km1&
   &             , 2))
   rzk = b1*(bcdata(nn)%norm(j, kp1, 3)-bcdata(nn)%norm(j, km1&
   &             , 3))
   CALL PUSHREAL8(dpk)
   dpk = b1*(pp2(j, kp1)-pp2(j, km1))
   ! Compute the dot product between the unit vector
   ! and the normal vectors in i, j and k-direction.
   CALL PUSHREAL8(ri)
   ri = bcdata(nn)%norm(j, k, 1)*sixa + bcdata(nn)%norm(j, k, 2&
   &             )*siya + bcdata(nn)%norm(j, k, 3)*siza
   CALL PUSHREAL8(rj)
   rj = bcdata(nn)%norm(j, k, 1)*sjxa + bcdata(nn)%norm(j, k, 2&
   &             )*sjya + bcdata(nn)%norm(j, k, 3)*sjza
   CALL PUSHREAL8(rk)
   rk = bcdata(nn)%norm(j, k, 1)*skxa + bcdata(nn)%norm(j, k, 2&
   &             )*skya + bcdata(nn)%norm(j, k, 3)*skza
   ! Store the velocity components in ux, uy and uz and
   ! subtract the mesh velocity if the face is moving.
   CALL PUSHREAL8(uux)
   uux = ww2(j, k, ivx)
   CALL PUSHREAL8(uuy)
   uuy = ww2(j, k, ivy)
   CALL PUSHREAL8(uuz)
   uuz = ww2(j, k, ivz)
   IF (addgridvelocities) THEN
   uux = uux - ss(j, k, 1)
   uuy = uuy - ss(j, k, 2)
   uuz = uuz - ss(j, k, 3)
   END IF
   ! Compute the velocity components in j and
   ! k-direction.
   qj = uux*sjxa + uuy*sjya + uuz*sjza
   qk = uux*skxa + uuy*skya + uuz*skza
   ! Compute the pressure gradient, which is stored
   ! in pp1. I'm not entirely sure whether this
   ! formulation is correct for moving meshes. It could
   ! be that an additional term is needed there.
   pp1(j, k) = ((qj*(uux*rxj+uuy*ryj+uuz*rzj)+qk*(uux*rxk+uuy*&
   &             ryk+uuz*rzk))*ww2(j, k, irho)-rj*dpj-rk*dpk)/ri
   END DO
   CALL PUSHINTEGER4(j - 1)
   CALL PUSHINTEGER4(ad_from5)
   END DO
   CALL PUSHINTEGER4(k - 1)
   CALL PUSHINTEGER4(ad_from6)
   CALL RESETSSBWD(nn, ssi, ssj, ssk, ss)
   CALL PUSHCONTROL3B(0)
   CASE DEFAULT
   CALL PUSHCONTROL3B(4)
   END SELECT
   ad_from8 = bcdata(nn)%jcbeg
   ! Determine the state in the halo cell. Again loop over
   ! the cell range for this subface.
   DO k=ad_from8,bcdata(nn)%jcend
   ad_from7 = bcdata(nn)%icbeg
   DO j=ad_from7,bcdata(nn)%icend
   ! Compute the pressure density and velocity in the
   ! halo cell. Note that rface is the grid velocity
   ! component in the direction of norm, i.e. outward
   ! pointing.
   tmp = DIM(pp2(j, k), pp1(j, k))
   CALL PUSHREAL8(pp1(j, k))
   pp1(j, k) = tmp
   CALL PUSHREAL8(vn)
   vn = two*(bcdata(nn)%rface(j, k)-ww2(j, k, ivx)*bcdata(nn)%&
   &           norm(j, k, 1)-ww2(j, k, ivy)*bcdata(nn)%norm(j, k, 2)-ww2(j&
   &           , k, ivz)*bcdata(nn)%norm(j, k, 3))
   ww1(j, k, irho) = ww2(j, k, irho)
   ww1(j, k, ivx) = ww2(j, k, ivx) + vn*bcdata(nn)%norm(j, k, 1)
   ww1(j, k, ivy) = ww2(j, k, ivy) + vn*bcdata(nn)%norm(j, k, 2)
   ww1(j, k, ivz) = ww2(j, k, ivz) + vn*bcdata(nn)%norm(j, k, 3)
   ! Just copy the turbulent variables.
   DO l=nt1mg,nt2mg
   ww1(j, k, l) = ww2(j, k, l)
   END DO
   ! The laminar and eddy viscosity, if present.
   IF (viscous) THEN
   rlv1(j, k) = rlv2(j, k)
   CALL PUSHCONTROL1B(0)
   ELSE
   CALL PUSHCONTROL1B(1)
   END IF
   IF (eddymodel) THEN
   rev1(j, k) = rev2(j, k)
   CALL PUSHCONTROL1B(1)
   ELSE
   CALL PUSHCONTROL1B(0)
   END IF
   END DO
   CALL PUSHINTEGER4(j - 1)
   CALL PUSHINTEGER4(ad_from7)
   END DO
   CALL PUSHINTEGER4(k - 1)
   CALL PUSHINTEGER4(ad_from8)
   ! deallocation all pointer
   CALL PUSHREAL8ARRAY(p, SIZE(p, 1)*SIZE(p, 2)*SIZE(p, 3))
   CALL RESETBCPOINTERSBWD(nn, ww1, ww2, pp1, pp2, rlv1, rlv2, &
   &                          rev1, rev2, 0)
   ! Compute the energy for these halo's.
   CALL PUSHREAL8ARRAY(w, SIZE(w, 1)*SIZE(w, 2)*SIZE(w, 3)*SIZE(w, 4)&
   &                  )
   CALL COMPUTEETOT(icbeg(nn), icend(nn), jcbeg(nn), jcend(nn), &
   &                   kcbeg(nn), kcend(nn), correctfork)
   ! Extrapolate the state vectors in case a second halo
   ! is needed.
   IF (secondhalo) THEN
   CALL PUSHREAL8ARRAY(w, SIZE(w, 1)*SIZE(w, 2)*SIZE(w, 3)*SIZE(w, &
   &                     4))
   CALL PUSHREAL8ARRAY(p, SIZE(p, 1)*SIZE(p, 2)*SIZE(p, 3))
   CALL EXTRAPOLATE2NDHALO(nn, correctfork)
   CALL PUSHCONTROL2B(2)
   ELSE
   CALL PUSHCONTROL2B(1)
   END IF
   ELSE
   CALL PUSHCONTROL2B(0)
   END IF
   END DO bocos
   DO ii1=1,SIZE(bcdatad)
   bcdatad(ii1)%norm = 0.0_8
   END DO
   pp3d = 0.0_8
   pp4d = 0.0_8
   DO nn=nbocos,1,-1
   CALL POPCONTROL2B(branch)
   IF (branch .NE. 0) THEN
   IF (branch .NE. 1) THEN
   CALL POPREAL8ARRAY(p, SIZE(p, 1)*SIZE(p, 2)*SIZE(p, 3))
   CALL POPREAL8ARRAY(w, SIZE(w, 1)*SIZE(w, 2)*SIZE(w, 3)*SIZE(w, 4&
   &                    ))
   CALL EXTRAPOLATE2NDHALO_B(nn, correctfork)
   END IF
   CALL POPREAL8ARRAY(w, SIZE(w, 1)*SIZE(w, 2)*SIZE(w, 3)*SIZE(w, 4))
   CALL COMPUTEETOT_B(icbeg(nn), icend(nn), jcbeg(nn), jcend(nn), &
   &                  kcbeg(nn), kcend(nn), correctfork)
   CALL POPREAL8ARRAY(p, SIZE(p, 1)*SIZE(p, 2)*SIZE(p, 3))
   CALL RESETBCPOINTERSBWD_B(nn, ww1, ww1d, ww2, ww2d, pp1, pp1d, pp2&
   &                         , pp2d, rlv1, rlv1d, rlv2, rlv2d, rev1, rev1d&
   &                         , rev2, rev2d, 0)
   CALL POPINTEGER4(ad_from8)
   CALL POPINTEGER4(ad_to8)
   DO k=ad_to8,ad_from8,-1
   CALL POPINTEGER4(ad_from7)
   CALL POPINTEGER4(ad_to7)
   DO j=ad_to7,ad_from7,-1
   CALL POPCONTROL1B(branch)
   IF (branch .NE. 0) THEN
   rev2d(j, k) = rev2d(j, k) + rev1d(j, k)
   rev1d(j, k) = 0.0_8
   END IF
   CALL POPCONTROL1B(branch)
   IF (branch .EQ. 0) THEN
   rlv2d(j, k) = rlv2d(j, k) + rlv1d(j, k)
   rlv1d(j, k) = 0.0_8
   END IF
   DO l=nt2mg,nt1mg,-1
   ww2d(j, k, l) = ww2d(j, k, l) + ww1d(j, k, l)
   ww1d(j, k, l) = 0.0_8
   END DO
   ww2d(j, k, ivz) = ww2d(j, k, ivz) + ww1d(j, k, ivz)
   vnd = bcdata(nn)%norm(j, k, 3)*ww1d(j, k, ivz)
   bcdatad(nn)%norm(j, k, 3) = bcdatad(nn)%norm(j, k, 3) + vn*&
   &           ww1d(j, k, ivz)
   ww1d(j, k, ivz) = 0.0_8
   ww2d(j, k, ivy) = ww2d(j, k, ivy) + ww1d(j, k, ivy)
   vnd = vnd + bcdata(nn)%norm(j, k, 2)*ww1d(j, k, ivy)
   bcdatad(nn)%norm(j, k, 2) = bcdatad(nn)%norm(j, k, 2) + vn*&
   &           ww1d(j, k, ivy)
   ww1d(j, k, ivy) = 0.0_8
   ww2d(j, k, ivx) = ww2d(j, k, ivx) + ww1d(j, k, ivx)
   vnd = vnd + bcdata(nn)%norm(j, k, 1)*ww1d(j, k, ivx)
   bcdatad(nn)%norm(j, k, 1) = bcdatad(nn)%norm(j, k, 1) + vn*&
   &           ww1d(j, k, ivx)
   ww1d(j, k, ivx) = 0.0_8
   ww2d(j, k, irho) = ww2d(j, k, irho) + ww1d(j, k, irho)
   ww1d(j, k, irho) = 0.0_8
   CALL POPREAL8(vn)
   tempd3 = two*vnd
   ww2d(j, k, ivx) = ww2d(j, k, ivx) - bcdata(nn)%norm(j, k, 1)*&
   &           tempd3
   bcdatad(nn)%norm(j, k, 1) = bcdatad(nn)%norm(j, k, 1) - ww2(j&
   &           , k, ivx)*tempd3
   ww2d(j, k, ivy) = ww2d(j, k, ivy) - bcdata(nn)%norm(j, k, 2)*&
   &           tempd3
   bcdatad(nn)%norm(j, k, 2) = bcdatad(nn)%norm(j, k, 2) - ww2(j&
   &           , k, ivy)*tempd3
   ww2d(j, k, ivz) = ww2d(j, k, ivz) - bcdata(nn)%norm(j, k, 3)*&
   &           tempd3
   bcdatad(nn)%norm(j, k, 3) = bcdatad(nn)%norm(j, k, 3) - ww2(j&
   &           , k, ivz)*tempd3
   CALL POPREAL8(pp1(j, k))
   tmpd = pp1d(j, k)
   pp1d(j, k) = 0.0_8
   CALL DIM_B(pp2(j, k), pp2d(j, k), pp1(j, k), pp1d(j, k), tmpd)
   END DO
   END DO
   CALL POPCONTROL3B(branch)
   IF (branch .LT. 2) THEN
   IF (branch .EQ. 0) THEN
   CALL RESETSSBWD_B(nn, ssi, ssid, ssj, ssjd, ssk, sskd, ss)
   CALL POPINTEGER4(ad_from6)
   CALL POPINTEGER4(ad_to6)
   DO k=ad_to6,ad_from6,-1
   CALL POPINTEGER4(ad_from5)
   CALL POPINTEGER4(ad_to5)
   DO j=ad_to5,ad_from5,-1
   qj = uux*sjxa + uuy*sjya + uuz*sjza
   qk = uux*skxa + uuy*skya + uuz*skza
   ryj = a1*(bcdata(nn)%norm(jp1, k, 2)-bcdata(nn)%norm(jm1, &
   &               k, 2))
   ryk = b1*(bcdata(nn)%norm(j, kp1, 2)-bcdata(nn)%norm(j, &
   &               km1, 2))
   rzj = a1*(bcdata(nn)%norm(jp1, k, 3)-bcdata(nn)%norm(jm1, &
   &               k, 3))
   rzk = b1*(bcdata(nn)%norm(j, kp1, 3)-bcdata(nn)%norm(j, &
   &               km1, 3))
   rxj = a1*(bcdata(nn)%norm(jp1, k, 1)-bcdata(nn)%norm(jm1, &
   &               k, 1))
   rxk = b1*(bcdata(nn)%norm(j, kp1, 1)-bcdata(nn)%norm(j, &
   &               km1, 1))
   tempd = pp1d(j, k)/ri
   tempd0 = ww2(j, k, irho)*tempd
   temp0 = uux*rxj + uuy*ryj + uuz*rzj
   tempd1 = qj*tempd0
   temp1 = uux*rxk + uuy*ryk + uuz*rzk
   tempd2 = qk*tempd0
   temp = qj*temp0 + qk*temp1
   qjd = temp0*tempd0
   rxjd = uux*tempd1
   ryjd = uuy*tempd1
   rzjd = uuz*tempd1
   qkd = temp1*tempd0
   uuxd = skxa*qkd + sjxa*qjd + rxk*tempd2 + rxj*tempd1
   uuyd = skya*qkd + sjya*qjd + ryk*tempd2 + ryj*tempd1
   uuzd = skza*qkd + sjza*qjd + rzk*tempd2 + rzj*tempd1
   rxkd = uux*tempd2
   rykd = uuy*tempd2
   rzkd = uuz*tempd2
   ww2d(j, k, irho) = ww2d(j, k, irho) + temp*tempd
   rjd = -(dpj*tempd)
   dpjd = -(rj*tempd)
   rkd = -(dpk*tempd)
   dpkd = -(rk*tempd)
   rid = -((temp*ww2(j, k, irho)-rj*dpj-rk*dpk)*tempd/ri)
   pp1d(j, k) = 0.0_8
   skxad = uux*qkd
   skyad = uuy*qkd
   skzad = uuz*qkd
   sjxad = uux*qjd
   sjyad = uuy*qjd
   sjzad = uuz*qjd
   CALL POPREAL8(uuz)
   ww2d(j, k, ivz) = ww2d(j, k, ivz) + uuzd
   CALL POPREAL8(uuy)
   ww2d(j, k, ivy) = ww2d(j, k, ivy) + uuyd
   CALL POPREAL8(uux)
   ww2d(j, k, ivx) = ww2d(j, k, ivx) + uuxd
   CALL POPREAL8(rk)
   bcdatad(nn)%norm(j, k, 1) = bcdatad(nn)%norm(j, k, 1) + &
   &               skxa*rkd
   skxad = skxad + bcdata(nn)%norm(j, k, 1)*rkd
   bcdatad(nn)%norm(j, k, 2) = bcdatad(nn)%norm(j, k, 2) + &
   &               skya*rkd
   skyad = skyad + bcdata(nn)%norm(j, k, 2)*rkd
   bcdatad(nn)%norm(j, k, 3) = bcdatad(nn)%norm(j, k, 3) + &
   &               skza*rkd
   skzad = skzad + bcdata(nn)%norm(j, k, 3)*rkd
   CALL POPREAL8(rj)
   bcdatad(nn)%norm(j, k, 1) = bcdatad(nn)%norm(j, k, 1) + &
   &               sjxa*rjd
   sjxad = sjxad + bcdata(nn)%norm(j, k, 1)*rjd
   bcdatad(nn)%norm(j, k, 2) = bcdatad(nn)%norm(j, k, 2) + &
   &               sjya*rjd
   sjyad = sjyad + bcdata(nn)%norm(j, k, 2)*rjd
   bcdatad(nn)%norm(j, k, 3) = bcdatad(nn)%norm(j, k, 3) + &
   &               sjza*rjd
   sjzad = sjzad + bcdata(nn)%norm(j, k, 3)*rjd
   CALL POPREAL8(ri)
   bcdatad(nn)%norm(j, k, 1) = bcdatad(nn)%norm(j, k, 1) + &
   &               sixa*rid
   sixad = bcdata(nn)%norm(j, k, 1)*rid
   bcdatad(nn)%norm(j, k, 2) = bcdatad(nn)%norm(j, k, 2) + &
   &               siya*rid
   siyad = bcdata(nn)%norm(j, k, 2)*rid
   bcdatad(nn)%norm(j, k, 3) = bcdatad(nn)%norm(j, k, 3) + &
   &               siza*rid
   sizad = bcdata(nn)%norm(j, k, 3)*rid
   CALL POPREAL8(dpk)
   pp2d(j, kp1) = pp2d(j, kp1) + b1*dpkd
   pp2d(j, km1) = pp2d(j, km1) - b1*dpkd
   bcdatad(nn)%norm(j, kp1, 3) = bcdatad(nn)%norm(j, kp1, 3) &
   &               + b1*rzkd
   bcdatad(nn)%norm(j, km1, 3) = bcdatad(nn)%norm(j, km1, 3) &
   &               - b1*rzkd
   bcdatad(nn)%norm(j, kp1, 2) = bcdatad(nn)%norm(j, kp1, 2) &
   &               + b1*rykd
   bcdatad(nn)%norm(j, km1, 2) = bcdatad(nn)%norm(j, km1, 2) &
   &               - b1*rykd
   bcdatad(nn)%norm(j, kp1, 1) = bcdatad(nn)%norm(j, kp1, 1) &
   &               + b1*rxkd
   bcdatad(nn)%norm(j, km1, 1) = bcdatad(nn)%norm(j, km1, 1) &
   &               - b1*rxkd
   CALL POPREAL8(dpj)
   pp2d(jp1, k) = pp2d(jp1, k) + a1*dpjd
   pp2d(jm1, k) = pp2d(jm1, k) - a1*dpjd
   bcdatad(nn)%norm(jp1, k, 3) = bcdatad(nn)%norm(jp1, k, 3) &
   &               + a1*rzjd
   bcdatad(nn)%norm(jm1, k, 3) = bcdatad(nn)%norm(jm1, k, 3) &
   &               - a1*rzjd
   bcdatad(nn)%norm(jp1, k, 2) = bcdatad(nn)%norm(jp1, k, 2) &
   &               + a1*ryjd
   bcdatad(nn)%norm(jm1, k, 2) = bcdatad(nn)%norm(jm1, k, 2) &
   &               - a1*ryjd
   bcdatad(nn)%norm(jp1, k, 1) = bcdatad(nn)%norm(jp1, k, 1) &
   &               + a1*rxjd
   bcdatad(nn)%norm(jm1, k, 1) = bcdatad(nn)%norm(jm1, k, 1) &
   &               - a1*rxjd
   CALL POPREAL8(skza)
   sskd(j, k, 3) = sskd(j, k, 3) + skzad
   sskd(j, k+1, 3) = sskd(j, k+1, 3) + skzad
   CALL POPREAL8(skya)
   sskd(j, k, 2) = sskd(j, k, 2) + skyad
   sskd(j, k+1, 2) = sskd(j, k+1, 2) + skyad
   CALL POPREAL8(skxa)
   sskd(j, k, 1) = sskd(j, k, 1) + skxad
   sskd(j, k+1, 1) = sskd(j, k+1, 1) + skxad
   CALL POPREAL8(sjza)
   ssjd(j, k, 3) = ssjd(j, k, 3) + sjzad
   ssjd(j+1, k, 3) = ssjd(j+1, k, 3) + sjzad
   CALL POPREAL8(sjya)
   ssjd(j, k, 2) = ssjd(j, k, 2) + sjyad
   ssjd(j+1, k, 2) = ssjd(j+1, k, 2) + sjyad
   CALL POPREAL8(sjxa)
   ssjd(j, k, 1) = ssjd(j, k, 1) + sjxad
   ssjd(j+1, k, 1) = ssjd(j+1, k, 1) + sjxad
   CALL POPREAL8(siza)
   ssid(j, k, 3) = ssid(j, k, 3) + two*sizad
   CALL POPREAL8(siya)
   ssid(j, k, 2) = ssid(j, k, 2) + two*siyad
   CALL POPREAL8(sixa)
   ssid(j, k, 1) = ssid(j, k, 1) + two*sixad
   CALL POPREAL8(a1)
   CALL POPINTEGER4(jp1)
   CALL POPINTEGER4(jm1)
   END DO
   CALL POPREAL8(b1)
   CALL POPINTEGER4(kp1)
   CALL POPINTEGER4(km1)
   END DO
   CALL SETSSBWD_B(nn, ssi, ssid, ssj, ssjd, ssk, sskd, ss)
   ELSE
   CALL POPREAL8ARRAY(p, SIZE(p, 1)*SIZE(p, 2)*SIZE(p, 3))
   CALL RESETPP3PP4BWD_B(nn, pp3, pp3d, pp4, pp4d)
   CALL POPINTEGER4(ad_from4)
   CALL POPINTEGER4(ad_to4)
   DO k=ad_to4,ad_from4,-1
   CALL POPINTEGER4(ad_from3)
   CALL POPINTEGER4(ad_to3)
   DO j=ad_to3,ad_from3,-1
   pp3d(j, k) = pp3d(j, k) + two*pp1d(j, k)
   pp2d(j, k) = pp2d(j, k) - 1.5_realType*pp1d(j, k)
   pp4d(j, k) = pp4d(j, k) - half*pp1d(j, k)
   pp1d(j, k) = 0.0_8
   END DO
   END DO
   CALL SETPP3PP4BWD_B(nn, pp3, pp3d, pp4, pp4d)
   END IF
   ELSE IF (branch .EQ. 2) THEN
   CALL POPREAL8ARRAY(p, SIZE(p, 1)*SIZE(p, 2)*SIZE(p, 3))
   CALL RESETPP3PP4BWD_B(nn, pp3, pp3d, pp4, pp4d)
   CALL POPINTEGER4(ad_from2)
   CALL POPINTEGER4(ad_to2)
   DO k=ad_to2,ad_from2,-1
   CALL POPINTEGER4(ad_from1)
   CALL POPINTEGER4(ad_to1)
   DO j=ad_to1,ad_from1,-1
   pp3d(j, k) = pp3d(j, k) + pp1d(j, k)
   pp2d(j, k) = pp2d(j, k) - pp1d(j, k)
   pp1d(j, k) = 0.0_8
   END DO
   END DO
   CALL SETPP3PP4BWD_B(nn, pp3, pp3d, pp4, pp4d)
   ELSE IF (branch .EQ. 3) THEN
   CALL POPINTEGER4(ad_from0)
   CALL POPINTEGER4(ad_to0)
   DO k=ad_to0,ad_from0,-1
   CALL POPINTEGER4(ad_from)
   CALL POPINTEGER4(ad_to)
   DO j=ad_to,ad_from,-1
   pp1d(j, k) = 0.0_8
   END DO
   END DO
   END IF
   CALL POPREAL8ARRAY(ww2, imaxdim*jmaxdim*nw)
   CALL POPREAL8ARRAY(pp2, imaxdim*jmaxdim)
   CALL SETBCPOINTERSBWD_B(nn, ww1, ww1d, ww2, ww2d, pp1, pp1d, pp2, &
   &                       pp2d, rlv1, rlv1d, rlv2, rlv2d, rev1, rev1d, &
   &                       rev2, rev2d, 0)
   END IF
   END DO
   END SUBROUTINE BCEULERWALL_B