%-------------------------------------------------------------------------------------------------------------------%
%
% IB2d is an Immersed Boundary Code (IB) for solving fully coupled non-linear 
% 	fluid-structure eraction models. This version of the code is based off of
%	Peskin's Immersed Boundary Method Paper in Acta Numerica, 2002.
%
% Author: Nicholas A. Battista
% Email:  nick.battista@unc.edu
% Date Created: May 27th, 2015
% Institution: UNC-CH
%
% This code is capable of creating Lagrangian Structures using:
% 	1. Springs
% 	2. Beams (*torsional springs)
% 	3. Target Pos
%	4. Muscle-Model (combined Force-Length-Velocity model, "Hill+(Length-Tension)")
%
% One is able to update those Lagrangian Structure parameters, e.g., spring ants, resting lengths, etc
% 
% There are a number of built in Examples, mostly used for teaching purposes. 
% 
% If you would like us to add a specific muscle model, please let Nick (nick.battista@unc.edu) know.
%
%--------------------------------------------------------------------------------------------------------------------%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: updates the spring attributes!
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function beams_info = update_nonInv_Beams(dt,current_time,beams_info)


% beams_info:   col 1: 1ST PT.
%               col 2: MIDDLE PT. (where force is exerted)
%               col 3: 3RD PT.
%               col 4: beam stiffness
%               col 5: curavture

% GEOMETRIC PARAMETERS
pi = 4*atan(1);
L1 = 8;                              % length of computational domain (m)
N1 = 512;                            % number of Cartesian grid meshwidths at the finest level of the AMR grid
bell_length = 2;                % bell length (m)
bell_circumference = pi;
npts_bell = ceil(2*(bell_length/L1)*N1);  % number of pos along the length of the bell
npts_circ = 1; %number of pos along the circumference (if in 3D)
npts = npts_bell*npts_circ;	    % total number pos
dphi = bell_circumference/(npts_circ-1);     %mesh spacing (m) in third dimension if applicable
ds1 = bell_length/(npts_bell-1);   % mesh spacing(m) along length of bell

% Values from Alben, Peng, and Miller
betao = 0.5;
betam = 0.3;
to = 0.4;
gamma = 1;

s1 = 0;
q1 = 0;

beta = 0.5;
V = 1; 
Zs = -2;            
zl=-2;
rl=0;
phi = 0;
ro=0;
thetaj = 0;
pulse_time = 0;
ptt = 0;
i1 =0;

 %These are used to keep track of cycle number and time into the cycle
ptt = floor(current_time/(2*to));              % determine cycle number, starting at 0
pulse_time = current_time-floor(current_time); % determine time since beginning of first pulse
		
    if (pulse_time<to)  %contract bell
        phi = 0;
        beta = betao+(betam-betao)*(pulse_time/to);
    else                % expand bell
        phi = 0; 
        beta = betam+(betao-betam)*((pulse_time-to)/(1-to));
    end
		
    %---------------------
    %Xb and Yb are calculated here and will be used to determine new curvatures
    s1=0;
    thetaj = -1.55*(1-exp(-(s1)*ds1/beta));
    zl = Zs;
    ro = 0;
    %top of bell
    Xb_lam(1)=ro;
    Yb_lam(1)=zl;

    %right side of bell
    for s1 = 2:ceil(npts_bell/2)
        thetaj = -1.55*(1-exp(-(s1)*ds1/beta));
        zl = zl + ds1*sin(thetaj);
        ro = ro + ds1*cos(thetaj);
        Xb_lam(s1)=ro;
        Yb_lam(s1)=zl;
    end

    zl = Zs;
    ro = 0;
    %left side of bell
    for s1 = (ceil(npts_bell/2))+1:npts_bell
        s2=s1-(ceil(npts_bell/2));
        thetaj = -1.55*(1-exp(-(s2)*ds1/beta));
        zl = zl + ds1*sin(thetaj);
        ro = ro - ds1*cos(thetaj);
        Xb_lam(s1)=ro;
        Yb_lam(s1)=zl;
    end

    C = give_Beam_Curvatures();      % Gives beam CURVATURES for each phase


% CHANGE RESTING LENGTH BTWN SIDES OF JELLYFISH BELL
for i=1:length( beams_info(:,5) )
    
    if t<= P1
        beams_info(:,5) = C(:,1) + (t/P1)*( C(:,2) - C(:,1) );
    else
        tt = t - P1;
        beams_info(:,5) = C(:,2) + ( tt/P2 )*( C(:,1) - C(:,2) );
    end
    
end


