% ============================================================
% make_figures_Q5_halfwidth.m
% FIX: lines always above bars (robust) using 2 overlaid axes
% ============================================================

close all; clear; clc;

S = load("AS3B_Q5_Results.mat","Results","p","E_heat_kWh","E_cool_kWh");
R = S.Results;

outDir = fullfile(pwd,"figures"); if ~exist(outDir,"dir"), mkdir(outDir); end
dpi = 600; figBG = "white";

col_glass = [0.90 0.15 0.15];
col_air   = [0.10 0.40 0.80];
col_wall3 = [0.80 0.70 0.10];
col_wall4 = [0.55 0.20 0.70];
col_out   = [0.20 0.60 0.20];

set(groot, ...
 "defaultAxesFontSize",14, "defaultTextFontSize",14, ...
 "defaultAxesLabelFontSizeMultiplier",1.1, "defaultAxesTitleFontSizeMultiplier",1.2, ...
 "defaultLegendFontSize",9);

t = R.HOUR_CUM(:);

% ------------------- Day selection -------------------


% 46   137    228   319
day_to_plot = 137;
i_start = (day_to_plot-1)*24;
i_end   = day_to_plot*24;
idx = (t >= i_start) & (t <= i_end);

% ------------------- Data -------------------
T0 = R.T0(idx); T1 = R.T1(idx); T2 = R.T2(idx); T3 = R.T3(idx); T4 = R.T4(idx);
QkW  = R.Q_LOAD(idx)/1000;

p = defaults();
Qsol = p.L * p.H * p.pGlass * p.d1 * R.Q_SOL(idx)/1000;
Qppl = (R.NP(idx) * 100) / 1000; % kW

t_end = 0:24;
t_mid = 0.5:1:23.5;

QkWm  = QkW(2:end);
Qsolm = Qsol(2:end);
Qpplm = Qppl(2:end);

idx_heat = QkWm > 0;
idx_cool = QkWm < 0;
idx_ppl  = Qpplm > 0;

% % ---- Y-limits base from temperatures ----
% Tmin = min([T0;T1;T2;T3;T4]); Tmax = max([T0;T1;T2;T3;T4]);
% Tpad = 0.06*(Tmax - Tmin + eps);
% Tlims = [Tmin-Tpad, Tmax+Tpad];

% ---- Y-limits base from temperatures ----
Tmin = -5; Tmax = 35;
Tlims = [Tmin, Tmax];

scale = 1.0; % 1.0 => 10°C aligns with 10 kW (visual calibration)

% ---- Title (calendar date from day-of-year) ----
baseDate = datetime(2025,1,1);
dateStr  = datestr(baseDate + days(day_to_plot-1), 'dd mmmm');

% ------------------- Figure (half width) -------------------
f = figure("Units","pixels","Position",[80 120 800 560],"Color",figBG);

% Axes position (use explicit position so legends placement is stable)
axPos = [0.10 0.14 0.82 0.78];


% ===================== BOTTOM AXES: BARS (kW) =====================
axBars = axes(f,"Position",axPos);
hold(axBars,"on"); box(axBars,"on");
set(axBars,"XColor","k","YColor","k","Layer","top");

% X formatting (main x-axis lives here)
xlim(axBars,[0 24]);
xticks(axBars,0:2:24);
xlabel(axBars,"Hour of day");

% Grid (horizontal only)
grid(axBars,"on");
axBars.XGrid = "off";
axBars.YGrid = "off";

% Right axis for power
yyaxis(axBars,"right");
set(axBars,"YColor","k");

bp = bar(axBars, t_mid(idx_ppl),  Qpplm(idx_ppl),  1.0, ...
    "FaceColor",[0.7 0.7 0.7],"EdgeColor","none","FaceAlpha",0.85);
bh = bar(axBars, t_mid(idx_heat), QkWm(idx_heat), 1.0, ...
    "FaceColor","red","EdgeColor","none","FaceAlpha",0.6);
bc = bar(axBars, t_mid(idx_cool), QkWm(idx_cool), 1.0, ...
    "FaceColor","blue","EdgeColor","none","FaceAlpha",0.6);
bs = bar(axBars, t_mid,           Qsolm,           1.0, ...
    "FaceColor",[0.95 0.85 0.20],"EdgeColor","none","FaceAlpha",0.6);

ylabel(axBars,"Power [kW]");
ylim(axBars, scale*Tlims);  % keep your visual calibration

% Hide left y-axis of bars axes (we'll use the top axis for temperatures)
yyaxis(axBars,"left");
axBars.YAxis(1).Visible = "off";

% ===================== TOP AXES: LINES (°C) =====================
axLines = axes(f,"Position",axPos,"Color","none");
hold(axLines,"on"); box(axLines,"off");
set(axLines,"XColor","k","YColor","k");

% Match x range, but hide x-axis here (so only one x-axis is shown)
xlim(axLines,[0 24]);
xticks(axLines,0:1:24);
axLines.XAxis.Visible = "off";
% ---- Comfort temperature band (20–24 °C) ----
% ---- Comfort band ONLY when occupied (NP > 0) ----
NP_day  = R.NP(idx);        % 25 pontos (0..24)
NPm     = NP_day(2:end);    % 24 horas (0-1 ... 23-24), alinhado com t_mid
occm    = NPm > 0;          % ocupação por hora

% Encontrar blocos contíguos de ocupação
d = diff([false; occm(:); false]);
run_start = find(d == 1);
run_end   = find(d == -1) - 1;

comfortCol = [0.80 0.88 0.97];  % subtle light blue
comfortAlpha = 0.30;

hComfort = gobjects(numel(run_start),1);
for r = 1:numel(run_start)
    x0 = run_start(r) - 1;   % edge esquerda (ex.: k=1 -> 0)
    x1 = run_end(r);         % edge direita  (ex.: k=1 -> 1)

    hComfort(r) = patch(axLines, ...
        [x0 x1 x1 x0], [20 20 24 24], comfortCol, ...
        "EdgeColor","none", "FaceAlpha",comfortAlpha);
end


% Temperature axis (left)
ylim(axLines, Tlims);
ylabel(axLines,"Temperature [°C]");

hT1 = plot(axLines, t_end, T1, "LineWidth",1.6, "LineStyle","-", "Color",col_glass);
hT2 = plot(axLines, t_end, T2, "LineWidth",1.6, "LineStyle","-", "Color",col_air);
hT3 = plot(axLines, t_end, T3, "LineWidth",1.6, "LineStyle","-", "Color",col_wall3);
hT4 = plot(axLines, t_end, T4, "LineWidth",1.6, "LineStyle","-", "Color",col_wall4);
hT0 = plot(axLines, t_end, T0, "LineWidth",1.6, "LineStyle","-", "Color",col_out);

% Zero line drawn on top axis so it sits above bars too
y0 = yline(axLines,0,"-","LineWidth",1.0); y0.Color="k";

% Title on top axis
title(axLines, dateStr, "FontWeight","normal","FontSize",14);

% Keep x linked (zoom/pan stays consistent)
linkaxes([axBars axLines],"x");

% ---- HVAC legend colour based on daily average ----
Qavg_day = mean(QkWm,"omitnan");
if Qavg_day >= 0
    hHVAC = bh;
else
    hHVAC = bc;
end

% ===================== LEGENDS (manual position) =====================
% Create legends on their respective axes
lgBars  = legend(axBars,  [hHVAC bp bs], {"HVAC","People gains","Solar gains"}, "Box","off");
lgTemps = legend(axLines, [hT1 hT2 hT3 hT4 hT0], {'Glass','Indoor air','Interior mass','Facade wall','Outdoor'}, "Box","off");

lgBars.Location  = "none";
lgTemps.Location = "none";
lgBars.Units     = "normalized";
lgTemps.Units    = "normalized";

drawnow; % ensure sizes are computed

pb = lgBars.Position;
pt = lgTemps.Position;

% Slightly above x-axis (inside axes)
yLeg = axPos(2) + 0.1;   % tweak this value

% Left legend (bars)
xLeft  = axPos(1) + 0.01;

% Right legend (temps)
xRight = axPos(1) + axPos(3) - pt(3) - 0.01;

lgBars.Position  = [xLeft  yLeg pb(3) pb(4)];
lgTemps.Position = [xRight yLeg pt(3) pt(4)];





% Export
exportgraphics(f, fullfile(outDir, sprintf("Q5_day%02d_combined_halfwidth.png",day_to_plot)), "Resolution", dpi);
fprintf("Saved figures to: %s\n", outDir);

close all;
