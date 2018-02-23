local osmose = require 'osmose'
local et = osmose.Model 'LNGEvaporation'

et.software = {'VALI','ET/testch4_Francesca.bls'}

----------
-- User parameters
----------

et.inputs = {
  -- Gas flows
  MAX_CAPACITY = {default=50000, unit='kW'},
    -- Heat exchangers
    S_17_VAPF = {default=0, unit='-',status = 'CST',accuracy = 'A'},
    
    S_19_T = {default=125, unit='C',status = 'CST',accuracy = 'A'},
    S_19_P = {default=300, unit='bar',status = 'CST',accuracy = 'A'},
    
    S_10_T = {default=125, unit='C',status = 'CST',accuracy = 'A'},
    S_10_P = {default=100, unit='bar',status = 'CST',accuracy = 'A'},
    
    S_6_T = {default=125, unit='C',status = 'CST',accuracy = 'A'},
    
    S_14_T = {default=-13, unit='C',status = 'CST',accuracy = 'A'},
    
    S_18_T = {default=-13.15, unit='C',status = 'CST',accuracy = 'A'},
    
    S_7_T = {default=25, unit='C',status = 'CST',accuracy = 'A'},
    S_7_P = {default=6, unit='bar',status = 'CST',accuracy = 'A'},
    
    --EX1_TIN = {default=-29.40, unit='°C'},
    --EX1_TOUT = {default=20.53, unit='°C'},
    --EX1_Q = {default=322.83, unit='kW'},
    
    --EX4_TIN = {default=25, unit='°C'},
    
    --Q_4_LOAD = {default=260, unit='kW',status = 'OFF',accuracy = 'A'},
    --EX4_Q = {default=11.60, unit='kW'},
    
    --EX5_TIN = {default=69.24, unit='°C'},
    --EX5_TOUT = {default=-13.15, unit='°C'},
    --EX5_Q = {default=145.86, unit='kW'},
    
    --EX6_TIN = {default=20.53, unit='°C'},
    --EX6_TOUT = {default=125, unit='°C'},
    --EX6_Q = {default=632.69, unit='kW'},
    
    --EX3_TIN = {default=54.50, unit='°C'},
    --EX3_TOUT = {default=125, unit='°C'},
    --EX3_Q = {default=370.87, unit='kW'},
    
    --EX2_TIN = {default=69.24, unit='°C'},
    --EX2_TOUT = {default=125, unit='°C'},
    --EX2_Q = {default=166.59, unit='kW'},
    --Heat Input

    -- Units consuming electricity
    --W1_P_EL = {default=1.30, unit='kW'},
    --W6_P_EL = {default=13.10, unit='kW'},
    --W7_P_EL = {default=296.01, unit='kW'},
    --W5_P_EL = {default=284.47, unit='kW'},
    --W2_P_EL = {default=246.97, unit='kW'},
    --W3_P_EL = {default=253.95, unit='kW'}

}

-----------
-- Calculated parameters
-----------

et.outputs = {
    -- Heat exchanger delta enthalpy
    --EX1_DH = {unit='kW',job='CP_MEAN*EX1_M*(EX1_TOUT-EX1_TIN)'},
    --EX2_DH = {unit='kW',job='CP_MEAN*EX2_M*(EX2_TOUT-EX2_TIN)'},
    --EX3_DH = {unit='kW',job='CP_MEAN*EX3_M*(EX3_TOUT-EX3_TIN)'},
    --QMAX = {unit='kW',job='EX1_DH()+EX2_DH()+EX3_DH()'},
    -- Total electricity supply
    
    --Gas capacity in kW
    
    --Stream temperatures
    S_3_T = {unit = 'C'},
    S_4_T = {unit = 'C'},
    --S_19_T = {unit = 'C'},
    S_9_T = {unit = 'C'},
    S_10_T = {unit = 'C'},
    S_8_T = {unit = 'C'},
    S_6_T = {unit = 'C'},
    S_14_T = {unit = 'C'},
    S_18_T = {unit = 'C'},
    
    --Pumps power consumption
    W_1_POWER = {unit = 'kW'},
    W_6_POWER = {unit = 'kW'},
    W_7_POWER = {unit = 'kW'},
    
    --Turbines power consumption
    W_5_POWER = {unit = 'kW'},
    W_3_POWER = {unit = 'kW'},
    W_2_POWER = {unit = 'kW'},
    
    --Heat Input
    Q_1_LOAD = {unit = 'kW'},
    Q_7_LOAD = {unit = 'kW'},
    Q_3_LOAD = {unit = 'kW'},
    Q_2_LOAD = {unit = 'kW'},
    
    --Heat Output
    Q_4_LOAD = {unit = 'kW'},
    Q_5_LOAD = {unit = 'kW'},
    
    
    P_EL_IN = {unit='kW',job='W_1_POWER+W_6_POWER+W_7_POWER'},
    P_EL_OUT = {unit='kW',job='W_5_POWER+W_3_POWER+W_2_POWER'},
    P_EL_TOT = {unit='kW',job='P_EL_OUT-P_EL_IN'}
    --TEMP = {unit='°C', job='S_14_T - 273'}
}

-----------
-- Layers
-----------

et:addLayers {Electricity = {type= 'ResourceBalance', unit = 'kW'} }
et:addLayers {Gas = {type= 'ResourceBalance', unit = 'kW'} }
et:addLayers {Lng = {type= 'ResourceBalance', unit = 'kW'} }


-----------
-- Units
-----------

et:addUnit('CH4EvapProd',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['CH4EvapProd']:addStreams{
    -- Heat Input
    --qt_ex1 = qt({tin = 'EX1_TIN', hin = 0, tout='EX1_TOUT', hout='EX1_Q', dtmin=0}),
    qt_ex1 = qt({tin = 'S_3_T', hin = 0, tout='S_4_T', hout='Q_1_LOAD', dtmin=0}),
    --qt_ex4 = qt({tin = 'EX4_TIN', hin = 'Q_4_LOAD', tout='S_14_T', hout=0, dtmin=0}),
    qt_ex4 = qt({tin = 'S_7_T', hin = 'Q_4_LOAD', tout='S_14_T', hout=0, dtmin=0}),
    --qt_ex5 = qt({tin = 'EX5_TIN', hin = 'EX5_Q', tout='EX5_TOUT', hout=0, dtmin=0}),
    qt_ex5 = qt({tin = 'S_8_T', hin = 'Q_5_LOAD', tout='S_18_T', hout=0, dtmin=0}),
    --qt_ex6 = qt({tin = 'EX6_TIN', hin = 0, tout='EX6_TOUT', hout='EX6_Q', dtmin=0}),
    qt_ex6 = qt({tin = 'S_4_T', hin = 0, tout='S_19_T', hout='Q_7_LOAD', dtmin=0}),
    --qt_ex3 = qt({tin = 'EX3_TIN', hin = 0, tout='EX3_TOUT', hout='EX3_Q', dtmin=0}),
    qt_ex3 = qt({tin = 'S_9_T', hin = 0, tout='S_10_T', hout='Q_3_LOAD', dtmin=0}),
    --qt_ex2 = qt({tin = 'EX2_TIN', hin = 0, tout='EX2_TOUT', hout='EX2_Q', dtmin=0}),
    qt_ex2 = qt({tin = 'S_8_T', hin = 0, tout='S_6_T', hout='Q_2_LOAD', dtmin=0}),
    -- Electricity stream
    --elect_out = rs({'Electricity', 'out', 'P_EL_OUT'})
    -- Gas Stream
    gas_out = rs({'Gas', 'out', 'MAX_CAPACITY'})
}

et:addUnit('CH4EvapIntake',{type='Utility', Fmin = 0, Fmax = 1, Cost1=0, Cost2=0, Cinv1=0, Cinv2=0, Power1=0, Power2=0, Impact1=0,Impact2=0})
et['CH4EvapIntake']:addStreams{
    -- Electricity stream
    --elect_in = rs({'Electricity', 'in', 'P_EL_IN'})
    -- Gas Stream
    lng_in = rs({'Lng', 'in', 'MAX_CAPACITY'})
}
return et