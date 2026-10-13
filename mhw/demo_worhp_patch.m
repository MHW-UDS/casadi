%% Demo of the patched CasADi WORHP interface (CasADi 3.8.1)
% Feature 1: sol.stats() now contains iter_count, iter_minor, inf_pr, inf_du
% Feature 2: iteration callbacks (opti.callback / iteration_callback) are
%            actually called by WORHP (GitHub issue casadi/casadi#4053)
%
% Requires StopCb.m (same folder) for the early termination example.

clear; clc; close all;
addpath('C:\SOLVER\casadi-3.8.1-windows64-matlab2018b');
import casadi.*
set(groot, 'defaultTextInterpreter', 'latex');
set(groot, 'defaultLegendInterpreter', 'latex');
set(groot, 'defaultAxesTickLabelInterpreter', 'latex');

%% Test problem: constrained Rosenbrock
x   = SX.sym('x', 2);
f   = (1 - x(1))^2 + 100*(x(2) - x(1)^2)^2;
g   = x(1) + x(2);
nlp = struct('x', x, 'f', f, 'g', g);
x0  = [-1.2; 1];
lbg = -10;
ubg = 1.5;

%% Feature 1: iteration statistics in sol.stats()
fprintf('\n#### Feature 1: iteration statistics ####\n');
solvers = {'ipopt', 'worhp'};
opts = struct( ...
    'ipopt', struct('print_time', false, 'ipopt', struct('print_level', 0)), ...
    'worhp', struct('print_time', false, 'worhp', struct('NLPprint', -1)));

for k = 1:numel(solvers)
    name = solvers{k};
    S    = nlpsol('S', name, nlp, opts.(name));
    sol  = S('x0', x0, 'lbg', lbg, 'ubg', ubg);
    st   = S.stats();
    fprintf('%-6s status = %-20s iter_count = %3d', name, st.return_status, st.iter_count);
    if strcmp(name, 'worhp')
        fprintf('  iter_minor = %d  inf_pr = %.2e  inf_du = %.2e', ...
            st.iter_minor, st.inf_pr, st.inf_du);
    end
    fprintf('  x* = %s\n', mat2str(full(sol.x), 6));
end

% Cross check: iteration count in stats vs. WORHP console output
S   = nlpsol('S', 'worhp', nlp, struct('print_time', false));
consoleLog = evalc('sol = S(''x0'', x0, ''lbg'', lbg, ''ubg'', ubg);');
st  = S.stats();
tok = regexp(consoleLog,'Final values after iteration\s+(\d+)', 'tokens', 'once');
fprintf('WORHP console: %s iterations, stats.iter_count: %d\n', tok{1}, st.iter_count);

%% Feature 2a: opti.callback with WORHP (example from issue #4053)
fprintf('\n#### Feature 2a: opti.callback ####\n');
opti = casadi.Opti();
z    = opti.variable(2, 1);
opti.minimize((1 - z(1))^2 + 100*(z(2) - z(1)^2)^2);
opti.subject_to(z(1) + z(2) <= ubg);
opti.set_initial(z, x0);

figure('Name', 'WORHP iterates');
hold on; grid on; box on;
[X1, X2] = meshgrid(linspace(-1.5, 1.5, 200), linspace(-0.5, 2, 200));
contour(X1, X2, log10((1 - X1).^2 + 100*(X2 - X1.^2).^2 + 1e-12), 30);
plot([-0.5, 1.5], [2, 0], 'k--');
hPath = animatedline('Color', 'r', 'Marker', 'o', 'LineWidth', 1.2);
xlabel('$x_1$');
ylabel('$x_2$');
title('Iterates recorded by \texttt{opti.callback} (WORHP)');

% The callback receives the iteration index; opti.debug gives the iterate
opti.callback(@(it) record_iterate(it, opti, z, hPath));
opti.solver('worhp', struct('print_time', false), struct('NLPprint', -1));
sol = opti.solve();
st  = sol.stats();
legend('$\log_{10} f$', '$x_1 + x_2 = 1.5$', 'iterates', 'Location', 'southwest');
axis([-1.5, 1.5, -0.5, 2]);
fprintf('callback calls = %d, iter_count = %d, x* = %s\n', ...
    st.n_call_callback_fun, st.iter_count, mat2str(sol.value(z), 6));
opti.callback();

%% Feature 2b: early termination via iteration_callback
fprintf('\n#### Feature 2b: stop after 5 callback calls ####\n');
cb = StopCb('cb', 2, 1, 5, 'stop');
S  = nlpsol('S', 'worhp', nlp, struct('print_time', false, ...
    'iteration_callback', cb, 'worhp', struct('NLPprint', -1)));
sol = S('x0', x0, 'lbg', lbg, 'ubg', ubg);
st  = S.stats();
fprintf('status = %s, success = %d, iter_count = %d, callback calls = %d\n', ...
    st.return_status, st.success, st.iter_count, cb.k);

%% Local functions
function record_iterate(it, opti, z, hPath)
zk = opti.debug.value(z);
addpoints(hPath,zk(1), zk(2));
drawnow limitrate;
fprintf('  callback: iteration %2d, x = [%8.5f, %8.5f]\n', it, zk(1), zk(2));
end
