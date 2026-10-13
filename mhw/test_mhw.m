% Smoke test for a casadi-<VER>-mhw folder: own DLLs + official plugins.
% Usage: addpath('C:\SOLVER\casadi-<VER>-mhw'); test_mhw
import casadi.*
fprintf('casadi %s from %s\n', casadi.CasadiMeta.version(), fileparts(which('casadiMEX')));

% 1) Map-Stats with WORHP: per-element stats must equal single calls
opti = Opti(); x = opti.variable(3,1); pv = opti.parameter(3,1);
opti.minimize(sumsqr(x-pv)); opti.subject_to(x>=0);
opti.solver('worhp', struct('print_time',false,'worhp',struct('NLPprint',-1)));
f = opti.to_function('f',{pv},{x});
P = [1 -2 3 4; 5 6 -7 8; 9 1 2 -3];
for par = {'serial','thread'}
  M = f.map(4, par{1}, 4); M(P); st = M.stats();
  fprintf('worhp map %-6s iter_count=%s\n', par{1}, mat2str(st.iter_count));
end
it = zeros(1,4); for i=1:4, f(P(:,i)); s = f.stats(); it(i) = s.iter_count; end
fprintf('worhp single        iter_count=%s\n', mat2str(it));

% 2) WORHP output_file and iter_count (PR #4433)
of = fullfile(tempdir, 'worhp_test_mhw.txt'); if exist(of,'file'), delete(of); end
opti.solver('worhp', struct('print_time',false,'output_file',of));
opti.set_value(pv,[1;2;-1]); opti.solve(); s = opti.stats(); d = dir(of);
fprintf('worhp output_file %d bytes, iter_count=%d\n', d.bytes, s.iter_count);

% 3) official Ipopt plugin with own core
opti.solver('ipopt', struct('print_time',false,'ipopt',struct('print_level',0)));
sol = opti.solve(); fprintf('ipopt x=%s\n', mat2str(full(sol.value(x)),3));
M = opti.to_function('g',{pv},{x}).map(3,'thread',3); M(P(:,1:3)); st = M.stats();
fprintf('ipopt map iter_count=%s\n', mat2str(st.iter_count));

% 4) official Fatrop plugin (stage-wise OCP for structure detection)
N = 10; dt = 0.1; opti = Opti(); x0p = opti.parameter(2,1);
xk = opti.variable(2,1); opti.subject_to(xk == x0p); J = 0;
for k = 1:N
  uk = opti.variable(); xn = opti.variable(2,1);
  opti.subject_to(xn == [xk(1)+dt*xk(2); xk(2)+dt*uk]); opti.subject_to(-1 <= uk <= 1);
  J = J + sumsqr(xk) + uk^2; xk = xn;
  if k == 1, u1 = uk; end
end
opti.minimize(J + sumsqr(xk));
opti.solver('fatrop', struct('structure_detection','auto','print_time',false,'fatrop',struct('print_level',0)));
opti.set_value(x0p,[1;0]); opti.solve(); s = opti.stats();
fprintf('fatrop iter_count=%d\n', s.iter_count);
M = opti.to_function('h',{x0p},{u1}).map(3,'thread',3); M([1 0.5 -1; 0 0 0]); st = M.stats();
fprintf('fatrop map iter_count=%s\n', mat2str(st.iter_count));
disp('TEST_MHW DONE');
