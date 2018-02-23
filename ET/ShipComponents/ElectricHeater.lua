local osmose = require 'osmose'
local et = osmose.Model 'ElectricHeater'
local invcostcalc = require 'equipmentcost.InvestmentCostLinearizator'

----------
-- User parameters
----------

et.inputs = {
    -- Heat supply
    TIN = {default=1000, unit='C'},
    TOUT = {default=1000, unit='C'},
    QMAX = {default=3000, unit='kW'},
    -- Efficiency
    EFF = {default=0.95, unit=nil},
    C_INV_FIX = {default=767000, unit='Dollar'},
    c_inv_var = {default=5537, unit='Dollar/kW'}
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    -- Fuel consumption
    PMAX = {unit='kW',job='QMAX/EFF'},
    -- Investment costs
    -- Calculating the investment cost.
    -- Since the area is the value that works as reference, we need to make an assumption on the global heat exchange coefficient. This is assumed to be equal to 2000 W/m2K
    --[[
    C_INV_FIX = {unit='Dollar',job=
      function()
        x0_area = QMAX * 1000 / 600 / 500  -- Assuming U_glob = 2000 W/m2K and MLTD = 600 K
        x0_vector = {'SS/SS' , x0_area , 4} -- Assuming Stainless steal as material, and 7 bar as operating pressure
        cost_function = "cost_HeatExchanger_Kettle"
        temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0_vector,2,{unit='Dollar', costType='GR'})
        output = temp.Cinv1
        return output
      end
    },
    c_inv_var = {unit='Dollar',job=
      function()
        x0_area = QMAX * 1000 / 600 / 500  -- Assuming U_glob = 2000 W/m2K and MLTD = 600 K
        x0_vector = {'SS/SS' , x0_area , 4} -- Assuming Stainless steal as material, and 7 bar as operating pressure
        cost_function = "cost_HeatExchanger_Kettle"
        temp = invcostcalc.InvestmentCostLinearizator(cost_function,x0_vector,2,{unit='Dollar', costType='GR'})
        output = temp.Cinv2 * 1000 / 600 / 2000
        return output
      end
    },
    --]]
    C_INV_VAR = {unit='Dollar', job='c_inv_var * QMAX'}
}

-----------
-- Layers
-----------

et:addLayers {Electricity = {type= 'ResourceBalance', unit = 'kW'} }

-----------
-- Units
-----------

et:addUnit('ElectricHeater',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1='C_INV_FIX', Cinv2='C_INV_VAR', Power1=0, Power2=0, Impact1=0,Impact2=0})
et['ElectricHeater']:addStreams{
    -- Output heat
    qt_hot = qt({tin = 'TIN', hin = 'QMAX', tout='TOUT', hout=0, stype='gas'}),
    -- Fuel consumption
    el_in = rs({'Electricity', 'in', 'PMAX'})
}

return et