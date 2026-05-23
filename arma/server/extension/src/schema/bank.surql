DEFINE TABLE IF NOT EXISTS bank SCHEMALESS;
DEFINE FIELD IF NOT EXISTS uid ON bank TYPE string;
DEFINE FIELD IF NOT EXISTS name ON bank TYPE string;
DEFINE FIELD IF NOT EXISTS bank ON bank TYPE number;
DEFINE FIELD IF NOT EXISTS cash ON bank TYPE number;
DEFINE FIELD IF NOT EXISTS earnings ON bank TYPE number;
DEFINE FIELD IF NOT EXISTS pin ON bank TYPE int;
DEFINE FIELD OVERWRITE updated_at ON bank TYPE option<datetime>;
DEFINE INDEX IF NOT EXISTS bank_uid ON bank COLUMNS uid UNIQUE;

DEFINE TABLE IF NOT EXISTS bank_transaction SCHEMAFULL;
DEFINE FIELD IF NOT EXISTS uid ON bank_transaction TYPE string;
DEFINE FIELD IF NOT EXISTS ordinal ON bank_transaction TYPE int;
DEFINE FIELD IF NOT EXISTS message ON bank_transaction TYPE string;
DEFINE FIELD OVERWRITE created_at ON bank_transaction TYPE option<datetime>;
DEFINE INDEX IF NOT EXISTS bank_transaction_owner ON bank_transaction COLUMNS uid;
DEFINE INDEX IF NOT EXISTS bank_transaction_unique ON bank_transaction COLUMNS uid, ordinal UNIQUE;
