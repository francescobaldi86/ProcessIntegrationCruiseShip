local osmose = require 'osmose'
local et = osmose.Model 'RankineConverging'
local cp = require 'coolprop'


-- Note: this component is meant for being able to always have at least quality 1 at the turbine output. 
-- Hence, the meaning of the "DT_SH_EXTRA" is the "extra" DT over the minimum superheating required for convergence. 

----------
-- User parameters
----------

et.inputs = {
    -- Evaporator
    HPSTEAM_T = {default=150, unit='C'}, -- Ethanol:60, Steam:9
    -- Condenser
    T_CON = {default=40, unit='C'}, -- Ethanol:1, Steam:0.2(1.7)
    -- Degree of superheating
    DT_SH = {default=0, unit='C'},  --Ethanol:100, Steam: 164 
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
    FLUID = {default = 'Water', unit=nil}, -- Optimal for the Diesel engine in the test case is Ethanol, for the Fuel cell is Water
    -- Investment cost
    INV_COST = {default = 2500, unit='CHF/kW'},
    --PAYBACK_TIME = {default = 5, unit='yr'}
    -- Operating cost
    --OP_COST = {default=0.15, unit='CHF/kWh' },
    -- Other
    --OP_TIME = {default=8760, unit='h'}
}

-----------
-- Calculated parameters
-----------

et.outputs = {
  T_EVA = {unit='C', job='HPSTEAM_T'},
  -- Evaporation and Condensation pressures
  P_EVA = {unit='bar', job=
    function()
      local temperature = T_EVA() + 273.15
      local pressure = cp.PropsSI('P', 'T', temperature, 'Q', 0, FLUID)
      local output = pressure / 100000
      return output
    end
  },
  P_CON = {unit='bar', job=
    function()
      local temperature = T_CON + 273.15
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
  T_SH_MIN = {unit='C', job=
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
      -- Initializing error and tolerance
      local tol = 1e-3
      local err = 10
      -- Converting the inputs
      local pressure_eva = P_EVA() * 100000
      local pressure_con = P_CON() * 100000
      local s_sv = cp.PropsSI('S','P',pressure_con,'Q',1,FLUID)
      local h_sv = cp.PropsSI('H','P',pressure_con,'Q',1,FLUID)
      
      -- Calculating the required point iteratively
      local h_in_oldHigh = cp.PropsSI('H','P',pressure_eva,'S',s_sv,FLUID)
      local h_in_oldLow = cp.PropsSI('H','P',pressure_eva,'Q',1,FLUID)
      local s_in_oldHigh = s_sv
      local s_in_oldLow = cp.PropsSI('S','P',pressure_eva,'H',h_in_oldLow,FLUID)
      local h_out_isoOldHigh = cp.PropsSI('H','P',pressure_con,'S',s_in_oldHigh,FLUID)
      local h_out_isoOldLow = cp.PropsSI('H','P',pressure_con,'S',s_in_oldLow,FLUID)
      local h_out_realOldHigh = h_in_oldHigh - ETA_IS * (h_in_oldHigh - h_out_isoOldHigh)
      local h_out_realOldLow = h_in_oldLow - ETA_IS * (h_in_oldLow - h_out_isoOldLow)
      local errHigh = (h_out_realOldHigh - h_sv) / h_sv
      local errLow = (h_out_realOldLow - h_sv) / h_sv
      local h_in_old_best -- Just declaring the variable
      err = min(abs(errLow),abs(errHigh))
      while err > tol do
        local a1 = (errHigh - errLow) / (h_in_oldHigh - h_in_oldLow)
        local a0 = errHigh - a1 * h_in_oldHigh
        if abs(errHigh) > abs(errLow) then
          h_in_oldHigh = -a0 / a1
          s_in_oldHigh = cp.PropsSI('S','P',pressure_eva,'H',h_in_oldHigh,FLUID)
          h_out_isoOldHigh = cp.PropsSI('H','P',pressure_con,'S',s_in_oldHigh,FLUID)
          h_out_realOldHigh = h_in_oldHigh - ETA_IS * (h_in_oldHigh - h_out_isoOldHigh)
          errHigh = (h_out_realOldHigh - h_sv) / h_sv
          h_in_old_best = h_in_oldHigh
        else
          h_in_oldLow = -a0 / a1
          s_in_oldLow = cp.PropsSI('S','P',pressure_eva,'H',h_in_oldLow,FLUID)
          h_out_isoOldLow = cp.PropsSI('H','P',pressure_con,'S',s_in_oldLow,FLUID)
          h_out_realOldLow = h_in_oldLow - ETA_IS * (h_in_oldLow - h_out_isoOldLow)
          errLow = (h_out_realOldLow - h_sv) / h_sv
          h_in_old_best = h_in_oldLow
        end
        err = min(abs(errLow),abs(errHigh))
      end
      local h_in = 1.01 * h_in_old_best  
      local output = cp.PropsSI('T','P',pressure_eva,'H',h_in,FLUID) - 273.15
      return output
    end
  },
  -- S
  
  T_SH = {unit='C',job='T_SH_MIN()+DT_SH'},
  -- Specific heat required for superheating the vapor
  DH_SH = {unit='kJ/kg',job=
    function()
      local pressure = P_EVA() * 100000
      local temperature = T_SH() + 273.15
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
      local temperature_sh = T_SH() + 273.15
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
      local temperature_sh = T_SH() + 273.15
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
      local temperauture = T_CON + 273.15
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
  
  -- Investment cost
  INV_COST_VAR = {unit='CHF', job = 'INV_COST*PMAX()'}
}

-----------
-- Layers
-----------

et:addLayers {Electricity = {type= 'ResourceBalance', unit = 'kW'} }
et:addLayers {HPSteam = {type= 'ResourceBalance', unit = 'kW'} }

-----------
-- Units
-----------

et:addUnit('ORC',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2='INV_COST_VAR', Power1=0, Power2=0, Impact1=0,Impact2=0})
et['ORC']:addStreams{
    -- Heat
    qt_eco = qt({tin = 'T_ECO', hin = 0, tout='T_EVA', hout='QMAX_ECO', dtmin=2}),
    --qt_eva = qt({tin = 'T_EVA', hin = 0, tout='T_EVA', hout='QMAX_EVA', dtmin=2}),
    qt_sh = qt({tin = 'T_EVA', hin = 0, tout='T_SH', hout='QMAX_SH', dtmin=5}),
    qt_con1 = qt({tin = 'T_EXP', hin = 'QMAX_CON1', tout='T_CON', hout=0, dtmin=2}),
    qt_con2 = qt({tin = 'T_CON', hin = 'QMAX_CON2', tout='T_CON', hout=0, dtmin=2}),
    -- Steam and condensate
    steam_in = rs({'HPSteam', 'in', 'QMAX_EVA'}),
    -- Electricity consumption
    elec_out = rs({'Electricity', 'out', 'PMAX'})
}

return et