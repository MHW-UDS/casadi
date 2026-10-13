classdef StopCb < casadi.Callback
  properties, nx; ng; k = 0; stop_at; mode; end
  methods
    function self = StopCb(name, nx, ng, stop_at, mode)
      self@casadi.Callback(); self.nx = nx; self.ng = ng; self.stop_at = stop_at; self.mode = mode;
      construct(self, name, struct());
    end
    function v = get_n_in(self),  v = casadi.nlpsol_n_out(); end
    function v = get_n_out(self), v = 1; end
    function v = get_name_in(self, i),  v = casadi.nlpsol_out(i); end
    function v = get_name_out(self, i), v = 'ret'; end
    function sp = get_sparsity_in(self, i)
      n = casadi.nlpsol_out(i);
      if strcmp(n,'f'), sp = casadi.Sparsity.scalar();
      elseif any(strcmp(n,{'x','lam_x'})), sp = casadi.Sparsity.dense(self.nx);
      elseif any(strcmp(n,{'g','lam_g'})), sp = casadi.Sparsity.dense(self.ng);
      else, sp = casadi.Sparsity(0,0); end
    end
    function out = eval(self, arg)
      self.k = self.k + 1;
      if self.k >= self.stop_at && strcmp(self.mode,'error'), error('Absichtlicher Fehler'); end
      out = {double(self.k >= self.stop_at)};
    end
  end
end
