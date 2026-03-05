CREATE TABLE IF NOT EXISTS trucker_companies (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(48) NOT NULL,
  type TINYINT DEFAULT 1,
  base_x FLOAT DEFAULT 0.0,
  base_y FLOAT DEFAULT 0.0,
  base_z FLOAT DEFAULT 0.0,
  base_angle FLOAT DEFAULT 0.0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO trucker_companies (name, type) VALUES
('PT. Nusantara Kargo', 1),
('PT. Sumber Pangan', 2),
('PT. Bahari Energi', 3),
('PT. Cepat Kirim', 4),
('PT. Batu Mulia Sejahtera', 5);

CREATE TABLE IF NOT EXISTS trucker_routes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  company_id INT NOT NULL,
  route_name VARCHAR(64) NOT NULL,
  pickup_x FLOAT DEFAULT 0.0,
  pickup_y FLOAT DEFAULT 0.0,
  pickup_z FLOAT DEFAULT 0.0,
  deliver_x FLOAT DEFAULT 0.0,
  deliver_y FLOAT DEFAULT 0.0,
  deliver_z FLOAT DEFAULT 0.0,
  pay_amount INT DEFAULT 5000,
  distance_bonus INT DEFAULT 0,
  FOREIGN KEY (company_id) REFERENCES trucker_companies(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS fish_markets (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(48) NOT NULL,
  pos_x FLOAT DEFAULT 0.0,
  pos_y FLOAT DEFAULT 0.0,
  pos_z FLOAT DEFAULT 0.0,
  price_ikan_nila INT DEFAULT 5000,
  price_ikan_mas INT DEFAULT 8000,
  price_ikan_lele INT DEFAULT 4000,
  price_ikan_bawal INT DEFAULT 7000,
  price_ikan_patin INT DEFAULT 6000,
  last_price_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO fish_markets (name) VALUES
('Pasar Ikan Mekar Pura'),
('Pasar Ikan Madya Raya'),
('Pasar Ikan Mojosono');

CREATE TABLE IF NOT EXISTS bus_terminals (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(48) NOT NULL,
  city TINYINT DEFAULT 1,
  pos_x FLOAT DEFAULT 0.0,
  pos_y FLOAT DEFAULT 0.0,
  pos_z FLOAT DEFAULT 0.0,
  pos_angle FLOAT DEFAULT 0.0,
  route_name VARCHAR(64) DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS player_jobs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  player_id INT NOT NULL,
  job_type TINYINT DEFAULT 0,
  company_id INT DEFAULT 0,
  total_earnings INT DEFAULT 0,
  trips_completed INT DEFAULT 0,
  hired_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_player (player_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
