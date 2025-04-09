% This script describes the hormonal cycling protocol for tendon explant
% testing
% Ensure pump is primed and calibrated before each use, this script assumes
% the bioreactor is pre-filled

%% set pump parameters

pump = RegloICC('COM6'); % initialize pump: set to appropriate COM port

%Channels are numbered back-to-front - i.e. channel 1 is closest to the
%pump body

tubeID = 1.52; 
directions = [1,1,1,0]; % 1: CW, 0: CCW. 


for i = 1:4
    pump.setTubeDiameter(i,tubeID);
    pump.setMode(i,'M'); % M for flow rate mode in mL/min
    pump.setDirection(i,directions(i));
end

%% set hormone protocol parameters

totalVolume = 200; % mL - placeholder not final
netFlowRate = totalVolume/60; % mL/min - full volume exchange once per hour

stockE = 2000; % pM
stockP = 2000; % pM

phasePeaksE = [1000,500,100,100]; % from 4-day protocol
phasePeaksP = [100,100,500,1000]; % from 4-day protocol


% flow rate for each pump channel based on total net flow, output in mL/min
pumpSpeedE = getFlowRateVec(phasePeaksE,stockE,netFlowRate); 
pumpSpeedP = getFlowRateVec(phasePeaksP,stockP,netFlowRate); 
pumpSpeedNH = netFlowRate - (pumpSpeedE + pumpSpeedP); 
pumpSpeedDrain = netFlowRate; 

%% run protocol

numHormoneCycles = 4; % set how many times to execute protocol over experiment

for j = 1:numHormoneCycles
    for i = 1:96
    pump.setSpeed(1,pumpSpeedE(i)); 
    pump.setSpeed(2,pumpSpeedP(i));
    pump.setSpeed(3,pumpSpeedNH(i));
    pump.setSpeed(4,pumpSpeedDrain(i));
    
    fprintf('Current pump speeds (mL/min): E: %.2f, P: %.2f, NH: %.2f, Drain: %.2f\n',pumpSpeedE(i),pumpSpeedP(i),pumpSpeedNH(i),pumpSpeedDrain(i))
    
    pause(60) % one minute for testing purposes - one hour (3600s) for experimental timescale
    end
end
%%
clear pump
%% helper functions

function hormoneConcentration = getConcentrationVec(phasePeaks)
    % interpolate to 1 point per hour
    phase1 = linspace(phasePeaks(1),phasePeaks(2),24);
    phase2 = linspace(phasePeaks(2),phasePeaks(3),24);
    phase3 = linspace(phasePeaks(3),phasePeaks(4),24);
    phase4 = linspace(phasePeaks(4),phasePeaks(1),24);

    hormoneConcentration = [phase1,phase2,phase3,phase4];
end

function flowRates = getFlowRateVec(phasePeaks,stockConcentration,netFlowRate)
    hormoneConcentration = getConcentrationVec(phasePeaks);

    flowRates = hormoneConcentration/stockConcentration*netFlowRate;
end

