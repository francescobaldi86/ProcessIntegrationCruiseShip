local osmose = require 'osmose'
local et = osmose.Model 'GasBurner'
local invcostcalc = require 'equipmentcost.InvestmentCostLinearizator'

----------
-- User parameters
----------

et.inputs = {
    -- Heat supply
    TIN = {default=900, unit='C'},
    TOUT = {default=200, unit='C'},
    QMAX = {default=4000, unit='kW'},
    EFF_TH = {default=0.92, unit=nil},
    -- Costs
    C_INV_FIX = {default = 71000, unit='Dollar'},
    c_inv_var = {default = 80, unit='Dollar/kW'},
    LIFETIME = {default = 20, unit=nil},
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    -- Fuel consumption
    GAS_IN_MAX = {unit='kW',job='QMAX/EFF_TH'},
 
  ANNUALIZATION_FACTOR = {unit=nil, job = '((1+InterestRate)^LIFETIME - 1) / (InterestRate*(1+InterestRate)^LIFETIME)'},
  C_INV_VAR = {unit='Dollar', job='c_inv_var * QMAX / ANNUALIZATION_FACTOR()'},
  C_INV_FIX = {unit='Dollar', job='c_inv_fix / ANNUALIZATION_FACTOR()'},
}

-----------
-- Layers
-----------

et:addLayers {NG = {type= 'ResourceBalance', unit = 'kW'} }

-----------
-- Units
-----------

et:addUnit('GasBurner',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1='C_INV_FIX', Cinv2='C_INV_VAR', Power1=0, Power2=0, Impact1=0,Impact2=0})
et['GasBurner']:addStreams{
    -- Output heat
    qt_hot = qt({tin = 'TIN', hin = 'QMAX', tout='TOUT', hout=0, stype='gas'}),
    -- Fuel consumption
    gas_in = rs({'NG', 'in', 'GAS_IN_MAX'})
}

return et