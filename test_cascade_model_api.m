% Build a model using the Model class API
% The cascade model can be made an arbitrary size using a single param
% Note: Building and running larger models (>~100 states/params takes awhile...)
clear; close all; clc
rng('default');

%% Build model
% Note: The errors from AMICI's compiler if you forget a component or have a
%   typo are actually pretty good.
build_model = false;
N = 100; % set N large to test large model limits
model_name = sprintf('cascade_model_%i', N);
model_dir = sprintf('_cascade_model_%i', N);
model_file = [model_dir '/model_file.mat'];
if build_model
    tic
    m = Model(model_name, model_dir);
    
    m.AddState('A', 'A0'); % initial activator
    for iN = 1:N
        m.AddState(sprintf('X%i', iN), 10);
        m.AddState(sprintf('Xp%i', iN), 0);
    end
    
    m.AddParameter('A0', 10);
    for iN = 1:N
        m.AddParameter(sprintf('kon%i', iN), 5);
        m.AddParameter(sprintf('koff%i', iN), 3);
    end
    
    m.AddReaction({'X1 activation', 'X1 inactivation'}, {'X1'}, {'Xp1'}, 'kon1*X1*A', 'koff1*Xp1')
    for iN = 2:N
        m.AddReaction({sprintf('X%i activation', iN), sprintf('X%i inactivation', iN)}, {sprintf('X%i', iN)}, {sprintf('Xp%i', iN)}, sprintf('kon%i*X%i*Xp%i', iN, iN, iN-1), sprintf('koff%i*Xp%i', iN, iN));
    end
    
    for iN = 1:N
        m.AddObservation(sprintf('X%i', iN), sprintf('X%i', iN));
        m.AddObservation(sprintf('Xp%i', iN), sprintf('Xp%i', iN));
    end
    
    m.Finalize(); % single arg = false to suppress amiwrap
    disp(['Time to build: ' num2str(toc) ])
    
    save(model_file, 'm');
else
    tic
    loaded = load(model_file);
    m = loaded.m;
    addpath(m.Directory);
    disp(['Time to load: ' num2str(toc) ])
end

%% Simulate model
nt = 101;
t = linspace(0, 1, nt);
tic
[x, y] = simulate_model(m, t);
disp(['Time to simulate: ' num2str(toc) ])

% Plot states
figure
plot(t, x)
xlabel('Time')
ylabel('Conc')
title('Cascade Model Simulation')
