function Results = run_simulation(in, p)

Q_SOL = in.Q_SOL(:);
HOUR = in.HOUR(:);
T0 = in.T0(:);
NP = in.NP(:);

N = numel(HOUR);

pre = max(0, round(p.preheat_hours));
occ = NP > 0;
occSoon = occ;
if pre > 0
    for i = 1:N
        j = min(N, i+pre);
        occSoon(i) = any(occ(i:j));
    end
end

VENT = p.vent_base + p.vent_pp .* NP;

T1 = zeros(N,1);
T2 = zeros(N,1);
T3 = zeros(N,1);
T4 = zeros(N,1);
Q_LOAD = zeros(N,1);
MODE = strings(N,1);

Tpast = p.Tpast_init(:)';

for i = 1:N
    if occSoon(i)
        Theat = p.T_heat_occ;  Tcool = p.T_cool_occ;
    else
        Theat = p.T_heat_unocc; Tcool = p.T_cool_unocc;
    end

    if p.unocc_mode == "FREEFLOAT"
        hvac_allowed = occSoon(i);
    else
        hvac_allowed = true;
    end

    [Qi, mode_i] = hvac_control(hvac_allowed, p, T0(i), Q_SOL(i), Tpast, VENT(i), NP(i), Theat, Tcool);

    [TT1,TT2,TT3,TT4] = HHS_model4(p, T0(i), Q_SOL(i), Tpast, Qi, VENT(i), NP(i));

    t1 = TT1(end); t2 = TT2(end); t3 = TT3(end); t4 = TT4(end);

    T1(i)=t1; T2(i)=t2; T3(i)=t3; T4(i)=t4;
    Q_LOAD(i)=Qi; MODE(i)=mode_i;

    Tpast = [t3, Tpast(1:3)];
end

HVAC_ON = abs(Q_LOAD) > 1e-6;

Results = table( ...
    HOUR, mod(HOUR-1,24), T0, T1, T2, T3, T4, ...
    HVAC_ON, MODE, ...
    NP, VENT, ...
    Q_LOAD, Q_SOL, ...
    'VariableNames', {'HOUR_CUM','HOUR','T0','T1','T2','T3','T4','HVAC_ON','MODE','NP','VENT','Q_LOAD','Q_SOL'} );
end