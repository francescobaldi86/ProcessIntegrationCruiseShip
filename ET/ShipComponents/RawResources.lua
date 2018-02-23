local osmose = require 'osmose'
local et = osmose.Model 'RawResources'

----------
-- User parameters
----------

et.inputs = {
    -- Resource price
    WATER_AVAIL = {default=10000, unit='kg/s'}
}

-----------
-- Calculated parameters
-----------

et.outputs = {
}

-----------
-- Layers
-----------

et:addLayers {Water = {type= 'ResourceBalance', unit = 'kg/s'} }
et:addLayers {H2O = {type= 'ResourceBalance', unit = 'kg/s'} }
et:addLayers {Minerals = {type= 'ResourceBalance', unit = 'kg/s'} }

-----------
-- Units
-----------

et:addUnit('Water_supply',{type='Utility', Fmin = 0, Fmax = 'WATER_AVAIL', Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['Water_supply']:addStreams{
    sw_supply = rs({'Water', 'out', 1})
}
et:addUnit('Water_discharge',{type='Utility', Fmin = 0, Fmax = 'WATER_AVAIL', Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['Water_discharge']:addStreams{
    sw_discharge = rs({'Water', 'in', 1})
}
et:addUnit('H2o_supply',{type='Utility', Fmin = 0, Fmax = 'WATER_AVAIL', Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['H2o_supply']:addStreams{
    fw_supply = rs({'H2O', 'out', 1})
}
et:addUnit('H2o_discharge',{type='Utility', Fmin = 0, Fmax = 'WATER_AVAIL', Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['H2o_discharge']:addStreams{
    fw_discharge = rs({'H2O', 'in', 1})
}
et:addUnit('Mineral_handling',{type='Utility', Fmin = 0, Fmax = 'WATER_AVAIL', Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['Mineral_handling']:addStreams{
    mineral_handling = rs({'Minerals', 'in', 1})
}


return et