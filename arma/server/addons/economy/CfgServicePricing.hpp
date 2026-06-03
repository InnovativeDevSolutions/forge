/*
 * Framework fallback prices for service/economy interactions.
 *
 * Mission-local CfgServicePricing overrides this config. Mission Params with
 * matching names override config defaults before the setup UI opens, and
 * submitted setup UI values override both.
 */
class CfgServicePricing {
    medicalSpawnCost = 100;
    medicalHealCost = 100;
    serviceRepairCost = 500;
    serviceRearmCost = 500;
    fuelCost = 5;
    transportBaseFare = 100;
    transportPricePerKm = 50;
};
