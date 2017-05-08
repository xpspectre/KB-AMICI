function [p, G, exit_flag, output] = fit_model(m, data, opts)
% Fit single Model to data using weighted sum of squares objective
% function. Right now, this fits all model parameters.
%
% Notation: nd is the total number of datapoints/measurements
%
% Inputs:
%   m [ Model ]
%       Finalized Model
%   data [ struct ]
%       Experimental data struct with fields:
%       .obs_inds [ nd int array ]
%           Observation index of each measurement
%       .times [ nd double array ]
%           Time of each nd
%       .measurements [ nmeas double array ]
%           Value of each measurement
%       .std_devs [ nd double array ]
%           Std dev of each measurement
%   opts [ struct ]
%       Options struct with fields:
%       .verbose [ positive integer {1} ]
%           How much info to display. 0 for none. 2 for detailed iteration
%           data from optimizer.
%       .sens_method [ {'fwd'} | 'adj' ]
%           Forward or adjoint sensitivity calculation method. Forward is
%           better tested and faster for smaller models. Adjoint is better
%           for very large models.
%       .p0 [ np double array ]
%           Initial guesses for fit parameters
%       .p_lo [ np double array ]
%           Lower bounds for fit parameters
%       .p_hi [ np double array ]
%           Upper bounds for fit parameters
%
% Outputs:
%   p [ 1 x np double vector ]
%       Fit parameters
%   G [ scalar double ]
%       Final objective function value
%   exit_flag [ scalar integer ]
%       Exit status code from optimizer
%   output [ struct ]
%       Detailed exit status info from optimizer

data = build_amici_data(data, m.ny);

obj_fun_opts = [];
obj_fun_opts.sens_method = opts.sens_method;

switch opts.verbose
    case 0
        display = 'none';
    case 1
        display = 'final';
    case 2
        display = 'iter-detailed';
end

fit_opts = optimoptions('fmincon', 'SpecifyObjectiveGradient', true, 'Display', display);
fun = @(p) obj_fun(p, m, data, obj_fun_opts);
[p, G, exit_flag, output] = fmincon(fun, opts.p0, [], [], [], [], opts.p_lo, opts.p_hi, [], fit_opts);
end

function [G, dGds] = obj_fun(p, m, data, obj_fun_opts)
% Objective function for fit
opts = amioption('sensi', 1);
switch obj_fun_opts.sens_method
    case 'fwd'
        opts.sensi_meth = 'forward';
    case 'adj'
        opts.sensi_meth = 'adjoint';
end

sol_sens = m.model_fun(data.t, p, [], data, opts);
if sol_sens.status ~= 0
    error('Sensitivity simulation returned non-zero exit status')
end
G = -sol_sens.llh; % obj fun is the negative log-likelihood
dGds = -sol_sens.sllh; % and obj fun grad is also negated
end
