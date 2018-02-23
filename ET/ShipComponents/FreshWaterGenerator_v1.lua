local osmose = require 'osmose'
local et = osmose.Model 'FreshWaterGenerator'

----------
-- User parameters
----------

et.inputs = {
    -- Heat exchangers
    EX1_TIN = {default=15, unit='°C'},
    EX1_TOUT = {default=61, unit='°C'},
    EXEVA_T = {default=61, unit='°C'},
    EXCOND_T = {default=59, unit='°C'},
    EX2_TIN = {default=59, unit='°C'},
    EX2_TOUT = {default=25, unit='°C'},
    -- Units consuming electricity
    EFF_PUMP = {default=0.7, unit='-'},
    DP_PUMP = {default=80000, unit='Pa'},
    -- Inlet and outlet mass flows
    CREW_NUMBER = {default=20, unit='-'}, --Number of people on board, required for the estimation of the fresh water demand
    ENGINE_POWER = {default=5, unit='-'} --UNIT: MW . Average engine power demand, estimated. Required for the estimation of the fresh water demand. 
}

-----------
-- Calculated parameters
-----------

et.outputs = {
    -- Heat exchanger delta enthalpy
    WATER_IN = {unit='kg/s', job='(0.5*ENGINE_POWER+0.4*CREW_NUMBER+0.3)*1000/24/3600'}, -- Based on SNAME document "Marine power plants". Original estimation in ton/day, converted to kg/s
    EX_MCP = {unit='kW/K', job='4.187*WATER_IN()'},
    EX1_DH = {unit='kW',job='EX_MCP()*(EX1_TOUT-EX1_TIN)'},
    EX2_DH = {unit='kW',job='EX_MCP()*(EX2_TOUT-EX2_TIN)'},
    EXEVA_DH = {unit='kW',job='WATER_IN()*2370'},
    -- Total electricity supply
    P_EL_TOT = {unit='kW',job='DP_PUMP*WATER_IN()/EFF_PUMP/1000'}
}

-----------
-- Layers
-----------

et:addLayers {Electricity = {type= 'ResourceBalance', unit = 'kW'} }


-----------
-- Units
-----------

et:addUnit('PureWaterProd',{type='Process', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['PureWaterProd']:addStreams{
    -- Thermal streams
    qt_ex1 = qt({tin = 'EX1_TIN', hin = 0, tout='EX1_TOUT', hout='EX1_DH', dtmin=0}),
    qt_ex2 = qt({tin = 'EX2_TIN', hin = 0, tout='EX2_TOUT', hout='EX2_DH', dtmin=0}),
    qt_exeva = qt({tin = 'EXEVA_T', hin = 0, tout='EXEVA_T', hout='EXEVA_DH', dtmin=0}),
    qt_excond = qt({tin = 'EXCOND_T', hin = 'EXEVA_DH', tout='EXCOND_T', hout=0, dtmin=0}),   -- Electricity stream
    elec_tot = rs({'Electricity', 'in', 'P_EL_TOT'}),
}

return et