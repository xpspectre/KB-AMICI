function [p, G, exit_flag, output] = fit_eq_model(data, ny, fit_opts)
% Fit equilibrium model
% The ny is awkwardly inserted as an arg to specify the entire obs set

data = build_amici_data(data, ny);

obj_fun_opts = [];
obj_fun_opts.sens_method = fit_opts.sens_method;

switch fit_opts.verbose
    case 0
        display = 'none';
    case 1
        display = 'final';
    case 2
        display = 'iter-detailed';
end

% p0 = fit_opts.p0;
% G = obj_fun(p0, data, obj_fun_opts);

opts = optimoptions('fmincon', 'SpecifyObjectiveGradient', true, 'Display', display);
fun = @(p) obj_fun(p, data, obj_fun_opts);
[p, G, exit_flag, output] = fmincon(fun, fit_opts.p0, [], [], [], [], fit_opts.p_lo, fit_opts.p_hi, [], opts);
end

function [G, dGds] = obj_fun(p, data, obj_fun_opts)
% Objective function for fit
opts = amioption('sensi', 1);
switch obj_fun_opts.sens_method
    case 'fwd'
        opts.sensi_meth = 'forward';
    case 'adj'
        opts.sensi_meth = 'adjoint';
end

sol_sens = simulate_eq_model(data.t, p, [], data, opts);
if sol_sens.status ~= 0
    error('Sensitivity simulation returned non-zero exit status')
end
G = -sol_sens.llh; % obj fun is the negative log-likelihood
dGds = -sol_sens.sllh; % and obj fun grad is also negated
end
