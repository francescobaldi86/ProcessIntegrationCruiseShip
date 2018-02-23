local osmose = require 'osmose'
local et = osmose.Model 'HWGenerator'

----------
-- User parameters
----------

et.inputs = {
    -- Heat supply
    HW_TMAX = {default=90, unit='C'},
    HW_TMIN = {default=80, unit='C'},
    QMAX = {default=10000, unit='kW'},
    
         -- Operating cost
    OP_COST = {default=0.1, unit='Dollar/kWh' },
}

-----------
-- Calculated parameters
-----------

et.outputs = {
  OP_COST_2 = {unit='Dollar/h',job='QMAX*OP_COST'},
  }


-----------
-- Layers
-----------

et:addLayers {HotWater = {type= 'ResourceBalance', unit = 'kW'} }
et:addLayers {Electricity = {type= 'ResourceBalance', unit = 'kW'} }

-----------
-- Units
-----------

et:addUnit('HWGenerator',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2='OP_COST_2', Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['HWGenerator']:addStreams{
    -- Input heat
    qt_hw_gen = qt({tin = 'HW_TMIN', hin = 0, tout='HW_TMAX', hout='QMAX', stype = 'liquid'}),
    -- HotWater network
    hw_out = rs({'HotWater', 'out', 'QMAX'}),
}

return et