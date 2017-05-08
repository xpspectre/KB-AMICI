function [x, y] = simulate_model(m, t, x0, p, opts)
% Simulate single Model
%
% Inputs:
%   m [ Model ]
%       Finalized Model
%   t [ nt double vector ]
%       Timepoints to return results of simulation
%   x0 [ nx double vector, optional ]
%       Initial state values. If blank, use default values in model (constant
%       ICs use value specified from AddState, expression ICs use parameters
%       specified from AddState and AddParameter, with p)
%   p [ np double vector, optional ]
%       Parameter values. If blank, use default values in model.
%   opts [ struct ]
%       Options struct with the following fields:
%       .x0_override_p [ true | {false} ]
%           Whether the state initial conditions in x0 override the values
%           derived from p for states whose ICs are expressions. false means x0
%           values apply to states with constant ICs and states with expression
%           ICs come from specified parameters. true means override all state
%           ICs with the specified x0 values.
%
% Outputs:
%   x [ nt x nx double matrix ]
%       States at each timepoint
%   y [ nt x ny double matrix ]
%       Observations at each timepoint

if nargin < 5
    opts = [];
    if nargin < 4
        p = [];
        if nargin < 3
            x0 = [];
        end
    end
end

% Default options
if isempty(opts)
    opts = struct();
end
opts_ = [];
opts_.x0_override_p = false;
opts = merge_structs(opts_, opts);

if isempty(p)
    p = [m.Parameters.Value];
end
assert(length(p) == m.np, 'Number of parameters does not match model')

sim_opts = amioption('sensi', 0);

% Get constant ICs
ic_is_const = false(m.nx,1);
ic_const = zeros(m.nx,1);
for ix = 1:m.nx
    if isnumeric(m.States(ix).InitialValue)
        ic_is_const(ix) = true;
        ic_const(ix) = m.States(ix).InitialValue;
    end
end

% Handle ICs
if ~isempty(x0) && opts.x0_override_p % Override all ICs
    assert(length(x0) == m.nx, 'Number of initial state values does not match model')
    sim_opts.x0 = x0(:);
    k = zeros(sum(ic_is_const),1); % dummy constants to be ignored
else
    if isempty(x0) % Keep ICs from model
        k = ic_const(ic_is_const);
    else % Override constant ICs
        k = x0(ic_is_const);
    end
end

% Simulate
[status, ~, x, y, ~, ~] = m.model_fun(t, p, k, [], sim_opts);
if status ~= 0
    error('Model integration failed')
end

end
