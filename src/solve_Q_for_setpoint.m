function Q = solve_Q_for_setpoint(p, T0, Qsol, Tpast, vent, Tset, np)

f = @(Qtrial) (Tair_end(p, T0, Qsol, Tpast, Qtrial, vent, np) - Tset);

Qlo = -p.Qmax;
Qhi =  p.Qmax;

flo = f(Qlo);
fhi = f(Qhi);

it = 0;
while sign(flo)==sign(fhi) && it<12
    Qlo = 2*Qlo; 
    Qhi = 2*Qhi;
    flo = f(Qlo);
    fhi = f(Qhi);
    it = it + 1;
end

if sign(flo)==sign(fhi)
    Q = 0;
    return
end

Q = fzero(f,[Qlo Qhi]);

end

function Tair = Tair_end(p, T0, Qsol, Tpast, Qheat, vent, np)
[~, TT2, ~, ~] = HHS_model4(p, T0, Qsol, Tpast, Qheat, vent, np);
Tair = TT2(end);
end
