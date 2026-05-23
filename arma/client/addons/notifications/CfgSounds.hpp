class CfgSounds {
    sounds[] += {QGVAR(notify)};

    class GVAR(notify) {
        name = QGVAR(notify);
        sound[] = {QPATHTOF2(sounds\notify.ogg), 1, 1};
        titles[] = {};
    };
};
