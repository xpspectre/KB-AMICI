function [p, G, exit_flag, output] = fit_model(m, data, opts)
% Fit single Model to data using weighted sum of squares objective
% function. You can specify which parameters to fit, but non-fit params will be
% set to the model defaults.
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
%       .p_lo [ np double array {-inf(1,np)} ]
%           Lower bounds for fit parameters
%       .p_hi [ np double array {inf(1,np)} ]
%           Upper bounds for fit parameters
%       .p_fit [ np int array {ones(1,np)} ]
%           Specification of fitting status. 0 in a position indicates don't
%           fit; nonzero indicates fit. Default is to fit all parameters.
%
% Outputs:
%   p [ 1 x np double vector ]
%       Fit parameters, including those specified not to be fit.
%   G [ scalar double ]
%       Final objective function value
%   exit_flag [ scalar integer ]
%       Exit status code from optimizer
%   output [ struct ]
%       Detailed exit status info from optimizer

% Default options
opts_ = [];
opts_.verbose = 1;
opts_.sens_method = 'fwd';
opts_.p0 = [m.Parameters.Value];
np = length(opts_.p0);
opts_.p_lo = -inf(1,np);
opts_.p_hi = inf(1,np);
opts_.p_fit = ones(1,np);
opts = merge_structs(opts_, opts);

% Build map of model params <-> fit params T
p_fit = opts.p_fit ~= 0;
p_inds = find(p_fit);
nT = sum(p_fit);
assert(length(opts.p0) == nT)
assert(length(opts.p_lo) == nT)
assert(length(opts.p_hi) == nT)

% Assemble fit params
T0 = opts.p0;
T_lo = opts.p_lo;
T_hi = opts.p_hi;

% Assemble data
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
fun = @(T) obj_fun(T, m, data, p_inds, obj_fun_opts);
[T, G, exit_flag, output] = fmincon(fun, T0, [], [], [], [], T_lo, T_hi, [], fit_opts);

p = [m.Parameters.Value];
p(p_inds) = T;
end

function [G, dGds] = obj_fun(T, m, data, p_inds, obj_fun_opts)
% Objective function for fit
opts = amioption('sensi', 1);
switch obj_fun_opts.sens_method
    case 'fwd'
        opts.sensi_meth = 'forward';
    case 'adj'
        opts.sensi_meth = 'adjoint';
end

% Get all model params for fit
p = [m.Parameters.Value];
p(p_inds) = T;

% Get constant ICs
k = [];
for ix = 1:m.nx
    if isnumeric(m.States(ix).InitialValue)
        k = [k, m.States(ix).InitialValue];
    end
end

% Simulate
sol_sens = m.model_fun(data.t, p, k, data, opts);
if sol_sens.status ~= 0
    error('Sensitivity simulation returned non-zero exit status')
end

G = -sol_sens.llh; % obj fun is the negative log-likelihood
dGds = -sol_sens.sllh(p_inds); % and obj fun grad is also negated; only take fit params
end
