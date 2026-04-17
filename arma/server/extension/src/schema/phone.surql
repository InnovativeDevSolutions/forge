DEFINE TABLE IF NOT EXISTS phone_user SCHEMALESS;
DEFINE FIELD IF NOT EXISTS uid ON phone_user TYPE string;
DEFINE FIELD OVERWRITE updated_at ON phone_user TYPE option<datetime>;
DEFINE INDEX IF NOT EXISTS phone_user_uid ON phone_user COLUMNS uid UNIQUE;

DEFINE TABLE IF NOT EXISTS phone_contact SCHEMAFULL;
DEFINE FIELD IF NOT EXISTS uid ON phone_contact TYPE string;
DEFINE FIELD IF NOT EXISTS contact_uid ON phone_contact TYPE string;
DEFINE FIELD OVERWRITE created_at ON phone_contact TYPE option<datetime>;
DEFINE INDEX IF NOT EXISTS phone_contact_owner ON phone_contact COLUMNS uid;
DEFINE INDEX IF NOT EXISTS phone_contact_unique ON phone_contact COLUMNS uid, contact_uid UNIQUE;

DEFINE TABLE IF NOT EXISTS phone_message SCHEMAFULL;
DEFINE FIELD IF NOT EXISTS message_id ON phone_message TYPE string;
DEFINE FIELD IF NOT EXISTS from_uid ON phone_message TYPE string;
DEFINE FIELD IF NOT EXISTS to_uid ON phone_message TYPE string;
DEFINE FIELD IF NOT EXISTS message ON phone_message TYPE string;
DEFINE FIELD IF NOT EXISTS timestamp ON phone_message TYPE number;
DEFINE FIELD OVERWRITE created_at ON phone_message TYPE option<datetime>;
DEFINE INDEX IF NOT EXISTS phone_message_message_id ON phone_message COLUMNS message_id UNIQUE;

DEFINE TABLE IF NOT EXISTS phone_message_index SCHEMAFULL;
DEFINE FIELD IF NOT EXISTS uid ON phone_message_index TYPE string;
DEFINE FIELD IF NOT EXISTS message_id ON phone_message_index TYPE string;
DEFINE FIELD IF NOT EXISTS is_read ON phone_message_index TYPE bool;
DEFINE FIELD OVERWRITE updated_at ON phone_message_index TYPE option<datetime>;
DEFINE INDEX IF NOT EXISTS phone_message_index_owner ON phone_message_index COLUMNS uid;
DEFINE INDEX IF NOT EXISTS phone_message_index_message ON phone_message_index COLUMNS message_id;
DEFINE INDEX IF NOT EXISTS phone_message_index_unique ON phone_message_index COLUMNS uid, message_id UNIQUE;

DEFINE TABLE IF NOT EXISTS phone_email SCHEMAFULL;
DEFINE FIELD IF NOT EXISTS email_id ON phone_email TYPE string;
DEFINE FIELD IF NOT EXISTS from_uid ON phone_email TYPE string;
DEFINE FIELD IF NOT EXISTS to_uid ON phone_email TYPE string;
DEFINE FIELD IF NOT EXISTS subject ON phone_email TYPE string;
DEFINE FIELD IF NOT EXISTS body ON phone_email TYPE string;
DEFINE FIELD IF NOT EXISTS timestamp ON phone_email TYPE number;
DEFINE FIELD OVERWRITE created_at ON phone_email TYPE option<datetime>;
DEFINE INDEX IF NOT EXISTS phone_email_email_id ON phone_email COLUMNS email_id UNIQUE;

DEFINE TABLE IF NOT EXISTS phone_email_index SCHEMAFULL;
DEFINE FIELD IF NOT EXISTS uid ON phone_email_index TYPE string;
DEFINE FIELD IF NOT EXISTS email_id ON phone_email_index TYPE string;
DEFINE FIELD IF NOT EXISTS is_read ON phone_email_index TYPE bool;
DEFINE FIELD OVERWRITE updated_at ON phone_email_index TYPE option<datetime>;
DEFINE INDEX IF NOT EXISTS phone_email_index_owner ON phone_email_index COLUMNS uid;
DEFINE INDEX IF NOT EXISTS phone_email_index_email ON phone_email_index COLUMNS email_id;
DEFINE INDEX IF NOT EXISTS phone_email_index_unique ON phone_email_index COLUMNS uid, email_id UNIQUE;

DEFINE TABLE IF NOT EXISTS phone_sequence SCHEMALESS;
DEFINE FIELD IF NOT EXISTS sequence_id ON phone_sequence TYPE string;
DEFINE FIELD IF NOT EXISTS value ON phone_sequence TYPE int;
DEFINE INDEX IF NOT EXISTS phone_sequence_id ON phone_sequence COLUMNS sequence_id UNIQUE;
