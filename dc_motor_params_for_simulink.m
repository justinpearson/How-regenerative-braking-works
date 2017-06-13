% dc motor params for simulink simulation
% jpp_dc_motor_regen_example2.slx

clear all; close all; fclose all; clc;

R = 14; % DMM
L = .0115; % LCR meter
Kb = .0405; % also called Kbemf. Spin by hand, measure voltage w/ dmm, and (in bash) get eqep twice, separated by sleep 1, to estimate w. Do for multiple voltages.
Km = .0405; % David found somewhere that Kb == Km. Can this be? They have same units...
bOverJ = .0125; % "flywheen spindown test". Spin up, record eqep every sec as it spins down. w' = b/J w => time to hit 63% of its initial value is J/b.
J = .168; % aluminum disk 10" across, 3/8" thick
Vs = 12; % My two 6-V batteries in series

A = [ -R/L, -Kb/L 
      Km/J, -bOverJ ];

B = [1/L 
      0 ];

C = eye(2);

D = zeros(2,1);

% eigs:
[v,d] = eig(A) % A*x = V * D * Vinv * x  let z:= Vinv*x  then  z' = D*z
% v =
%    -1.0000    0.0029
%     0.0002   -1.0000
%
% d(1,1)
%   -1.2174e+03
% d(2,2)
%    -0.0132

% Note: these evals are essentially
% R/L
%    1.2174e+03
% bOverJ
%     0.0125

% You can see that there's a fast mode and a slow mode.
% Current corresponds to the -1.2e3 eval, 
% and angvel to the .013 eval.
% 1/these is about 1ms and 1min.
% Therefore the electrical system changes 5 orders of mag faster than the
% mechanical system.


% ss after applying Vs and motor spins up
xss = -inv(A)*B*Vs
iss = xss(1) % .8A
wss = xss(2) % 16 rad/s = 2.5 rev / s

% short-term current when Vs=0 but before w changes
% Vs = I*R + L*I' + Kb*wss
% Vs=0, I'=0
iss1=-Kb*wss/R % -.04 A

% note: iss overcomes friction (b & R) in motor
% Note: asym btwn .8A and -.04A, same asym in regen / reverse-current
% timing

% Note: waiting until close to -0.04A bad: resistor eats E while you're
% waiting

% bigger Vs in final stage: less time that R burns up E

% like a switching power supply
% - apple's incredible switching power supplies

% multiple batts: switch to dump current into several, so that the current
% won't increase so fast.

%% Controller that connects / disconnects battery

% current threshold for disconnecting the battery (so bemf builds up neg current):
thresOn = 0;
% current threshold for connecting battery (so battery absorbs current & increases current):
thresOff = .95*iss1; % Note: this is actually negative.
% supply voltage that results from battery being disconnected:
voltOn = 0;
% supply voltage that results from battery being connected:
voltOff = Vs;



%% Simulate

tmax = 10;

% sim('jpp_dc_motor_regen_example.slx');
sim('jpp_dc_motor_regen_example2.slx');

% Should now have states X and applied supply voltage V
t = X.Time;
current = X.Data(:,1);
angvel = X.Data(:,2);
battvoltage = V.Data;

%% Plot

figure(1); clf;
h(1) = subplot(3,1,1);
plot(t,current,'k.-')
line(xlim,[0,0],'color','k')
line(xlim,[iss1,iss1],'color','r')
line(xlim,.95*[iss1,iss1],'color','b')
title('current (A)')
h(2) = subplot(3,1,2);
plot(t,angvel,'k.-')
title('angular velocity (rad/s)')
h(3) = subplot(3,1,3);
plot(t,battvoltage,'k.-')
title('supply voltage (V)')

linkaxes(h,'x')
set(gcf,'position',[ 1 5 1680 951])

%% Plot power & energy out of battery
figure(2); clf;
h(1) = subplot(2,1,1)
plot(P.Time, P.Data,'k.-')
title('power put out by battery')
h(2) = subplot(2,1,2)
plot(Energy.Time,Energy.Data,'k.-')
title('energy put out by battery')
set(gcf,'position',[ 1 5 1680 951])

%%
% Note: 
axis([0.9332    1.8395   -0.0065   -0.0034])
diff(ylim)/diff(xlim)
% ans =
%     0.0034
% as in, 3mW
%% To Do
% I see that we only recover energy like 1% of the time. Not great. Figure
% out an analyitical expr for the time for current to go btwn .95*iss1 and 0,
% versus time for current to go btwn 0 and .95*iss1. Why different? I
% would've thought they'd be the same, and you'd therefore be regenning 50%
% of the time, not 1%.