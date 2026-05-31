if (isServer) then {
	[] spawn {
		while { true } do {
			{
				_x addCuratorEditableObjects
				[
				entities [[], ["Logic"], true /* Include vehicle crew */, true /* Exclude dead bodies */],
				true
				];
			} count allCurators;
			sleep 30; // Change to whatever fits your needs
		};
	};
};
