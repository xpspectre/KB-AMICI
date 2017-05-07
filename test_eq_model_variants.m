% Build a Model and ModelVariants
clear; close all; clc
rng('default');

%% Build model
build_model = false;
model_name = 'eq_model_1';
model_dir = '_eq_model_1';
model_file = [model_dir '/model_file.mat'];
if build_model
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
    
    save(model_file, 'm');
else
    loaded = load(model_file);
    m = loaded.m;
end

%% Build 3 variants with different initial conditions
nv = 3;
A0 = [1.1, 2.1, 3.1]; % change initial A conc
for iv = 1:nv
    x0i = [m.States.InitialValue];
    x0i(1) = A0(iv);
    mvs(iv) = ModelVariant(sprintf('Eq%i',iv), m, x0i, []);
end

%% Simulate model
nt = 51;
t = linspace(0, 1, nt);
[xs, ys] = simulate_models(mvs, t);

% Plot states
figure
hold on
for iv = 1:nv
    ax = gca;
    ax.ColorOrderIndex = 1;
    plot(t, xs{iv})
end
hold off
xlabel('Time')
ylabel('Conc')
legend({m.States.Name})
title('A + B <-> C Simulations')

%% Generate some synthetic data to fit
t_gen = [0, 0.1, 0.3, 0.5]';
nt = length(t_gen);
[~, ys_gen] = simulate_models(mvs, t_gen);
obs_list = [];
times_list = [];
measurements = [];
ny = 3;
for iv = 1:nv
    for iy = 1:ny
        obs_list = [obs_list; repmat(iy,nt,1)];
        times_list = [times_list; t_gen];
        measurements = [measurements; ys_gen{iv}(:,iy)];
    end
end

%% Fit data
% TODO: Start here
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
