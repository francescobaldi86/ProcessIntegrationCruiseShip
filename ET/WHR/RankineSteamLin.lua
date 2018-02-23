local osmose = require 'osmose'
local et = osmose.Model 'RankineConverging'
local cp = require 'coolprop'


-- Note: this component is meant for being able to always have at least quality 1 at the turbine output. 
-- Hence, the meaning of the "DT_SH_EXTRA" is the "extra" DT over the minimum superheating required for convergence. 

----------
-- User parameters
----------

et.inputs = {
    -- General inputs
    T_TC_OUT = {default=350, unit='C'}, 
    T_SW_OUT = {default=60, unit='C'}, 
    C = {default=2, unit='K*m'}, 
    alpha_gas = {default=0.06, unit='m^2'}, 
    alpha_liquid = {default=0.5, unit='m^2'}, 
    alpha_evap = {default=3.6, unit='m^2'}, 
    alpha_cond = {default=1.6, unit='m^2'}, 
    -- Electricity output
    EMAX = {default=1000, unit='kW'},
    -- Polytropic efficiency of the expander
    ETA_IS = {default = 0.7, unit=nil}, --0.8
    -- Efficiency of the electric generator
    ETA_EL = {default = 0.95, unit=nil},
    -- Efficiency of the pump
    ETA_PUMP = {default = 0.7, unit=nil},
    PUMP_WORK_CONVERSION = {default=100, unit='kPa/bar'}, -- from bar to kPa
    -- Fluid
    FLUID = {default = 'Water', unit=nil}, 
    -- Investment cost
    INV_COST = {default = 2500, unit='CHF/kW'},
}

-----------
-- Calculated parameters
-----------

et.outputs = {
  dtmin_MAX = {unit='C', job='2*C/(alpha_gas^0.5)'},
  dtmin_CON = {unit='C', job='C/(alpha_cond^0.5) + C/(alpha_liquid^0.5)'},
  T_MAX = {unit='C', job='T_TC_OUT - dtmin_MAX()-1'},
  T_CON = {unit='C', job='T_SW_OUT + dtmin_CON()+1'},
  -- Evaporation and Condensation pressures
  T_EVA = {unit='C', job=
    function()
      local pressure = P_EVA() * 100000
      local temperature = cp.PropsSI('T', 'P', pressure, 'Q', 0, FLUID)
      local output = temperature -273
      return output
    end
  },
  P_CON = {unit='bar', job=
    function()
      local temperature = T_CON() + 273.15
      local pressure = cp.PropsSI('P', 'T', temperature, 'Q', 0, FLUID)
      local output = pressure / 100000
      return output
    end
  },
  -- Specific latent heat of evaporation, at evaporation pressure
  DH_EVA = {unit='kJ/kg',job=
    function()
      local pressure = P_EVA() * 100000
      local h_sl = cp.PropsSI('H','P',pressure,'Q',0,FLUID)
      local h_sv = cp.PropsSI('H','P',pressure,'Q',1,FLUID)
      local output = (h_sv - h_sl) / 1000
      return output
    end
  },
  -- Specific latent heat of evaporation, at condensation pressure
  DH_CON2 = {unit='kJ/kg',job=
    function()
      local pressure = P_CON() * 100000
      local h_sl = cp.PropsSI('H','P',pressure,'Q',0,FLUID)
      local h_sv = cp.PropsSI('H','P',pressure,'Q',1,FLUID)
      local output = (h_sv - h_sl) / 1000
      return output
    end
  },
  -- Temperature of the superheated vapor
  P_EVA = {unit='bar', job=
    function()
      -- Defining a "min" function because I cannot make it work otherwise
      function min(x,y)
        if x > y then
          return y
        else
          return x
        end
      end
      -- Same for the "abs" function
      function abs(x)
        if x > 0 then
          return x
        else
          return -x
        end
      end
      function sign(x)
        if x>= 0 then
          return 1
        else
          return -1
        end
      end
      function iteration(s_in, T_max, pressure_con, h_sv)
        local h_in = cp.PropsSI('H','S', s_in, 'T', T_max, FLUID)
        local h_out_iso = cp.PropsSI('H','P',pressure_con,'S',s_in,FLUID)
        local h_out_real = h_in - ETA_IS * (h_in - h_out_iso)
        local err = (h_out_real - h_sv) / h_sv
        return err
      end
      -- Initializing error and tolerance
      local tol = 1e-3
      local err = 10
      -- Converting the inputs
      local pressure_con = P_CON() * 100000
      local s_sv = cp.PropsSI('S','P',pressure_con,'Q',1,FLUID)
      local h_sv = cp.PropsSI('H','P',pressure_con,'Q',1,FLUID)
      local T_max = T_MAX() + 273
      -- Calculating the required point iteratively
      local s_in_high = s_sv
      local s_in_low = cp.PropsSI('S','T',T_max,'Q',1,FLUID)
      local errHigh = iteration(s_in_high, T_max, pressure_con, h_sv)
      local errLow = iteration(s_in_low, T_max, pressure_con, h_sv)
      err = min(abs(errLow),abs(errHigh))
      while err > tol do
        local a1 = (errHigh - errLow) / (s_in_high - s_in_low)
        local a0 = errHigh - a1 * s_in_high
        if abs(errHigh) > abs(errLow) then
          s_in_high = -a0 / a1
          errHigh = iteration(s_in_high, T_max, pressure_con, h_sv)
          s_in_new = s_in_high
        else
          s_in_low = -a0 / a1
          errLow = iteration(s_in_low, T_max, pressure_con, h_sv)
          s_in_new = s_in_low
        end
        err = min(abs(errLow),abs(errHigh))
      end
      local s_in = 1.01 * s_in_new  
      local output = cp.PropsSI('P','T',T_max,'S',s_in,FLUID) / 100000
      return output
    end
  },
  -- Specific heat required for superheating the vapor
  DH_SH = {unit='kJ/kg',job=
    function()
      local pressure = P_EVA() * 100000
      local temperature = T_MAX() + 273.15
      local h_shv = cp.PropsSI('H','P',pressure,'T',temperature,FLUID)
      local h_sv = cp.PropsSI('H','P',pressure,'Q',1,FLUID)
      local output = (h_shv - h_sv) / 1000
      return output
    end
  },
  -- Temperature before the economizer
  T_ECO = {unit='C',job=
    function()
      local pressure_con = P_CON() * 100000
      local pressure_eva = P_EVA() * 100000
      local h_ssl = cp.PropsSI('H','P',pressure_con,'Q',0,FLUID) + W_PUMP()*1000
      local output = cp.PropsSI('T','P',pressure_eva,'H',h_ssl,FLUID) - 273.15
      return output
    end
  },
  -- Specific heat required for pre-heating the liquid
  DH_ECO = {unit='kJ/kg',job=
    function()
      local pressure = P_EVA() * 100000
      local temperature = T_ECO() + 273.15
      local h_sl = cp.PropsSI('H','P',pressure,'Q',0,FLUID)
      local h_ssl = cp.PropsSI('H','P',pressure,'T',temperature,FLUID)
      local output = (h_sl - h_ssl) / 1000
      return output
    end
  },
  -- Temperature after the expander
  T_EXP = {unit='C',job=
    function()
      local pressure_eva = P_EVA() * 100000
      local temperature_sh = T_MAX() + 273.15
      local pressure_con = P_CON() * 100000
      local h_in = cp.PropsSI('H','P',pressure_eva,'T',temperature_sh,FLUID)
      local s_in = cp.PropsSI('S','P',pressure_eva,'T',temperature_sh,FLUID)
      local h_out_iso = cp.PropsSI('H','P',pressure_con,'S',s_in,FLUID)
      local h_out_real = h_in - ETA_IS * (h_in - h_out_iso)
      local output = cp.PropsSI('T','P',pressure_con,'H',h_out_real,FLUID) - 273.15
      return output
    end
  },
  -- Specific heat rejected between expander outlet and condenser inlet
  DH_CON1 = {unit='kJ/kg',job=
    function()
      local pressure = P_CON() * 100000
      local t_exp = T_EXP() + 273.15
      local h_v = cp.PropsSI('H','P',pressure,'T',t_exp,FLUID)
      local h_sv = cp.PropsSI('H','P',pressure,'Q',1,FLUID)
      local output = (h_v - h_sv) / 1000
      return output
    end
  },
  -- Thermodynamic specific work output
    W_TH = {unit='kJ/kg',job=
    function()
      local pressure_eva = P_EVA() * 100000
      local temperature_sh = T_MAX() + 273.15
      local pressure_con = P_CON() * 100000
      local h_in = cp.PropsSI('H','P',pressure_eva,'T',temperature_sh,FLUID)
      local s_in = cp.PropsSI('S','P',pressure_eva,'T',temperature_sh,FLUID)
      local h_out_iso = cp.PropsSI('H','P',pressure_con,'S',s_in,FLUID)
      local h_out_real = h_in - ETA_IS * (h_in - h_out_iso)
      local output = (h_in - h_out_real)/1000
      return output
    end
  },
  -- Density of the liquid (required for pump work)
  RHO_L = {unit='kg/m^3',job=
    function()
      local pressure = P_EVA() * 100000
      local temperauture = T_CON() + 273.15
      local output = cp.PropsSI('D','P',pressure,'Q',0,FLUID)
      return output
    end
  },

  -- Pump specific work
  P_EVA_CALC = {unit='kPa',job='P_EVA()*PUMP_WORK_CONVERSION'},
  P_CON_CALC = {unit='kPa',job='P_EVA()*PUMP_WORK_CONVERSION'},
  W_PUMP = {unit='kJ/kg',job='(P_EVA_CALC()-P_CON_CALC())/RHO_L()/ETA_PUMP'},
  -- Net ORC specific work
  W_ORC = {unit='kJ/kg',job='W_TH()-W_PUMP()'},
  -- Scaling coefficient
  MDOT_MAX = {unit='kg/s',job='EMAX/W_ORC()'},
  -- Maximum heat for all the heat exchangers
  QMAX_ECO = {unit='kW',job='DH_ECO()*MDOT_MAX()'},
  QMAX_EVA = {unit='kW',job='DH_EVA()*MDOT_MAX()'},
  QMAX_SH = {unit='kW',job='DH_SH()*MDOT_MAX()'},
  QMAX_CON1 = {unit='kW',job='DH_CON1()*MDOT_MAX()'},
  QMAX_CON2 = {unit='kW',job='DH_CON2()*MDOT_MAX()'},
  PMAX = {unit='kW',job='W_ORC()*MDOT_MAX()*ETA_EL'},
  PMAX_TURBINE = {unit='kW',job='W_TH()*MDOT_MAX()'},
  PMAX_PUMP = {unit='kW',job='W_PUMP()*MDOT_MAX()'},
  
  -- Investment cost
  INV_TURBINE_FIX = {unit='CHF',job=
      function()
        x0_vector = {PMAX_TURBINE}
        cost_function = "cost_drives_steam_turbine"
        temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0_vector,1,'TM')
        output = temp.Cinv1
        return output
      end
    },
    INV_TURBINE_VAR = {unit='CHF',job=
      function()
        x0_vector = {PMAX_TURBINE} -- Assuming Stainless steal as material, and 7 bar as operating pressure
        cost_function = "cost_drives_steam_turbine"
        temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0_vector,1,'TM')
        output = temp.Cinv2
        return output
      end
    },
    INV_PUMP_FIX = {unit='CHF',job=
      function()
        x0_vector = {PMAX_PUMP}
        cost_function = "cost_Pump_Centrifugal"
        temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0_vector,1,'TM')
        output = temp.Cinv1
        return output
      end
    },
    INV_PUMP_VAR = {unit='CHF',job=
      function()
        x0_vector = {PMAX_PUMP} -- Assuming Stainless steal as material, and 7 bar as operating pressure
        cost_function = "cost_Pump_Centrifugal"
        temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0_vector,1,'TM')
        output = temp.Cinv2
        return output
      end
    },
    INV_SH_FIX = {unit='CHF',job=
      function()
        local x0_area = QMAX/10 * 1000 / MLTD() / U_GLOB  -- Assuming U_glob = 2000 W/m2K and MLTD = 600 K
        local x0_vector = {'SS' , x0_area , HPSTEAM_P()} -- Assuming Stainless steal as material, and 7 bar as operating pressure
        local cost_function = "cost_evaporator_long_tube"
        local temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0_vector,2,'TM')
        local output = temp.Cinv1
        return output
      end
    },
    INV_SH_VAR = {unit='CHF',job=
      function()
        local x0_area = QMAX/10 * 1000 / MLTD() / U_GLOB  -- Assuming U_glob = 2000 W/m2K and MLTD = 600 K
        local x0_vector = {'SS' , x0_area , HPSTEAM_P()} -- Assuming Stainless steal as material, and 7 bar as operating pressure
        local cost_function = "cost_evaporator_long_tube"
        local temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0_vector,2,'TM')
        local output = temp.Cinv2 * 1000 / MLTD() / U_GLOB
        return output
      end
    },
    INV_ECO_FIX = {unit='CHF',job=
      function()
        local x0_area = QMAX/10 * 1000 / MLTD() / U_GLOB  -- Assuming U_glob = 2000 W/m2K and MLTD = 600 K
        local x0_vector = {'SS' , x0_area , HPSTEAM_P()} -- Assuming Stainless steal as material, and 7 bar as operating pressure
        local cost_function = "cost_evaporator_long_tube"
        local temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0_vector,2,'TM')
        local output = temp.Cinv1
        return output
      end
    },
    INV_ECO_VAR = {unit='CHF',job=
      function()
        local x0_area = QMAX/10 * 1000 / MLTD() / U_GLOB  -- Assuming U_glob = 2000 W/m2K and MLTD = 600 K
        local x0_vector = {'SS' , x0_area , HPSTEAM_P()} -- Assuming Stainless steal as material, and 7 bar as operating pressure
        local cost_function = "cost_evaporator_long_tube"
        local temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0_vector,2,'TM')
        local output = temp.Cinv2 * 1000 / MLTD() / U_GLOB
        return output
      end
    },
}

-----------
-- Layers
-----------

et:addLayers {Electricity = {type= 'ResourceBalance', unit = 'kW'} }
--et:addLayers {HPSteam = {type= 'ResourceBalance', unit = 'kW'} }

-----------
-- Units
-----------

et:addUnit('ORC',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['ORC']:addStreams{
    -- Heat
    qt_eco = qt({tin = 'T_ECO', hin = 0, tout='T_EVA', hout='QMAX_ECO', stype='liquid'}),
    qt_eva = qt({tin = 'T_EVA', hin = 0, tout='T_EVA', hout='QMAX_EVA', stype='evap'}),
    qt_sh = qt({tin = 'T_EVA', hin = 0, tout='T_MAX', hout='QMAX_SH', stype='gas'}),
    qt_con1 = qt({tin = 'T_EXP', hin = 'QMAX_CON1', tout='T_CON', hout=0, stype='gas'}),
    qt_con2 = qt({tin = 'T_CON', hin = 'QMAX_CON2', tout='T_CON', hout=0, stype='cond'}),
    -- Steam and condensate
    --steam_in = rs({'HPSteam', 'in', 'QMAX_EVA'}),
    -- Electricity consumption
    elec_out = rs({'Electricity', 'out', 'PMAX'})
}

return et