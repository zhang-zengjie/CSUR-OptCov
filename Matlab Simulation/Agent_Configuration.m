offset = 20;
maxX = 100;
maxY = 200;
global nAgent;
nAgent = 3;

randLow = 2*pi;
randUp  = 0;
startTheta = randLow + rand(nAgent,2)*(randUp-randLow);

centerX = 50;
centerY = 50;
rXY = 1;

startX = centerX + rXY * cos(0 : 2*pi/nAgent : 2*pi);
startY = centerY + rXY * sin(0 : 2*pi/nAgent : 2*pi);
startPose = [startX', startY', zeros(numel(startX),1)];

pose = zeros(3, nAgent);
poseVM = zeros(nAgent, 3);
com = Class_Centralized_Controller(nAgent, worldVertexes(1:end-1,:), xrange, yrange);
com.boundariesCoeff = [A(:,1), A(:,2), b'];

% BOT & CONTROLLER
v =  linspace(50, 80, nAgent) .* ones(1,nAgent);
w0 = linspace(1, 1.6, nAgent) .* ones(1,nAgent);
wMax = 3.2;
K1 = 3.2 - w0;
K2 = 1;

if(world == VREP)
    v = linspace(0.2,0.4, nAgent) .* ones(1,nAgent);
    w0 = linspace(0.1, 0.2, nAgent) .* ones(1,nAgent);
    wMax = 0.5;
    startPose = [0.375, 0.975, 0;
                 1.2250, 0.3750, 0;
                 2.850, 0.4750, 0;
                 1.675, 1.4750, 0;
                 0.650, 2.550, 0] + 3;
    K1 = 0.28;
    K2 = 0.5;
end
k_inputScale = [K1 .* ones(1, nAgent)', K2 * ones(1,nAgent)'];         
%kMu = rand(nAgent,1) .* w0;
kMu = wMax - w0;
bot_handle = Class_Mobile_Robot.empty(nAgent, 0);
controller_handle = Class_Controller_Khanh.empty(nAgent, 0);

global dt;
for i  = 1:nAgent
   bot_handle(i) = Class_Mobile_Robot(startPose(i,1), startPose(i,2), startPose(i,3), dt);
   bot_handle(i).wMax = wMax;
   bot_handle(i).setParameterVirtualMass(w0(i));
   controller_handle(i) = Class_Controller_Khanh(0, w0(i), v(i), worldVertexes, bot_handle(i)); 
end

