#include "script_component.hpp"

if (isNil QEGVAR(common,EventBus)) then { call EFUNC(common,eventBus); };
if (isNil QGVAR(TransportService)) then { call FUNC(initTransportService); };
