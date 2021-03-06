function y = tapas_softmax_wld_sim(r, infStates, p)
% Simulates observations from a Boltzmann distribution with volatility as temperature
%
% --------------------------------------------------------------------------------------------------
% Copyright (C) 2019 Christoph Mathys, TNU, UZH & ETHZ
%
% This file is part of the HGF toolbox, which is released under the terms of the GNU General Public
% Licence (GPL), version 3. You can redistribute it and/or modify it under the terms of the GPL
% (either version 3 or, at your option, any later version). For further details, see the file
% COPYING or <http://www.gnu.org/licenses/>.

% Predictions or posteriors?
pop = 1; % Default: predictions
if r.c_obs.predorpost == 2
    pop = 3; % Alternative: posteriors
end

% Inverse decision temperature beta
be = p;

% Win- and loss-distortion parameters
la_wd = p(1);
la_ld = p(2);

% Assumed structure of infStates:
% dim 1: time (ie, input sequence number)
% dim 2: HGF level
% dim 3: choice number
% dim 4: 1: muhat, 2: sahat, 3: mu, 4: sa

% Number of choices
nc = size(infStates,3);

% Belief trajectories at 1st level
states = squeeze(infStates(:,1,:,pop));

% Log-volatility trajectory
mu3 = squeeze(infStates(:,3,1,3));

% Inputs
u = r.u(:,1);

% True responses underlying belief trajectories
y_true = r.u(:,2);

% Choice matrix Y corresponding to states
Y = zeros(size(states));
Y(sub2ind(size(Y), 1:size(Y,1), y_true')) = 1;

% Choice on previous trial
Yprev = Y;
Yprev = [zeros(1,size(Yprev,2)); Yprev];
Yprev(end,:) = [];

% Wins on previous trial
wprev = u;
wprev = [0; wprev];
wprev(end) = [];

% Losses on previous trial
lprev = 1 - wprev;
lprev(1) = 0;

% In matrix form corresponding to states
Wprev = Yprev;
Wprev(find(lprev),:) = 0;
Lprev = Yprev;
Lprev(find(wprev),:) = 0;

% Win- and loss-distortion
states = states + la_wd*Wprev + la_ld*Lprev;

% Partition functions
Z = sum(exp(be.*states),2);
Z = repmat(Z,1,nc);

% Softmax probabilities
prob = exp(be.*states)./Z;

% Initialize random number generator
if isnan(r.c_sim.seed)
    rng('shuffle');
else
    rng(r.c_sim.seed);
end

% Draw responses
n = size(infStates,1);
y = NaN(n,1);

for j=1:n
    y(j) = find(mnrnd(1, prob(j,:)));
end

end
