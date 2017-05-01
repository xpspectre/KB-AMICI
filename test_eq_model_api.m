% Build a model using the Model class API
clear; close all; clc
rng('default');

%% Build model
model_name = 'eq_model_1';
model_dir = '_eq_model_1';

m = Model(model_name, model_dir);

m.AddState('A', 1);
m.AddState('B', 2);
m.AddState('C', 0);

m.AddParameter('kf', 5);
m.AddParameter('kr', 3);

m.AddReaction({'bind', 'unbind'}, {'A', 'B'}, {'C'}, 'kf*A*B', 'kr*C')

m.AddObservation('A', 'A');
m.AddObservation('B', 'B');
m.AddObservation('C', 'C');

m.Finalize(); % single arg = false to suppress amiwrap

%% Simulate model
nt = 51;
t = linspace(0, 1, nt);
[x, y] = simulate_model(m, t);

% Plot states
figure
plot(t, x)
xlabel('Time')
ylabel('Conc')
legend({m.States.Name})
title('A + B <-> C Simulation')

%% Fit data
% Test data from KroneckerBio
obs_list   = [1    1    2    2    3    3  ]'; % index of the output this measurement refers to
times_list    = [0.1  1    0.1  1    0.1  1  ]';
measurements = [0.6  0.4  1.5  1.3  0.4  0.6]';

data = [];
data.obs_inds = obs_list;
data.times = times_list;
data.measurements = measurements;
data.std_devs = measurements * 0.05;

fit_opts = [];
fit_opts.p0 = [4, 4]; % initial guess
fit_opts.p_lo = [0.1, 0.1];
fit_opts.p_hi = [10, 10];
fit_opts.sens_method = 'fwd'; % or 'adj'
fit_opts.verbose = 2; % or 0 for none, 1 for final only

[p_fit, G, exit_flag, fit_output] = fit_model(m, data, fit_opts);

x_fit = simulate_model(m, t, [], p_fit);

% Plot fits
figure
hold on
plot(t, x)
ax = gca;
ax.ColorOrderIndex = 1;
plot(times_list(1:2), reshape(measurements,2,3), '+')
ax = gca;
ax.ColorOrderIndex = 1;
plot(t, x_fit, ':')
hold off
legend('A','B','C','A data','B data','C data','A fit','B fit','C Fit')
xlabel('Time')
ylabel('Amount')
title('A + B <-> C Fit')
