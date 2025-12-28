close all; clear; clc;

[root, figDir, resFile] = paths_from_plots();
addpath(genpath(fullfile(root,"src")));
addpath(genpath(fullfile(root,"plots")));

S = load(resFile,"Results","p","in");
R = S.Results;
p = S.p;
in = S.in;

dpi = 600;
set(groot, ...
 "defaultAxesFontSize",14, "defaultTextFontSize",14, ...
 "defaultAxesLabelFontSizeMultiplier",1.1, "defaultAxesTitleFontSizeMultiplier",1.2, ...
 "defaultLegendFontSize",9);

cols = struct( ...
 "glass",[0.90 0.15 0.15], ...
 "air",  [0.10 0.40 0.80], ...
 "wall3",[0.80 0.70 0.10], ...
 "wall4",[0.55 0.20 0.70], ...
 "out",  [0.20 0.60 0.20]);

days = [46 137 228 319];

% yLeg mapping (height of legends): 137 & 228 -> 0.10 ; 46 & 319 -> 0.55
yLegMap = containers.Map( ...
    {'46','137','228','319'}, ...
    {0.55, 0.10, 0.10, 0.55} );

Tlims = [-5 35];
scale = 1.0;
axPos = [0.10 0.14 0.82 0.78];

t_end = 0:24;
t_mid = 0.5:1:23.5;

tCum = R.HOUR_CUM(:);

for k = 1:numel(days)
    day_to_plot = days(k);
    yLeg = axPos(2) + yLegMap(num2str(day_to_plot));

    idx = day_idx(tCum, day_to_plot);

    T0 = R.T0(idx); T1 = R.T1(idx); T2 = R.T2(idx); T3 = R.T3(idx); T4 = R.T4(idx);
    QkW  = R.Q_LOAD(idx)/1000;

    Qsol = p.L * p.H * p.pGlass * p.d1 * R.Q_SOL(idx)/1000;

    NP_day = get_np(R, in, idx);
    Qppl = (NP_day * 100) / 1000;   % kW

    QkWm  = QkW(2:end);
    Qsolm = Qsol(2:end);
    Qpplm = Qppl(2:end);

    baseDate = datetime(2025,1,1);
    dateStr  = datestr(baseDate + caldays(day_to_plot-1), "dd mmmm");

    f = figure("Units","pixels","Position",[80 120 800 560],"Color","white");

    axBars = axes(f,"Position",axPos);
    hold(axBars,"on"); box(axBars,"on");
    xlim(axBars,[0 24]); xticks(axBars,0:2:24); xlabel(axBars,"Hour of day");

    yyaxis(axBars,"right"); axBars.YColor = "k";
    plot_bars(axBars, t_mid, QkWm, Qpplm, Qsolm);
    ylabel(axBars,"Power [kW]");
    ylim(axBars, scale*Tlims);

    yyaxis(axBars,"left"); axBars.YAxis(1).Visible = "off";

    axLines = axes(f,"Position",axPos,"Color","none");
    hold(axLines,"on"); box(axLines,"off");
    xlim(axLines,[0 24]); axLines.XAxis.Visible = "off";
    ylim(axLines, Tlims); ylabel(axLines,"Temperature [°C]");

    add_comfort_band(axLines, Qpplm>0, 20, 24);

    hT1 = plot(axLines, t_end, T1, "LineWidth",1.6, "Color",cols.glass);
    hT2 = plot(axLines, t_end, T2, "LineWidth",1.6, "Color",cols.air);
    hT3 = plot(axLines, t_end, T3, "LineWidth",1.6, "Color",cols.wall3);
    hT4 = plot(axLines, t_end, T4, "LineWidth",1.6, "Color",cols.wall4);
    hT0 = plot(axLines, t_end, T0, "LineWidth",1.6, "Color",cols.out);

    y0 = yline(axLines,0,"-","LineWidth",1.0); y0.Color="k";
    title(axLines, dateStr, "FontWeight","normal","FontSize",14);

    linkaxes([axBars axLines],"x");

    Qavg_day = mean(QkWm,"omitnan");
    hHVAC = findobj(axBars,"Type","Bar","Tag", ternary(Qavg_day>=0,"HVAC_heat","HVAC_cool"));

    lgBars  = legend(axBars,  [hHVAC findobj(axBars,"Tag","People") findobj(axBars,"Tag","Solar")], ...
                     {"HVAC","People gains","Solar gains"}, "Box","off");
    lgTemps = legend(axLines, [hT1 hT2 hT3 hT4 hT0], ...
                     {'Glass','Indoor air','Interior mass','Facade wall','Outdoor'}, "Box","off");

    place_legends(lgBars, lgTemps, axPos, yLeg);

    outName = sprintf("Q5_day%02d.png", day_to_plot);
    exportgraphics(f, fullfile(figDir,outName), "Resolution", dpi);
    fprintf("Saved: %s\n", fullfile(figDir,outName));

    close(f);
end

% ===================== helpers =====================

function [root, figDir, resFile] = paths_from_plots()
    this = fileparts(mfilename("fullpath"));
    root = fileparts(this);
    figDir  = fullfile(root,"figures"); if ~exist(figDir,"dir"), mkdir(figDir); end
    resFile = fullfile(root,"results","AS3B_Q5_Results.mat");
end

function idx = day_idx(tCum, day)
    i0 = (day-1)*24; i1 = day*24;
    idx = (tCum >= i0) & (tCum <= i1);
end

function NP_day = get_np(R, in, idx)
    if isfield(R,"NP")
        NP_day = R.NP(idx);
    elseif isfield(in,"NP")
        NP_day = in.NP(idx);
    else
        error("No NP found (neither Results.NP nor in.NP).");
    end
end

function plot_bars(ax, xmid, QkWm, Qpplm, Qsolm)
    idx_heat = QkWm > 0;
    idx_cool = QkWm < 0;
    idx_ppl  = Qpplm > 0;

    if any(idx_ppl)
        b = bar(ax, xmid(idx_ppl), Qpplm(idx_ppl), 1.0, ...
            "FaceColor",[0.7 0.7 0.7],"EdgeColor","none","FaceAlpha",0.85);
        b.Tag = "People";
    end
    if any(idx_heat)
        b = bar(ax, xmid(idx_heat), QkWm(idx_heat), 1.0, ...
            "FaceColor","red","EdgeColor","none","FaceAlpha",0.6);
        b.Tag = "HVAC_heat";
    end
    if any(idx_cool)
        b = bar(ax, xmid(idx_cool), QkWm(idx_cool), 1.0, ...
            "FaceColor","blue","EdgeColor","none","FaceAlpha",0.6);
        b.Tag = "HVAC_cool";
    end
    b = bar(ax, xmid, Qsolm, 1.0, ...
        "FaceColor",[0.95 0.85 0.20],"EdgeColor","none","FaceAlpha",0.6);
    b.Tag = "Solar";
end

function add_comfort_band(ax, occHour, Tlow, Thigh)
    d = diff([false; occHour(:); false]);
    run_start = find(d==1);
    run_end   = find(d==-1)-1;

    col = [0.80 0.88 0.97]; alpha = 0.30;
    for r = 1:numel(run_start)
        x0 = run_start(r)-1;
        x1 = run_end(r);
        patch(ax, [x0 x1 x1 x0], [Tlow Tlow Thigh Thigh], col, ...
            "EdgeColor","none","FaceAlpha",alpha);
    end
end

function place_legends(lgBars, lgTemps, axPos, yLeg)
    lgBars.Location  = "none";
    lgTemps.Location = "none";
    lgBars.Units = "normalized";
    lgTemps.Units = "normalized";
    drawnow;

    pb = lgBars.Position;
    pt = lgTemps.Position;

    xLeft  = axPos(1) + 0.01;
    xRight = axPos(1) + axPos(3) - pt(3) - 0.01;

    lgBars.Position  = [xLeft  yLeg pb(3) pb(4)];
    lgTemps.Position = [xRight yLeg pt(3) pt(4)];
end

function out = ternary(cond,a,b)
    if cond, out = a; else, out = b; end
end