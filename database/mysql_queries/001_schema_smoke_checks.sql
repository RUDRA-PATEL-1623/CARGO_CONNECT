USE cargoconnect_db;

SELECT DATABASE() AS active_database;

SELECT
  table_name,
  table_rows
FROM information_schema.tables
WHERE table_schema = 'cargoconnect_db'
ORDER BY table_name;

SELECT
  table_name,
  constraint_name,
  referenced_table_name
FROM information_schema.referential_constraints
WHERE constraint_schema = 'cargoconnect_db'
ORDER BY table_name, constraint_name;

SELECT
  table_name,
  index_name,
  GROUP_CONCAT(column_name ORDER BY seq_in_index) AS indexed_columns
FROM information_schema.statistics
WHERE table_schema = 'cargoconnect_db'
GROUP BY table_name, index_name
ORDER BY table_name, index_name;
