DEFINE TABLE IF NOT EXISTS locker SCHEMALESS;
DEFINE FIELD IF NOT EXISTS uid ON locker TYPE string;
DEFINE FIELD OVERWRITE updated_at ON locker TYPE option<datetime>;
DEFINE INDEX IF NOT EXISTS locker_uid ON locker COLUMNS uid UNIQUE;

DEFINE TABLE IF NOT EXISTS locker_item SCHEMAFULL;
DEFINE FIELD IF NOT EXISTS uid ON locker_item TYPE string;
DEFINE FIELD IF NOT EXISTS category ON locker_item TYPE string;
DEFINE FIELD IF NOT EXISTS classname ON locker_item TYPE string;
DEFINE FIELD IF NOT EXISTS amount ON locker_item TYPE int;
DEFINE FIELD OVERWRITE updated_at ON locker_item TYPE option<datetime>;
DEFINE INDEX IF NOT EXISTS locker_item_owner ON locker_item COLUMNS uid;
DEFINE INDEX IF NOT EXISTS locker_item_unique ON locker_item COLUMNS uid, classname UNIQUE;

DEFINE TABLE IF NOT EXISTS owned_locker SCHEMALESS;
DEFINE FIELD IF NOT EXISTS uid ON owned_locker TYPE string;
DEFINE FIELD OVERWRITE updated_at ON owned_locker TYPE option<datetime>;
DEFINE INDEX IF NOT EXISTS owned_locker_uid ON owned_locker COLUMNS uid UNIQUE;

DEFINE TABLE IF NOT EXISTS locker_unlock SCHEMAFULL;
DEFINE FIELD IF NOT EXISTS uid ON locker_unlock TYPE string;
DEFINE FIELD IF NOT EXISTS category ON locker_unlock TYPE string;
DEFINE FIELD IF NOT EXISTS classname ON locker_unlock TYPE string;
DEFINE FIELD IF NOT EXISTS source ON locker_unlock TYPE option<string>;
DEFINE FIELD OVERWRITE unlocked_at ON locker_unlock TYPE option<datetime>;
DEFINE INDEX IF NOT EXISTS locker_unlock_owner ON locker_unlock COLUMNS uid;
DEFINE INDEX IF NOT EXISTS locker_unlock_unique ON locker_unlock COLUMNS uid, category, classname UNIQUE;
