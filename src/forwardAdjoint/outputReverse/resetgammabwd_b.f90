   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.10 (r5363) -  9 Sep 2014 09:53
   !
   !  Differentiation of resetgammabwd in reverse (adjoint) mode (with options i4 dr8 r8 noISIZE):
   !   gradient     of useful results: *gamma gamma1 gamma2
   !   with respect to varying inputs: *gamma gamma1 gamma2
   !   Plus diff mem management of: gamma:in
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          resetgammaBwd.f90                               *
   !      * Author:        Peter Zhoujie Lyu                               *
   !      * Starting date: 10-21-2014                                      *
   !      * Last modified: 10-21-2014                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   SUBROUTINE RESETGAMMABWD_B(nn, gamma1, gamma1d, gamma2, gamma2d)
   USE BCTYPES
   USE BLOCKPOINTERS
   USE FLOWVARREFSTATE
   IMPLICIT NONE
   !
   !      Subroutine arguments.
   !
   INTEGER(kind=inttype), INTENT(IN) :: nn
   REAL(kind=realtype), DIMENSION(imaxdim, jmaxdim) :: gamma1, gamma2
   REAL(kind=realtype), DIMENSION(imaxdim, jmaxdim) :: gamma1d, gamma2d
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Begin execution                                                *
   !      *                                                                *
   !      ******************************************************************
   !
   ! Determine the face id on which the subface is located and set
   ! the pointers accordinly.
   SELECT CASE  (bcfaceid(nn)) 
   CASE (imin) 
   gamma2d(1:je, 1:ke) = gamma2d(1:je, 1:ke) + gammad(2, 1:je, 1:ke)
   gammad(2, 1:je, 1:ke) = 0.0_8
   gamma1d(1:je, 1:ke) = gamma1d(1:je, 1:ke) + gammad(1, 1:je, 1:ke)
   gammad(1, 1:je, 1:ke) = 0.0_8
   CASE (imax) 
   gamma2d(1:je, 1:ke) = gamma2d(1:je, 1:ke) + gammad(il, 1:je, 1:ke)
   gammad(il, 1:je, 1:ke) = 0.0_8
   gamma1d(1:je, 1:ke) = gamma1d(1:je, 1:ke) + gammad(ie, 1:je, 1:ke)
   gammad(ie, 1:je, 1:ke) = 0.0_8
   CASE (jmin) 
   gamma2d(1:ie, 1:ke) = gamma2d(1:ie, 1:ke) + gammad(1:ie, 2, 1:ke)
   gammad(1:ie, 2, 1:ke) = 0.0_8
   gamma1d(1:ie, 1:ke) = gamma1d(1:ie, 1:ke) + gammad(1:ie, 1, 1:ke)
   gammad(1:ie, 1, 1:ke) = 0.0_8
   CASE (jmax) 
   gamma2d(1:ie, 1:ke) = gamma2d(1:ie, 1:ke) + gammad(1:ie, jl, 1:ke)
   gammad(1:ie, jl, 1:ke) = 0.0_8
   gamma1d(1:ie, 1:ke) = gamma1d(1:ie, 1:ke) + gammad(1:ie, je, 1:ke)
   gammad(1:ie, je, 1:ke) = 0.0_8
   CASE (kmin) 
   gamma2d(1:ie, 1:je) = gamma2d(1:ie, 1:je) + gammad(1:ie, 1:je, 2)
   gammad(1:ie, 1:je, 2) = 0.0_8
   gamma1d(1:ie, 1:je) = gamma1d(1:ie, 1:je) + gammad(1:ie, 1:je, 1)
   gammad(1:ie, 1:je, 1) = 0.0_8
   CASE (kmax) 
   gamma2d(1:ie, 1:je) = gamma2d(1:ie, 1:je) + gammad(1:ie, 1:je, kl)
   gammad(1:ie, 1:je, kl) = 0.0_8
   gamma1d(1:ie, 1:je) = gamma1d(1:ie, 1:je) + gammad(1:ie, 1:je, ke)
   gammad(1:ie, 1:je, ke) = 0.0_8
   END SELECT
   END SUBROUTINE RESETGAMMABWD_B