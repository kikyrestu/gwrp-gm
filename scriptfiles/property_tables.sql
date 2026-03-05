CREATE TABLE IF NOT EXISTS properties (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(64) NOT NULL,
  type TINYINT DEFAULT 1 COMMENT '1=apartemen,2=kostan,3=gudang,4=ruko,5=tanah',
  owner_id INT DEFAULT 0,
  owner_name VARCHAR(32) DEFAULT '',
  price INT DEFAULT 0,
  rent_price INT DEFAULT 0 COMMENT 'monthly rent',
  rent_due_date TIMESTAMP NULL DEFAULT NULL,
  entry_x FLOAT DEFAULT 0.0,
  entry_y FLOAT DEFAULT 0.0,
  entry_z FLOAT DEFAULT 0.0,
  entry_angle FLOAT DEFAULT 0.0,
  exit_x FLOAT DEFAULT 0.0,
  exit_y FLOAT DEFAULT 0.0,
  exit_z FLOAT DEFAULT 0.0,
  exit_angle FLOAT DEFAULT 0.0,
  interior INT DEFAULT 0,
  vw INT DEFAULT 0,
  locked TINYINT DEFAULT 1,
  storage_slots INT DEFAULT 10,
  has_nib TINYINT DEFAULT 0 COMMENT 'for ruko: has business license',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS property_storage (
  id INT AUTO_INCREMENT PRIMARY KEY,
  property_id INT NOT NULL,
  item_id INT DEFAULT 0,
  amount INT DEFAULT 0,
  FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS property_keys (
  id INT AUTO_INCREMENT PRIMARY KEY,
  property_id INT NOT NULL,
  player_id INT NOT NULL,
  player_name VARCHAR(32) DEFAULT '',
  FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE,
  UNIQUE KEY uq_prop_player (property_id, player_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
