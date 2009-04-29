!
!      ******************************************************************
!      *                                                                *
!      * File:          gridVelocitiesFineLevelForcesAdj.f90            *
!      * Author:        Edwin van der Weide,C.A.(Sandy) Mader           *
!      * Starting date: 02-23-2004                                      *
!      * Last modified: 10-22-2008                                      *
!      *                                                                *
!      ******************************************************************
!
       subroutine gridVelocitiesFineLevelForcesAdj(useOldCoor, t, sps,xAdj,sAdj,&
            iiBeg,iiEnd,jjBeg,jjEnd,i2Beg,i2End,j2Beg,j2End,mm,&
            sFaceIAdj,sFaceJAdj,sFaceKAdj,&
            machGridAdj,velDirFreestreamAdj,&
            rotCenterAdj, rotRateAdj,siAdj,sjAdj,skAdj)
!
!      ******************************************************************
!      *                                                                *
!      * gridVelocitiesFineLevel computes the grid velocities for       *
!      * the cell centers and the normal grid velocities for the faces  *
!      * of moving blocks for the currently finest grid, i.e.           *
!      * groundLevel. The velocities are computed at time t for         *
!      * spectral mode sps. If useOldCoor is .true. the velocities      *
!      * are determined using the unsteady time integrator in           *
!      * combination with the old coordinates; otherwise the analytic   *
!      * form is used.                                                  *
!      *                                                                *
!      ******************************************************************
!
       use blockPointers
       use cgnsGrid
       use flowVarRefState
       use inputMotion
       use inputUnsteady
       use iteration
       use BCTypes     !imin,imax,etc.
       implicit none
!
!      Subroutine arguments.
!

       integer(kind=intType) :: iiBeg,iiEnd,jjBeg,jjEnd
       integer(kind=intType) :: i2Beg,i2End,j2Beg,j2End

       integer(kind=intType), intent(in) :: sps
       logical,               intent(in) :: useOldCoor

       real(kind=realType), dimension(*), intent(in) :: t
       real(kind=realType), dimension(3), intent(in) :: rotCenterAdj, rotRateAdj
       
       real(kind=realType), dimension(0:ie,0:je,0:ke,3),intent(in) :: xAdj
       real(kind=realType), dimension(0:ie,0:je,0:ke,3),intent(out) :: sAdj

       real(kind=realType), dimension(1:2,iiBeg:iiEnd,jjBeg:jjEnd,3),intent(in) :: siAdj
       real(kind=realType), dimension(iiBeg:iiEnd,1:2,jjBeg:jjEnd,3),intent(in) :: sjAdj
       real(kind=realType), dimension(iiBeg:iiEnd,jjBeg:jjEnd,1:2,3),intent(in) :: skAdj

       real(kind=realType), dimension(1:2,iiBeg:iiEnd,jjBeg:jjEnd) :: sFaceiAdj
       real(kind=realType), dimension(iiBeg:iiEnd,1:2,jjBeg:jjEnd) :: sFacejAdj
       real(kind=realType), dimension(iiBeg:iiEnd,jjBeg:jjEnd,1:2) :: sFacekAdj
       
       real(kind=realType),intent(in):: machGridAdj
       real(kind=realType),dimension(3),intent(in):: velDirFreestreamAdj
!
!      Local variables.
!
       integer(kind=intType) :: nn, mm
       integer(kind=intType) :: i, j, k, ii, iie, jje, kke

       real(kind=realType) :: oneOver4dt, oneOver8dt
       real(kind=realType) :: velxGrid, velyGrid, velzGrid,aInf

       real(kind=realType), dimension(3) :: sc, xc, xxc

       real(kind=realType), dimension(3)   :: rotationPointAdj,rotPointAdj
       real(kind=realType), dimension(3,3) :: rotationMatrixAdj
       
       real(kind=realType), dimension(iiBeg-1:iiEnd,jjBeg-1:jjEnd,3) :: xxAdj
       real(kind=realType), dimension(iiBeg:iiEnd,jjBeg:jjEnd,3) :: ssAdj
       real(kind=realType), dimension(iiBeg:iiEnd,jjBeg:jjEnd) :: sFaceAdj
      

       !real(kind=realType), dimension(:,:), pointer :: sFace

!       real(kind=realType), dimension(:,:,:),   pointer :: xx, ss
!       real(kind=realType), dimension(:,:,:,:), pointer :: xxOld
!
!      ******************************************************************
!      *                                                                *
!      * Begin execution                                                *
!      *                                                                *
!      ******************************************************************
!
       ! Compute the mesh velocity from the given mesh Mach number.
       !print *,'in gridvelocities',mm

    !  aInf = sqrt(gammaInf*pInf/rhoInf)
    !  velxGrid = aInf*MachGrid(1)
    !  velyGrid = aInf*MachGrid(2)
    !  velzGrid = aInf*MachGrid(3)

      ! velxGrid = zero
      ! velyGrid = zero
      ! velzGrid = zero

       aInf = sqrt(gammaInf*pInf/rhoInf)
       velxGrid = aInf*machgridAdj*-velDirFreestreamAdj(1)
       velyGrid = aInf*machgridAdj*-velDirFreestreamAdj(2) 
       velzGrid = aInf*machgridAdj*-velDirFreestreamAdj(3) 


       ! Compute the derivative of the rotation matrix and the rotation
       ! point; needed for velocity due to the rigid body rotation of
       ! the entire grid. It is assumed that the rigid body motion of
       ! the grid is only specified if there is only 1 section present.

       call derivativeRotMatrixRigidForcesAdj(rotationMatrixAdj, rotationPointAdj,rotPointAdj, t(1))

!moved outside
!!$       ! Loop over the number of local blocks.
!!$
!!$       domains: do nn=1,nDom
!!$
!!$         ! Set the pointers for this block.
!!$
!!$         call setPointers(nn, groundLevel, sps)

         ! Check for a moving block.

         testMoving: if( blockIsMoving ) then

           ! Determine the situation we are having here.

           testUseOldCoor: if( useOldCoor ) then
              
              print *,'arbitrary mesh movement not yet supported in the ADjoint'
              call terminate()
!!$!
!!$!            ************************************************************
!!$!            *                                                          *
!!$!            * The velocities must be determined via a finite           *
!!$!            * difference formula using the coordinates of the old      *
!!$!            * levels.                                                  *
!!$!            *                                                          *
!!$!            ************************************************************
!!$!
!!$             ! Set the coefficients for the time integrator and store
!!$             ! the inverse of the physical nonDimensional time step,
!!$             ! divided by 4 and 8, a bit easier.
!!$
!!$             call setCoefTimeIntegrator
!!$             oneOver4dt = fourth*timeRef/deltaT
!!$             oneOver8dt = half*oneOver4dt
!!$!
!!$!            ************************************************************
!!$!            *                                                          *
!!$!            * Grid velocities of the cell centers, including the       *
!!$!            * 1st level halo cells.                                    *
!!$!            *                                                          *
!!$!            ************************************************************
!!$!
!!$             ! Loop over the cells, including the 1st level halo's.
!!$
!!$             do k=1,ke
!!$               do j=1,je
!!$                 do i=1,ie
!!$
!!$                   ! The velocity of the cell center is determined
!!$                   ! by a finite difference formula. First store
!!$                   ! the current coordinate, multiplied by 8 and
!!$                   ! coefTime(0) in sc.
!!$
!!$                   sc(1) = (x(i-1,j-1,k-1,1) + x(i,j-1,k-1,1)  &
!!$                         +  x(i-1,j,  k-1,1) + x(i,j,  k-1,1)  &
!!$                         +  x(i-1,j-1,k,  1) + x(i,j-1,k,  1)  &
!!$                         +  x(i-1,j,  k,  1) + x(i,j,  k,  1)) &
!!$                         * coefTime(0)
!!$                   sc(2) = (x(i-1,j-1,k-1,2) + x(i,j-1,k-1,2)  &
!!$                         +  x(i-1,j,  k-1,2) + x(i,j,  k-1,2)  &
!!$                         +  x(i-1,j-1,k,  2) + x(i,j-1,k,  2)  &
!!$                         +  x(i-1,j,  k,  2) + x(i,j,  k,  2)) &
!!$                         * coefTime(0)
!!$                   sc(3) = (x(i-1,j-1,k-1,3) + x(i,j-1,k-1,3)  &
!!$                         +  x(i-1,j,  k-1,3) + x(i,j,  k-1,3)  &
!!$                         +  x(i-1,j-1,k,  3) + x(i,j-1,k,  3)  &
!!$                         +  x(i-1,j,  k,  3) + x(i,j,  k,  3)) &
!!$                         * coefTime(0)
!!$
!!$                   ! Loop over the older levels to complete the
!!$                   ! finite difference formula.
!!$
!!$                   do ii=1,nOldLevels
!!$                     sc(1) = sc(1) + (xOld(ii,i-1,j-1,k-1,1)  &
!!$                           +          xOld(ii,i,  j-1,k-1,1)  &
!!$                           +          xOld(ii,i-1,j,  k-1,1)  &
!!$                           +          xOld(ii,i,  j,  k-1,1)  &
!!$                           +          xOld(ii,i-1,j-1,k,  1)  &
!!$                           +          xOld(ii,i,  j-1,k,  1)  &
!!$                           +          xOld(ii,i-1,j,  k,  1)  &
!!$                           +          xOld(ii,i,  j,  k,  1)) &
!!$                           * coefTime(ii)
!!$                     sc(2) = sc(2) + (xOld(ii,i-1,j-1,k-1,2)  &
!!$                           +          xOld(ii,i,  j-1,k-1,2)  &
!!$                           +          xOld(ii,i-1,j,  k-1,2)  &
!!$                           +          xOld(ii,i,  j,  k-1,2)  &
!!$                           +          xOld(ii,i-1,j-1,k,  2)  &
!!$                           +          xOld(ii,i,  j-1,k,  2)  &
!!$                           +          xOld(ii,i-1,j,  k,  2)  &
!!$                           +          xOld(ii,i,  j,  k,  2)) &
!!$                           * coefTime(ii)
!!$                     sc(3) = sc(3) + (xOld(ii,i-1,j-1,k-1,3)  &
!!$                           +          xOld(ii,i,  j-1,k-1,3)  &
!!$                           +          xOld(ii,i-1,j,  k-1,3)  &
!!$                           +          xOld(ii,i,  j,  k-1,3)  &
!!$                           +          xOld(ii,i-1,j-1,k,  3)  &
!!$                           +          xOld(ii,i,  j-1,k,  3)  &
!!$                           +          xOld(ii,i-1,j,  k,  3)  &
!!$                           +          xOld(ii,i,  j,  k,  3)) &
!!$                           * coefTime(ii)
!!$                   enddo
!!$
!!$                   ! Divide by 8 delta t to obtain the correct
!!$                   ! velocities.
!!$
!!$                   s(i,j,k,1) = sc(1)*oneOver8dt
!!$                   s(i,j,k,2) = sc(2)*oneOver8dt
!!$                   s(i,j,k,3) = sc(3)*oneOver8dt
!!$
!!$                 enddo
!!$               enddo
!!$             enddo
!!$!
!!$!            ************************************************************
!!$!            *                                                          *
!!$!            * Normal grid velocities of the faces.                     *
!!$!            *                                                          *
!!$!            ************************************************************
!!$!
!!$             ! Loop over the three directions.
!!$
!!$             loopDir: do mm=1,3
!!$
!!$               ! Set the upper boundaries depending on the direction.
!!$
!!$               select case (mm)
!!$                 case (1_intType)       ! normals in i-direction
!!$                   iie = ie; jje = je; kke = ke
!!$
!!$                 case (2_intType)       ! normals in j-direction
!!$                   iie = je; jje = ie; kke = ke
!!$
!!$                 case (3_intType)       ! normals in k-direction
!!$                   iie = ke; jje = ie; kke = je
!!$               end select
!!$!
!!$!              **********************************************************
!!$!              *                                                        *
!!$!              * Normal grid velocities in generalized i-direction.     *
!!$!              * Mm == 1: i-direction                                   *
!!$!              * mm == 2: j-direction                                   *
!!$!              * mm == 3: k-direction                                   *
!!$!              *                                                        *
!!$!              **********************************************************
!!$!
!!$               do i=0,iie
!!$
!!$                 ! Set the pointers for the coordinates, normals and
!!$                 ! normal velocities for this generalized i-plane.
!!$                 ! This depends on the value of mm.
!!$
!!$                 select case (mm)
!!$                   case (1_intType)       ! normals in i-direction
!!$                     xx =>  x(i,:,:,:);  xxOld => xOld(:,i,:,:,:)
!!$                     ss => si(i,:,:,:);  sFace => sFaceI(i,:,:)
!!$
!!$                   case (2_intType)       ! normals in j-direction
!!$                     xx =>  x(:,i,:,:);  xxOld => xOld(:,:,i,:,:)
!!$                     ss => sj(:,i,:,:);  sFace => sFaceJ(:,i,:)
!!$
!!$                   case (3_intType)       ! normals in k-direction
!!$                     xx =>  x(:,:,i,:);  xxOld => xOld(:,:,:,i,:)
!!$                     ss => sk(:,:,i,:);  sFace => sFaceK(:,:,i)
!!$                 end select
!!$
!!$                 ! Loop over the k and j-direction of this
!!$                 ! generalized i-face. Note that due to the usage of
!!$                 ! the pointers xx and xxOld an offset of +1 must be
!!$                 ! used in the coordinate arrays, because x and xOld
!!$                 ! originally start at 0 for the i, j and k indices.
!!$
!!$                 do k=1,kke
!!$                   do j=1,jje
!!$
!!$                     ! The velocity of the face center is determined
!!$                     ! by a finite difference formula. First store
!!$                     ! the current coordinate, multiplied by 4 and
!!$                     ! coefTime(0) in sc.
!!$
!!$                     sc(1) = coefTime(0)*(xx(j+1,k+1,1) + xx(j,k+1,1) &
!!$                           +              xx(j+1,k,  1) + xx(j,k,  1))
!!$                     sc(2) = coefTime(0)*(xx(j+1,k+1,2) + xx(j,k+1,2) &
!!$                           +              xx(j+1,k,  2) + xx(j,k,  2))
!!$                     sc(3) = coefTime(0)*(xx(j+1,k+1,3) + xx(j,k+1,3) &
!!$                           +              xx(j+1,k,  3) + xx(j,k,  3))
!!$
!!$                     ! Loop over the older levels to complete the
!!$                     ! finite difference.
!!$
!!$                     do ii=1,nOldLevels
!!$
!!$                       sc(1) = sc(1) + coefTime(ii)         &
!!$                             *         (xxOld(ii,j+1,k+1,1) &
!!$                             +          xxOld(ii,j,  k+1,1) &
!!$                             +          xxOld(ii,j+1,k,  1) &
!!$                             +          xxOld(ii,j,  k,  1))
!!$                       sc(2) = sc(2) + coefTime(ii)         &
!!$                             *         (xxOld(ii,j+1,k+1,2) &
!!$                             +          xxOld(ii,j,  k+1,2) &
!!$                             +          xxOld(ii,j+1,k,  2) &
!!$                             +          xxOld(ii,j,  k,  2))
!!$                       sc(3) = sc(3) + coefTime(ii)         &
!!$                             *         (xxOld(ii,j+1,k+1,3) &
!!$                             +          xxOld(ii,j,  k+1,3) &
!!$                             +          xxOld(ii,j+1,k,  3) &
!!$                             +          xxOld(ii,j,  k,  3))
!!$                     enddo
!!$
!!$                     ! Determine the dot product of sc and the normal
!!$                     ! and divide by 4 deltaT to obtain the correct
!!$                     ! value of the normal velocity.
!!$
!!$                     sFace(j,k) = sc(1)*ss(j,k,1) + sc(2)*ss(j,k,2) &
!!$                                + sc(3)*ss(j,k,3)
!!$                     sFace(j,k) = sFace(j,k)*oneOver4dt
!!$
!!$                   enddo
!!$                 enddo
!!$               enddo
!!$
!!$             enddo loopDir

           else testUseOldCoor
!
!            ************************************************************
!            *                                                          *
!            * The velocities must be determined analytically.          *
!            *                                                          *
!            ************************************************************
!

             !!! Pass these in, set them in copyADjointStencil.f90
!!$
!!$             ! Store the rotation center and determine the
!!$             ! nonDimensional rotation rate of this block. As the
!!$             ! reference length is 1 timeRef == 1/uRef and at the end
!!$             ! the nonDimensional velocity is computed.
!!$
!!$             j = nbkGlobal
!!$
!!$             rotCenter = cgnsDoms(j)%rotCenter
!!$             rotRate   = timeRef*cgnsDoms(j)%rotRate

             !subtract off the rotational velocity of the center of the grid
             ! to account for the added overall velocity.
             velxGrid =velxgrid+ 1*(rotRateAdj(2)*rotCenterAdj(3) - rotRateAdj(3)*rotCenterAdj(2))
             velyGrid =velygrid+ 1*(rotRateAdj(3)*rotCenterAdj(1) - rotRateAdj(1)*rotCenterAdj(3))
             velzGrid =velzgrid+ 1*(rotRateAdj(1)*rotCenterAdj(2) - rotRateAdj(2)*rotCenterAdj(1))


!
!            ************************************************************
!            *                                                          *
!            * Grid velocities of the cell centers, including the       *
!            * 1st level halo cells.                                    *
!            *                                                          *
!            ************************************************************
!
             ! Loop over the cells, including the 1st level halo's.
             ! print *,'calculating grid velocities',ie,je,ke,shape(xadj)
             do k=1,ke
               do j=1,je
                 do i=1,ie

                   ! Determine the coordinates of the cell center,
                   ! which are stored in xc.

                   xc(1) = eighth*(xAdj(i-1,j-1,k-1,1) + xAdj(i,j-1,k-1,1) &
                         +         xAdj(i-1,j,  k-1,1) + xAdj(i,j,  k-1,1) &
                         +         xAdj(i-1,j-1,k,  1) + xAdj(i,j-1,k,  1) &
                         +         xAdj(i-1,j,  k,  1) + xAdj(i,j,  k,  1))
                   xc(2) = eighth*(xAdj(i-1,j-1,k-1,2) + xAdj(i,j-1,k-1,2) &
                         +         xAdj(i-1,j,  k-1,2) + xAdj(i,j,  k-1,2) &
                         +         xAdj(i-1,j-1,k,  2) + xAdj(i,j-1,k,  2) &
                         +         xAdj(i-1,j,  k,  2) + xAdj(i,j,  k,  2))
                   xc(3) = eighth*(xAdj(i-1,j-1,k-1,3) + xAdj(i,j-1,k-1,3) &
                         +         xAdj(i-1,j,  k-1,3) + xAdj(i,j,  k-1,3) &
                         +         xAdj(i-1,j-1,k,  3) + xAdj(i,j-1,k,  3) &
                         +         xAdj(i-1,j,  k,  3) + xAdj(i,j,  k,  3))

                   ! Determine the coordinates relative to the
                   ! center of rotation.

                   xxc(1) = xc(1) - rotCenterAdj(1)
                   xxc(2) = xc(2) - rotCenterAdj(2)
                   xxc(3) = xc(3) - rotCenterAdj(3)

                   ! Determine the rotation speed of the cell center,
                   ! which is omega*r.

                   sc(1) = rotRateAdj(2)*xxc(3) - rotRateAdj(3)*xxc(2)
                   sc(2) = rotRateAdj(3)*xxc(1) - rotRateAdj(1)*xxc(3)
                   sc(3) = rotRateAdj(1)*xxc(2) - rotRateAdj(2)*xxc(1)

                   ! Determine the coordinates relative to the
                   ! rigid body rotation point.

                   xxc(1) = xc(1) - rotationPointAdj(1)
                   xxc(2) = xc(2) - rotationPointAdj(2)
                   xxc(3) = xc(3) - rotationPointAdj(3)

                   ! Determine the total velocity of the cell center.
                   ! This is a combination of rotation speed of this
                   ! block and the entire rigid body rotation.

                   sAdj(i,j,k,1) = sc(1) + velxGrid           &
                              + rotationMatrixAdj(1,1)*xxc(1) &
                              + rotationMatrixAdj(1,2)*xxc(2) &
                              + rotationMatrixAdj(1,3)*xxc(3)
                   sAdj(i,j,k,2) = sc(2) + velyGrid           &
                              + rotationMatrixAdj(2,1)*xxc(1) &
                              + rotationMatrixAdj(2,2)*xxc(2) &
                              + rotationMatrixAdj(2,3)*xxc(3)
                   sAdj(i,j,k,3) = sc(3) + velzGrid           &
                              + rotationMatrixAdj(3,1)*xxc(1) &
                              + rotationMatrixAdj(3,2)*xxc(2) &
                              + rotationMatrixAdj(3,3)*xxc(3)
                 enddo
               enddo
             enddo
!
!            ************************************************************
!            *                                                          *
!            * Normal grid velocities of the faces.                     *
!            *                                                          *
!            ************************************************************
!
! this loop is equivalent to the BC loop. Thus mm is determined by the global mm.
!!$             ! Loop over the three directions.
!!$
!!$             loopDirection: do mm=1,3
             
             

               ! Set the upper boundaries depending on the direction.
             !print *,'mm1',mm
               select case (BCFaceID(mm))
               !case (1_intType)
               case (imin,imax)   ! Normals in i-direction
                  iie = ie; jje = je; kke = ke
                  
                  !case (2_intType)
               case (jmin,jmax)       ! Normals in j-direction
                  iie = je; jje = ie; kke = ke
                  
               !case (3_intType)
               case (kmin,kmax)      ! Normals in k-direction
                  iie = ke; jje = ie; kke = je
               end select
!
!              **********************************************************
!              *                                                        *
!              * Normal grid velocities in generalized i-direction.     *
!              * mm == 1: i-direction                                   *
!              * mm == 2: j-direction                                   *
!              * mm == 3: k-direction                                   *
!              *                                                        *
!              **********************************************************
!
               ii=1
               !do i=0,iie
               do i=1,iie,iie-1 ! 1 to iie in steps of iie-1
                 ! print *,'iie',i,iie,mm,jje,kke
                 ! Set the pointers for the coordinates, normals and
                 ! normal velocities for this generalized i-plane.
                 ! This depends on the value of mm.
                 !print *,'xindices',iibeg,iiend,0,ie
                 select case (BCFaceID(mm))
                 case (imin,imax)       ! normals in i-direction
                      !print *,'case1',i,shape(xxadj),shape(xadj)
                     !xxAdj =  xAdj(i,:,:,:)
                     xxAdj(iiBeg-1:iiEnd,jjBeg-1:jjEnd,:)=xAdj(i,iiBeg-1:iiEnd,jjBeg-1:jjEnd,:)
                     ssAdj = siAdj(ii,:,:,:)!;  sFaceAdj = sFaceIAdj(i,:,:)

                  case (jmin,jmax)      ! normals in j-direction
                      !print *,'i2',i,shape(xxadj),shape(xadj)
                     xxAdj(iiBeg-1:iiEnd,jjBeg-1:jjEnd,:) =  xAdj(iiBeg-1:iiEnd,i,jjBeg-1:jjEnd,:)
                     !print *,'indices',iiBeg,iiEnd,jjBeg,jjEnd
                     ssAdj = sjAdj(:,ii,:,:)!;  sFaceAdj = sFaceJAdj(:,i,:)

                  case (kmin,kmax)       ! normals in k-direction
                     !print *,'i3',i,shape(xxadj),shape(xadj)
                     xxAdj(iiBeg-1:iiEnd,jjBeg-1:jjEnd,:)=xAdj(iiBeg-1:iiEnd,jjBeg-1:jjEnd,i,:)
                     !xxAdj =  xAdj(:,:,i,:)
                     ssAdj = skAdj(:,:,ii,:)!;  sFaceAdj = sFaceKAdj(:,:,i)
                 end select
               
                 ! Loop over the k and j-direction of this generalized
                 ! i-face. Note that due to the usage of the pointer
                 ! xx an offset of +1 must be used in the coordinate
                 ! array, because x originally starts at 0 for the
                 ! i, j and k indices.

                 do k=jjBeg,jjEnd!1,kke
                   do j=iiBeg,iiEnd!1,jje
                      !print *,'j',j,jje,'k',k,kke
                     ! Determine the coordinates of the face center,
                     ! which are stored in xc.

!!$                     xc(1) = fourth*(xxAdj(j+1,k+1,1) + xxAdj(j,k+1,1) &
!!$                           +         xxAdj(j+1,k,  1) + xxAdj(j,k,  1))
!!$                     xc(2) = fourth*(xxAdj(j+1,k+1,2) + xxAdj(j,k+1,2) &
!!$                           +         xxAdj(j+1,k,  2) + xxAdj(j,k,  2))
!!$                     xc(3) = fourth*(xxAdj(j+1,k+1,3) + xxAdj(j,k+1,3) &
!!$                           +         xxAdj(j+1,k,  3) + xxAdj(j,k,  3))
                     xc(1) = fourth*(xxAdj(j,k,1) + xxAdj(j-1,k,1) &
                           +         xxAdj(j,k-1,  1) + xxAdj(j-1,k-1,  1))
                     xc(2) = fourth*(xxAdj(j,k,2) + xxAdj(j-1,k,2) &
                           +         xxAdj(j,k-1,  2) + xxAdj(j-1,k-1,  2))
                     xc(3) = fourth*(xxAdj(j,k,3) + xxAdj(j-1,k,3) &
                           +         xxAdj(j,k-1,  3) + xxAdj(j-1,k-1,  3))

                     ! Determine the coordinates relative to the
                     ! center of rotation.

                     xxc(1) = xc(1) - rotCenterAdj(1)
                     xxc(2) = xc(2) - rotCenterAdj(2)
                     xxc(3) = xc(3) - rotCenterAdj(3)

                     ! Determine the rotation speed of the face center,
                     ! which is omega*r.

                     sc(1) = rotRateAdj(2)*xxc(3) - rotRateAdj(3)*xxc(2)
                     sc(2) = rotRateAdj(3)*xxc(1) - rotRateAdj(1)*xxc(3)
                     sc(3) = rotRateAdj(1)*xxc(2) - rotRateAdj(2)*xxc(1)

                     ! Determine the coordinates relative to the
                     ! rigid body rotation point.

                     xxc(1) = xc(1) - rotationPointAdj(1)
                     xxc(2) = xc(2) - rotationPointAdj(2)
                     xxc(3) = xc(3) - rotationPointAdj(3)

                     ! Determine the total velocity of the cell face.
                     ! This is a combination of rotation speed of this
                     ! block and the entire rigid body rotation.

                     sc(1) = sc(1) + velxGrid           &
                           + rotationMatrixAdj(1,1)*xxc(1) &
                           + rotationMatrixAdj(1,2)*xxc(2) &
                           + rotationMatrixAdj(1,3)*xxc(3)
                     sc(2) = sc(2) + velyGrid           &
                           + rotationMatrixAdj(2,1)*xxc(1) &
                           + rotationMatrixAdj(2,2)*xxc(2) &
                           + rotationMatrixAdj(2,3)*xxc(3)
                     sc(3) = sc(3) + velzGrid           &
                           + rotationMatrixAdj(3,1)*xxc(1) &
                           + rotationMatrixAdj(3,2)*xxc(2) &
                           + rotationMatrixAdj(3,3)*xxc(3)

                     ! Store the dot product of grid velocity sc and
                     ! the normal ss in sFace.

                     sFaceAdj(j,k) = sc(1)*ssAdj(j,k,1) + sc(2)*ssAdj(j,k,2) &
                                + sc(3)*ssAdj(j,k,3)

                   enddo
                 enddo

                 select case (BCFaceID(mm))
                 case (imin,imax)       ! normals in i-direction
                    sFaceIAdj(ii,:,:) =  sFaceAdj
                 case (jmin,jmax)       ! normals in j-direction
                    sFaceJAdj(:,ii,:) = sFaceAdj
                 case (kmin,kmax)       ! normals in k-direction
                    sFaceKAdj(:,:,ii )= sFaceAdj 
                 end select

                 !increment counter for s(i,j,k)adj, sFace(i,j,k)Adj
                 ii=ii+1
                 
               enddo

  !           enddo loopDirection
           endif testUseOldCoor
         endif testMoving
 !      enddo domains
        ! print *,'finished grid velocities'
       end subroutine gridVelocitiesFineLevelForcesAdj