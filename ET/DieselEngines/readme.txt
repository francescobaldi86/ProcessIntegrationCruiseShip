The main idea of the Diesel engine functions structure is the following: 

- The version 0.x is as simple as it can get: only fuel input and power output. 
--- The version 0.1 has fixed efficiency
--- The version 0.2 has nonlinear efficiency

- The version 1.x have heat losses included.
(A)--- The version 1.0 considers the exhaust gas as a heat flow
(A)--- The version 1.1 considers the exuaust gas as a resource flow
(A)--- The version 1.2 has nonlinear efficiency (with exhaust gas as heat flow)
(A)--- The version 1.3 has full nonlinear flows (heat flows and efficiency)

- The version 2.x have multiple(2)-engines definition. This allows taking into account the decreasing efficiency after design load
--- The version 2.0 is simply version 1.0 with L,H elements
--- The version 2.1 is simply version 1.1 with L,H elements
--- The version 2.2 is simply version 1.2 with L,H elements

- The version 3.x have multiple(3)-engines definition. This allows taking into account the decreasing efficiency after design load, and the fact that many temperatures change significantly with load
--- The version 2.0 is simply version 1.0 with L,M,H elements
--- The version 2.1 is simply version 1.1 with L,H elements
--- The version 2.2 is simply version 1.2 with L,H elements