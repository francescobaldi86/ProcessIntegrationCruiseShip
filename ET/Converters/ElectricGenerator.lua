local osmose = require 'osmose'
local et = osmose.Model 'ShaftGenerator'
local invcostcalc = require 'equipmentcost.InvestmentCostLinearizator'

----------
-- User parameters
----------

et.inputs = {
    -- Shaft generator efficiency
    EFF = {default=0.95 , unit=nil},
    -- Maximum power
    PMAX_IN = {default=40000 , unit='kW'}
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    -- Electricity consumption
    PMAX_OUT = {unit='kW',job='EFF*PMAX_IN'},
    -- Investement costName
    C_INV_FIX = {unit='Dollar',job=
      function()
        x0_vector = {5000} 
        cost_function = "cost_ElectricDrives"
        temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0_vector,1,{unit='Dollar', costType='GR'})
        output = temp.Cinv1
        return output
      end
    },
    C_INV_VAR = {unit='Dollar',job=
      function()
        x0_vector = {5000} 
        cost_function = "cost_ElectricDrives"
        temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0_vector,1,{unit='Dollar', costType='GR'})
        output = temp.Cinv2 * PMAX_IN
        return output
      end
    },
}

-----------
-- Layers
-----------

et:addLayers {MechanicalPower = {type= 'MassBalance', unit = 'kW'} }
et:addLayers {Electricity = {type= 'ResourceBalance', unit = 'kW'} }

-----------
-- Units
-----------

et:addUnit('ElectricGenerator',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0 , Power1=0, Power2=0, Impact1=0,Impact2=0})
et['ElectricGenerator']:addStreams{
    -- Mechanical power input
    sg_mech_in = ms({'MechanicalPower', 'in', 'PMAX_IN'}),
    -- Electric power output
    sg_el_out = rs({'Electricity', 'out', 'PMAX_OUT'})
}

return et