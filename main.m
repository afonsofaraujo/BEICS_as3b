close all; clear; clc;

root = fileparts(mfilename("fullpath"));
addpath(genpath(fullfile(root,"src")));
addpath(genpath(fullfile(root,"plots")));

load(fullfile(root,"data","HourlyEnergyData.mat"),"df");

in = struct();
in.HOUR  = df.HOUR;
in.T0    = df.T0;
in.Q_SOL = df.Q_SOL;
in.NP    = 25 * double(mod(in.HOUR-1,24) >= 8 & mod(in.HOUR-1,24) < 18);

p = defaults();
Results = run_simulation(in, p);

resDir = fullfile(root,"results");
if ~exist(resDir,"dir"), mkdir(resDir); end
save(fullfile(resDir,"AS3B_Q5_Results.mat"),"Results","p","in");