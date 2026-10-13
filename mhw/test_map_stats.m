addpath('C:\SOLVER\casadi-3.8.1-mhw');
import casadi.*
opti = Opti(); x = opti.variable(3,1); pv = opti.parameter(3,1); pf = opti.parameter(3,1);
opti.minimize(sumsqr(x-pv)+sumsqr(x-pf)); opti.subject_to(x>=0);
opti.solver('worhp', struct('print_time',false,'worhp',struct('NLPprint',-1)));
f = opti.to_function('f',{pv,pf,x,opti.lam_g},{x,opti.lam_g});
P = [1 2 3 4; 5 6 7 8; 9 1 2 3]; X0 = [1.5 2.5 3.5 4.5; 5.5 6.5 7.5 8.5; 9.5 1.5 2.5 3.5]; L0 = [0.1 .2 .3 .1; .05 .05 .05 .05; 0 0 0 0];
for par = {'serial','thread'}
  M = f.map(4, par{1}, 4);
  [rx, rl] = M(P, [3;3;3], X0, L0);
  fprintf('%s:\n', par{1}); st = M.stats(); disp(st.iter_count); disp(st.success); disp(st.return_status); disp(st.t_wall_element);
end
disp(full(rx));
for i=1:4, f(P(:,i),[3;3;3],X0(:,i),L0(:,i)); s=f.stats(); fprintf('serial iter %d\n', s.iter_count); end
