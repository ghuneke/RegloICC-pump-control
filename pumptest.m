%%
pump = RegloICC('COM6');
%%
directions = [1,1,1,0]; % 1: CW, 0: CCW

tubeID = 1.52; % inner diameter of tubing

speeds = [1,1,1,3]; % mL/min %1.52ID tubing min 0.13, max 13

for i = 1:4
    pump.setTubeDiameter(i,tubeID);
    pump.setMode(i,'M');
    pump.setDirection(i,directions(i));
    pump.setSpeed(i,speeds(i));
end
%%

for i = 1:4
    pump.startChannel(i);
end

%%

for i = 1:4
    pump.stopChannel(i);
end


%%
clear pump;