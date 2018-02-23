local osmose = require 'osmose'
local et = osmose.Model 'HPSteamGenerator'
local cp = require 'coolprop'
local math = require 'math'
local invcostcalc = require 'equipmentcost.InvestmentCostLinearizator'

----------
-- User parameters
----------

et.inputs = {
    -- Heat supply
    HPSTEAM_T = {default=150, unit='C'},
    QMAX = {default=10000, unit='kW'},
    HEATSOURCE_TMAX = {default=330, unit='C'},  -- Only used for the calculation of the investment cost
    HEATSOURCE_TMIN = {default=160, unit='C'},  -- Only used for the calculation of the investment cost
    U_GLOB = {default = 25, unit='W/m^2/K'}, -- From EngineeringToolbox.com, [10-40] for boiling liquid water-free convection gas, only used for the calculation of the investment cost
    
    -- Electricity consumption (for pumping/maintain pressure)
    --EL_SPEC = {default=0.01, unit='kWh_el/kWh_th'}
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    MLTD = {unit='C', job=
      function()
        local output = ((HEATSOURCE_TMAX - HPSTEAM_T) - (HEATSOURCE_TMIN - HPSTEAM_T)) / math.log((HEATSOURCE_TMAX - HPSTEAM_T)/(HEATSOURCE_TMIN - HPSTEAM_T))
        return output
      end
      },
    HPSTEAM_P = {unit='bar',job=
    function()
      local temperature = HPSTEAM_T + 273.15
      local p_eva = cp.PropsSI('P','T',temperature,'Q',1,'WATER')
      local output = p_eva / 100000
      return output
    end
  },
    -- Calculating the investment cost.
    -- Since the area is the value that works as reference, we need to make an assumption on the global heat exchange coefficient. This is assumed to be equal to 2000 W/m2K
    INV_FIX = {unit='CHF',job=
      function()
        local x0_area = QMAX/10 * 1000 / MLTD() / U_GLOB  -- Assuming U_glob = 2000 W/m2K and MLTD = 600 K
        local x0_vector = {'SS' , x0_area , HPSTEAM_P()} -- Assuming Stainless steal as material, and 7 bar as operating pressure
        local cost_function = "cost_evaporator_long_tube"
        local temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0_vector,2,'TM')
        local output = temp.Cinv1
        return output
      end
    },
    INV_VAR = {unit='CHF',job=
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

et:addLayers {HPSteam = {type= 'ResourceBalance', unit = 'kW'} }
et:addLayers {Electricity = {type= 'ResourceBalance', unit = 'kW'} }

-----------
-- Units
-----------

et:addUnit('HPSteamGenerator',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1='INV_FIX', Cinv2='INV_VAR', Power1=0, Power2=0, Impact1=0,Impact2=0})
et['HPSteamGenerator']:addStreams{
    -- Input heat
    qt_hp_steam_gen = qt({tin = 'HPSTEAM_T', hin = 0, tout='HPSTEAM_T', hout='QMAX', stype='evap'}),
    -- Steam network
    hpsteam_out = rs({'HPSteam', 'out', 'QMAX'}),
}

return et