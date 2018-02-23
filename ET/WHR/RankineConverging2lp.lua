local osmose = require 'osmose'
local et = osmose.Model 'RankineConverging'
local cp = require 'coolprop'
local invcostcalc = require 'equipmentcost.InvestmentCostLinearizator'


-- Note: this component is meant for being able to always have at least quality 1 at the turbine output. 
-- Hence, the meaning of the "DT_SH_EXTRA" is the "extra" DT over the minimum superheating required for convergence. 

----------
-- User parameters
----------

et.inputs = {
    -- Evaporator
    HPSTEAM_T = {default=150, unit='C'}, -- Ethanol:60, Steam:9
    LPSTEAM_T = {default=120, unit='C'}, -- Ethanol:60, Steam:9
    -- Condenser
    T_CON = {default=40, unit='C'}, -- Ethanol:1, Steam:0.2(1.7)
    -- Degree of superheating
    DT_SH = {default=1, unit='C'},  --Ethanol:100, Steam: 164 
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
    P_COST_FUNCTION_LOW = {default = 100, unit='kW'},
    P_COST_FUNCTION_HIGH = {default = 1600, unit='kW'}
}

-----------
-- Calculated parameters
-----------

et.outputs = {
  T_EVA_HP = {unit='C', job='HPSTEAM_T'},
  T_EVA_LP = {unit='C', job='LPSTEAM_T'},
  -- Evaporation and Condensation pressures
  P_EVA_HP = {unit='bar', job=
    function()
      local temperature = T_EVA_HP() + 273.15
      local pressure = cp.PropsSI('P', 'T', temperature, 'Q', 0, FLUID)
      local output = pressure / 100000
      return output
    end
  },
  P_EVA_LP = {unit='bar', job=
    function()
      local temperature = T_EVA_LP() + 273.15
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
  DH_EVA_HP = {unit='kJ/kg',job=
    function()
      local pressure = P_EVA_HP() * 100000
      local h_sl = cp.PropsSI('H','P',pressure,'Q',0,FLUID)
      local h_sv = cp.PropsSI('H','P',pressure,'Q',1,FLUID)
      local output = (h_sv - h_sl) / 1000
      return output
    end
  },
  DH_EVA_LP = {unit='kJ/kg',job=
    function()
      local pressure = P_EVA_LP() * 100000
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
      local pressure_eva = P_EVA_HP() * 100000
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
  -- Superheated steam temperature that ensures having quality = 1 at the turbine outlet
  T_SH = {unit='C',job='T_SH_MIN()+DT_SH'},
  -- Specific heat required for superheating the vapor
  DH_SH_HP = {unit='kJ/kg',job=
    function()
      local pressure = P_EVA_HP() * 100000
      local temperature = T_SH() + 273.15
      local h_shv = cp.PropsSI('H','P',pressure,'T',temperature,FLUID)
      local h_sv = cp.PropsSI('H','P',pressure,'Q',1,FLUID)
      local output = (h_shv - h_sv) / 1000
      return output
    end
  },
  DH_SH_LP = {unit='kJ/kg',job=
    function()
      local pressure = P_EVA_LP() * 100000
      local temperature = T_EXP_INT() + 273.15
      local h_shv = cp.PropsSI('H','P',pressure,'T',temperature,FLUID)
      local h_sv = cp.PropsSI('H','P',pressure,'Q',1,FLUID)
      local output = (h_shv - h_sv) / 1000
      return output
    end
  },
  -- Temperature before the economizer
  T_ECO_LP = {unit='C',job=
    function()
      local pressure_con = P_CON() * 100000
      local pressure_eva = P_EVA_LP() * 100000
      local h_ssl = cp.PropsSI('H','P',pressure_con,'Q',0,FLUID) + W_PUMP_LP()*1000
      local output = cp.PropsSI('T','P',pressure_eva,'H',h_ssl,FLUID) - 273.15
      return output
    end
  },
  T_ECO_HP = {unit='C',job=
    function()
      local pressure_con = P_CON() * 100000
      local pressure_eva = P_EVA_HP() * 100000
      local h_ssl = cp.PropsSI('H','P',pressure_con,'Q',0,FLUID) + W_PUMP_HP()*1000
      local output = cp.PropsSI('T','P',pressure_eva,'H',h_ssl,FLUID) - 273.15
      return output
    end
  },
  -- Specific heat required for pre-heating the liquid
  DH_ECO_LP = {unit='kJ/kg',job=
    function()
      local pressure = P_EVA_LP() * 100000
      local temperature = T_ECO_LP() + 273.15
      local h_sl = cp.PropsSI('H','P',pressure,'Q',0,FLUID)
      local h_ssl = cp.PropsSI('H','P',pressure,'T',temperature,FLUID)
      local output = (h_sl - h_ssl) / 1000
      return output
    end
  },
  DH_ECO_HP = {unit='kJ/kg',job=
    function()
      local pressure = P_EVA_HP() * 100000
      local temperature = T_ECO_HP() + 273.15
      local h_sl = cp.PropsSI('H','P',pressure,'Q',0,FLUID)
      local h_ssl = cp.PropsSI('H','P',pressure,'T',temperature,FLUID)
      local output = (h_sl - h_ssl) / 1000
      return output
    end
  },
  -- Temperature after the expander
  T_EXP = {unit='C',job=
    function()
      local pressure_eva = P_EVA_HP() * 100000
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
    T_EXP_INT = {unit='C',job=
    function()
      local pressure_eva = P_EVA_HP() * 100000
      local temperature_sh = T_SH() + 273.15
      local pressure_int = P_EVA_LP() * 100000
      local h_in = cp.PropsSI('H','P',pressure_eva,'T',temperature_sh,FLUID)
      local s_in = cp.PropsSI('S','P',pressure_eva,'T',temperature_sh,FLUID)
      local h_out_iso = cp.PropsSI('H','P',pressure_int,'S',s_in,FLUID)
      local h_out_real = h_in - ETA_IS * (h_in - h_out_iso)
      local output = cp.PropsSI('T','P',pressure_int,'H',h_out_real,FLUID) - 273.15
      return output
    end
  },
  -- Specific latent heat of evaporation, at condensation pressure
  DH_CON = {unit='kJ/kg',job=
    function()
      local pressure = P_CON() * 100000
      local h_sl = cp.PropsSI('H','P',pressure,'Q',0,FLUID)
      local h_sv = cp.PropsSI('H','P',pressure,'Q',1,FLUID)
      local output = (h_sv - h_sl) / 1000
      return output
    end
  },
  -- Thermodynamic specific work output
    W_TH_LP = {unit='kJ/kg',job=
    function()
      local pressure_eva = P_EVA_LP() * 100000
      local temperature_sh = T_EXP_INT() + 273.15
      local pressure_con = P_CON() * 100000
      local h_in = cp.PropsSI('H','P',pressure_eva,'T',temperature_sh,FLUID)
      local s_in = cp.PropsSI('S','P',pressure_eva,'T',temperature_sh,FLUID)
      local h_out_iso = cp.PropsSI('H','P',pressure_con,'S',s_in,FLUID)
      local h_out_real = h_in - ETA_IS * (h_in - h_out_iso)
      local output = (h_in - h_out_real)/1000
      return output
    end
  },
  W_TH_HP = {unit='kJ/kg',job=
    function()
      local pressure_eva = P_EVA_HP() * 100000
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
      local pressure = P_EVA_HP() * 100000
      local temperauture = T_CON + 273.15
      local output = cp.PropsSI('D','P',pressure,'Q',0,FLUID)
      return output
    end
  },

  -- Pump specific work
  P_EVA_HP_CALC = {unit='kPa',job='P_EVA_HP()*PUMP_WORK_CONVERSION'},
  P_EVA_LP_CALC = {unit='kPa',job='P_EVA_LP()*PUMP_WORK_CONVERSION'},
  P_CON_CALC = {unit='kPa',job='P_CON()*PUMP_WORK_CONVERSION'},
  W_PUMP_LP = {unit='kJ/kg',job='(P_EVA_LP_CALC()-P_CON_CALC())/RHO_L()/ETA_PUMP'},
  W_PUMP_HP = {unit='kJ/kg',job='(P_EVA_HP_CALC()-P_CON_CALC())/RHO_L()/ETA_PUMP'},
  -- Net ORC specific work
  W_NET_HP = {unit='kJ/kg',job='W_TH_HP()-W_PUMP_HP()'},
  W_NET_LP = {unit='kJ/kg',job='W_TH_LP()-W_PUMP_LP()'},
  -- Scaling coefficient
  MDOT_MAX_HP = {unit='kg/s',job='EMAX/W_NET_HP()'},
  MDOT_MAX_LP = {unit='kg/s',job='EMAX/W_NET_LP()'},
  -- Maximum heat for all the heat exchangers
  QMAX_ECO_HP = {unit='kW',job='DH_ECO_HP()*MDOT_MAX_HP()'},
  QMAX_EVA_HP = {unit='kW',job='DH_EVA_HP()*MDOT_MAX_HP()'},
  QMAX_SH_HP = {unit='kW',job='DH_SH_HP()*MDOT_MAX_HP()'},
  QMAX_CON_HP = {unit='kW',job='DH_EVA_LP()*MDOT_MAX_HP()'},
  QMAX_ECO_LP = {unit='kW',job='DH_ECO_LP()*MDOT_MAX_LP()'},
  QMAX_EVA_LP = {unit='kW',job='DH_EVA_LP()*MDOT_MAX_LP()'},
  QMAX_SH_LP = {unit='kW',job='DH_SH_LP()*MDOT_MAX_LP()'},
  QMAX_CON_LP = {unit='kW',job='DH_CON()*MDOT_MAX_LP()'},
  PMAX_HP = {unit='kW',job='W_NET_HP()*MDOT_MAX_HP()*ETA_EL'},
  PMAX_LP = {unit='kW',job='W_NET_LP()*MDOT_MAX_LP()*ETA_EL'},
  PMAX_TURBINE = {unit='kW',job='W_TH_HP()*MDOT_MAX_HP()'},
  PMAX_PUMP = {unit='kW',job='W_PUMP_HP()*MDOT_MAX_HP()'},
  
  -- Investment cost
  INV_TURBINE_FIX_HIGH = {unit='CHF',job=
      function()
        x0_vector = {P_COST_FUNCTION_HIGH}
        cost_function = "cost_drives_steam_turbine"
        temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0_vector,1,'TM')
        output = temp.Cinv1
        return output
      end
    },
    INV_TURBINE_VAR_HIGH = {unit='CHF/kW',job=
      function()
        x0_vector = {P_COST_FUNCTION_HIGH} -- Assuming Stainless steal as material, and 7 bar as operating pressure
        cost_function = "cost_drives_steam_turbine"
        temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0_vector,1,'TM')
        output = temp.Cinv2
        return output
      end
    },
    INV_TURBINE_FIX_LOW = {unit='CHF',job=
      function()
        x0_vector = {P_COST_FUNCTION_LOW}
        cost_function = "cost_drives_steam_turbine"
        temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0_vector,1,'TM')
        output = temp.Cinv1
        return output
      end
    },
    INV_TURBINE_VAR_LOW = {unit='CHF/kW',job=
      function()
        x0_vector = {P_COST_FUNCTION_LOW} -- Assuming Stainless steal as material, and 7 bar as operating pressure
        cost_function = "cost_drives_steam_turbine"
        temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0_vector,1,'TM')
        output = temp.Cinv2
        return output
      end
    },
    INV_PUMP_FIX = {unit='CHF',job=
      function()
        x0_vector = {'SS', PMAX_PUMP(), P_EVA_HP()}
        cost_function = "cost_Pump_Centrifugal"
        temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0_vector,2,'TM')
        output = temp.Cinv1
        return output
      end
    },
    INV_PUMP_VAR = {unit='CHF/kW',job=
      function()
        x0_vector = {'SS', PMAX_PUMP(), P_EVA_HP()}-- Assuming Stainless steal as material, and 7 bar as operating pressure
        cost_function = "cost_Pump_Centrifugal"
        temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0_vector,2,'TM')
        output = temp.Cinv2
        return output
      end
    },
  
  CINV_FIX_LOW = {unit='CHF',job='INV_TURBINE_FIX_LOW() + INV_PUMP_FIX()'},
  CINV_FIX_HIGH = {unit='CHF',job='INV_TURBINE_FIX_HIGH() + INV_PUMP_FIX()'},
  CINV_VAR_LOW = {unit='CHF',job='INV_TURBINE_VAR_LOW()*EMAX + INV_PUMP_VAR()*PMAX_PUMP()'},
  CINV_VAR_HIGH = {unit='CHF',job='INV_TURBINE_VAR_HIGH()*EMAX + INV_PUMP_VAR()*PMAX_PUMP()'},
    
}

-----------
-- Layers
-----------

et:addLayers {Electricity = {type= 'ResourceBalance', unit = 'kW'} }
et:addLayers {HPSteam = {type= 'ResourceBalance', unit = 'kW'} }
et:addLayers {LPSteam = {type= 'ResourceBalance', unit = 'kW'} }

-----------
-- Units
-----------
--[[
et:addUnit('LP_WHR',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1='CINV_FIX_HIGH', Cinv2='CINV_VAR_HIGH', Power1=0, Power2=0, Impact1=0,Impact2=0})
et['LP_WHR']:addStreams{
    -- Heat
    qt_eco = qt({tin = 'T_ECO_LP', hin = 0, tout='T_EVA_LP', hout='QMAX_ECO_LP', dtmin=2,stype='liquid'}),
    --qt_eva = qt({tin = 'T_EVA_LP', hin = 0, tout='T_EVA_LP', hout='QMAX_EVA_LP', dtmin=2}),
    qt_sh = qt({tin = 'T_EVA_LP', hin = 0, tout='T_EXP_INT', hout='QMAX_SH_LP', dtmin=5, stype='gas'}),
    qt_con2 = qt({tin = 'T_CON', hin = 'QMAX_CON_LP', tout='T_CON', hout=0, dtmin=2, stype='cond'}),
    -- Steam and condensate
    steam_in = rs({'LPSteam', 'in', 'QMAX_EVA_LP'}),
    -- Electricity consumption
    elec_out = rs({'Electricity', 'out', 'PMAX_LP'})
}
--]]
et:addUnit('HP_WHR',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1='CINV_FIX_LOW', Cinv2='CINV_VAR_LOW', Power1=0, Power2=0, Impact1=0,Impact2=0})
et['HP_WHR']:addStreams{
    -- Heat
    qt_eco = qt({tin = 'T_ECO_HP', hin = 0, tout='T_EVA_HP', hout='QMAX_ECO_HP', dtmin=2,stype='liquid'}),
    --qt_eva = qt({tin = 'T_EVA_HP', hin = 0, tout='T_EVA_HP', hout='QMAX_EVA_HP', dtmin=2}),
    qt_sh = qt({tin = 'T_EVA_HP', hin = 0, tout='T_SH', hout='QMAX_SH_HP', dtmin=5, stype='gas'}),
    --qt_con1 = qt({tin = 'T_EXP', hin = 'QMAX_CON1', tout='T_CON', hout=0, dtmin=2}),
    qt_con2 = qt({tin = 'T_CON', hin = 'QMAX_CON_HP', tout='T_CON', hout=0, dtmin=2, stype='cond'}),
    -- Steam and condensate
    steam_in = rs({'HPSteam', 'in', 'QMAX_EVA_HP'}),
    -- Electricity consumption
    elec_out = rs({'Electricity', 'out', 'PMAX_HP'})
}
-- Two-pressure level cycle
et:addUnit('2PLLPWHR',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1='CINV_FIX_HIGH', Cinv2='CINV_VAR_HIGH', Power1=0, Power2=0, Impact1=0,Impact2=0})
et['2PLLPWHR']:addStreams{
    -- Heat
    qt_eco = qt({tin = 'T_ECO_LP', hin = 0, tout='T_EVA_LP', hout='QMAX_ECO_LP', dtmin=2,stype='liquid'}),
    --qt_eva = qt({tin = 'T_EVA_LP', hin = 0, tout='T_EVA_LP', hout='QMAX_EVA_LP', dtmin=2}),
    qt_sh = qt({tin = 'T_EVA_LP', hin = 0, tout='T_EXP_INT', hout='QMAX_SH_LP', dtmin=5, stype='gas'}),
    qt_con2 = qt({tin = 'T_CON', hin = 'QMAX_CON_LP', tout='T_CON', hout=0, dtmin=2, stype='cond'}),
    -- Steam and condensate
    steam_in = rs({'LPSteam', 'in', 'QMAX_EVA_LP'}),
    -- Electricity consumption
    elec_out = rs({'Electricity', 'out', 'PMAX_LP'})
}

et:addUnit('2PLHPWHR',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1='CINV_FIX_LOW', Cinv2='CINV_VAR_LOW', Power1=0, Power2=0, Impact1=0,Impact2=0})
et['2PLHPWHR']:addStreams{
    -- Heat
    qt_eco = qt({tin = 'T_ECO_HP', hin = 0, tout='T_EVA_HP', hout='QMAX_ECO_HP', dtmin=2,stype='liquid'}),
    --qt_eva = qt({tin = 'T_EVA_HP', hin = 0, tout='T_EVA_HP', hout='QMAX_EVA_HP', dtmin=2}),
    qt_sh = qt({tin = 'T_EVA_HP', hin = 0, tout='T_SH', hout='QMAX_SH_HP', dtmin=5, stype='gas'}),
    --qt_con1 = qt({tin = 'T_EXP', hin = 'QMAX_CON1', tout='T_CON', hout=0, dtmin=2}),
    qt_con2 = qt({tin = 'T_CON', hin = 'QMAX_CON_HP', tout='T_CON', hout=0, dtmin=2, stype='cond'}),
    -- Steam and condensate
    steam_in = rs({'HPSteam', 'in', 'QMAX_EVA_HP'}),
    -- Electricity consumption
    elec_out = rs({'Electricity', 'out', 'PMAX_HP'})
}


------------
-- Equations
------------
--Add equations
et:addEquations {
eq_1 = { statement = string.format("subject to %s {p in Periods}: \n\t Units_Use[%s,p] - Units_Use[%s,p] = 0;",'WHR2plexistanceconstraint','2PLHPWHR','2PLLPWHR'), param = {}, addToProblem=1, type ='ampl' },
} -- The 2 units of the 2-pressure WHR system must be either both installed or none

return et