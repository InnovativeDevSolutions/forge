DEFINE TABLE IF NOT EXISTS garage SCHEMALESS;
DEFINE FIELD IF NOT EXISTS uid ON garage TYPE string;
DEFINE FIELD OVERWRITE updated_at ON garage TYPE option<datetime>;
DEFINE INDEX IF NOT EXISTS garage_uid ON garage COLUMNS uid UNIQUE;

DEFINE TABLE IF NOT EXISTS garage_vehicle SCHEMAFULL;
DEFINE FIELD IF NOT EXISTS uid ON garage_vehicle TYPE string;
DEFINE FIELD IF NOT EXISTS plate ON garage_vehicle TYPE string;
DEFINE FIELD IF NOT EXISTS classname ON garage_vehicle TYPE string;
DEFINE FIELD IF NOT EXISTS fuel ON garage_vehicle TYPE number;
DEFINE FIELD IF NOT EXISTS damage ON garage_vehicle TYPE number;
DEFINE FIELD IF NOT EXISTS hit_points ON garage_vehicle TYPE object;
DEFINE FIELD IF NOT EXISTS hit_points.names ON garage_vehicle TYPE array<string>;
DEFINE FIELD IF NOT EXISTS hit_points.selections ON garage_vehicle TYPE array<string>;
DEFINE FIELD IF NOT EXISTS hit_points.values ON garage_vehicle TYPE array<number>;
DEFINE FIELD OVERWRITE updated_at ON garage_vehicle TYPE option<datetime>;
DEFINE INDEX IF NOT EXISTS garage_vehicle_owner ON garage_vehicle COLUMNS uid;
DEFINE INDEX IF NOT EXISTS garage_vehicle_unique ON garage_vehicle COLUMNS uid, plate UNIQUE;

DEFINE TABLE IF NOT EXISTS owned_garage SCHEMALESS;
DEFINE FIELD IF NOT EXISTS uid ON owned_garage TYPE string;
DEFINE FIELD OVERWRITE updated_at ON owned_garage TYPE option<datetime>;
DEFINE INDEX IF NOT EXISTS owned_garage_uid ON owned_garage COLUMNS uid UNIQUE;

DEFINE TABLE IF NOT EXISTS garage_unlock SCHEMAFULL;
DEFINE FIELD IF NOT EXISTS uid ON garage_unlock TYPE string;
DEFINE FIELD IF NOT EXISTS category ON garage_unlock TYPE string;
DEFINE FIELD IF NOT EXISTS classname ON garage_unlock TYPE string;
DEFINE FIELD IF NOT EXISTS source ON garage_unlock TYPE option<string>;
DEFINE FIELD OVERWRITE unlocked_at ON garage_unlock TYPE option<datetime>;
DEFINE INDEX IF NOT EXISTS garage_unlock_owner ON garage_unlock COLUMNS uid;
DEFINE INDEX IF NOT EXISTS garage_unlock_unique ON garage_unlock COLUMNS uid, category, classname UNIQUE;
