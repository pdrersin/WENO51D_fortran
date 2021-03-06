! Main file
program main
  use flux
  use plotter
  use transform
  implicit none
  ! Plot values: 1=velocity, 2=pressure, 3=density 4=Mach number
  integer,parameter :: n_x = 201, SAVE=1,PLOT=1,PLOTVAL=3,VIDEO=0
  real, parameter :: startx = 0, endx = 1,gamma = 1.4
  real :: delx,dt,cfl,tend,lambda_0,lambda,t,dt_0
  integer :: I,id=0,check
  real,dimension(n_x) :: x,a_0,l_0,p,rho,vel,E,a                             ! Stores x coordinate of the points, primitive values
  real, dimension(n_x,3) :: u,u_0,q_0,q,qo,dF,hp,hn,v,vp,vn,g,f,gp,gn        ! Stores primitive values and flux values

  delx = abs(endx-startx)/(n_x-1)
  cfl = 0.55
  tend = 0.1

  x = (/ (startx + (I-1)*delx,I = 1,n_x) /)
  call IC1DStep(u_0,q_0,n_x,x)
  q = q_0
  a_0 = SQRT(gamma*u_0(:,2)/u_0(:,3))
  lambda_0 = MAXVAL( ABS( u_0(:,1) )+a_0 )
  dt_0 = cfl * delx/lambda_0

  !! Solver Loop
  u = u_0
  q = q_0
  t=0
  dt = dt_0
  lambda = lambda_0
  if(PLOT==1) then
    check=plot_data(q,x,n_x,t,id,PLOTVAL)
    id=id+1
  else if(SAVE==1)then
    check=save_data(q,x,n_x,t,id)
    id=id+1
  end if


  do while (t < tend)
    ! Starting RK
    qo = q

    ! RK 1st step
    f = build_flux(q,n_x)
    call WENO51d(lambda,f,q,delx,n_x,hp,hn)
    dF = ((hp - turn(hp,n_x,1)) + (hn - turn(hn,n_x,1)))/delx

    q = qo - dt*dF
    q(1,:) = qo(1,:)
    q(n_x,:) = qo(n_x,:)


    ! RK 2nd step
    f = build_flux(q,n_x)
    call WENO51d(lambda,f,q,delx,n_x,hp,hn)
    dF = ((hp - turn(hp,n_x,1)) + (hn - turn(hn,n_x,1)))/delx

    q = 0.75*qo + 0.25*( q - dt*dF)
    q(1,:) = qo(1,:)
    q(n_x,:) = qo(n_x,:)


    ! RK 3rd step
    f = build_flux(q,n_x)
    call WENO51d(lambda,f,q,delx,n_x,hp,hn)
    dF = ((hp - turn(hp,n_x,1)) + (hn - turn(hn,n_x,1)))/delx

    q = (qo + 2.0*( q - dt*dF))/3.0
    q(1,:) = qo(1,:)
    q(n_x,:) = qo(n_x,:)

    ! Extract primitive values
    call primitives(q,n_x,rho,vel,E,p,a)

    lambda = MAXVAL(ABS(vel)+a)
    dt = cfl*delx/lambda
    if(t+dt>tend) then
      dt = tend-t
    end if

    if(PLOT==1) then
      check=plot_data(q,x,n_x,t,id,PLOTVAL)
      id=id+1
    else if(SAVE==1)then
      check=save_data(q,x,n_x,t,id)
      id=id+1
    end if
      t=t+dt

  end do
if(VIDEO==1) then
  check=get_video(PLOTVAL)
end if
end program main
