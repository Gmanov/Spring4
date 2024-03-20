#Nivell 1
#Descàrrega els arxius CSV, estudia'ls i dissenya una base de dades amb un esquema d'estrella que contingui, 
#almenys 4 taules de les quals puguis realitzar les següents consultes:

#Creamos la tabla companies
CREATE TABLE company (
  company_id VARCHAR(15) PRIMARY KEY,
  company_name VARCHAR(255),
  phone VARCHAR(15),
  email VARCHAR(100),
  country VARCHAR(100),
  website VARCHAR(255)
);

#Creamos la tabla credit_card
CREATE TABLE credit_card (
  id VARCHAR(20) PRIMARY KEY,
  user_id INT,
  iban VARCHAR(50),
  pan VARCHAR(30),
  pin VARCHAR(4),
  cvv INT,
  track1 VARCHAR(255),
  track2 VARCHAR(255),
  expiring_date VARCHAR(10)
);

#Creamos la tabla product
CREATE TABLE product (
  id INT PRIMARY KEY,
  product_name VARCHAR(255),
  price DECIMAL(10, 2),
  colour VARCHAR(10),
  weight DECIMAL(5, 2),
  warehouse_id VARCHAR(10)
);

#Creamos la tabla transaction
CREATE TABLE transaction (
  id VARCHAR(255) PRIMARY KEY,
  card_id VARCHAR(15),
  business_id VARCHAR(20),
  timestamp TIMESTAMP,
  amount DECIMAL(10, 2),
  declined TINYINT(1),
  product_ids VARCHAR(255),
  user_id INT,
  lat FLOAT,
  longitude FLOAT
);

#Creamos la tabla user:
CREATE TABLE data_user (
  id INT PRIMARY KEY,
  name VARCHAR(100),
  surname VARCHAR(100),
  phone VARCHAR(150),
  email VARCHAR(150),
  birth_date VARCHAR(100),
  country VARCHAR(150),
  city VARCHAR(150),
  postal_code VARCHAR(100),
  address VARCHAR(255)
);

#Debido a que el campo price tiene valores con $, considero que el simbolo $ nos va a dar problemas para operar con los precios.alter
#procedo a quitar el dolar

#Primero voy a cambiar la columna price a VARCHAR para que mysql me deje hacer un import wizard table y me deje introducir los values
ALTER TABLE product
MODIFY COLUMN price VARCHAR(15);

#Ahora que ya tenemos los valores en la table, procedemos a quitar el dolar y darle el formato que queremos
UPDATE product
SET price = CAST(REPLACE(price, '$', '') AS DECIMAL(10, 2))
WHERE price LIKE '$%';

#Comprobamos que ya no tenemos el simbolo $ en el campo Price
SELECT *
FROM product;

#Creamos una nueva tabla donde separaremos los products_id
CREATE TABLE transactions_with_products (
    id VARCHAR(255),
    product_id VARCHAR(255),
    FOREIGN KEY (id) REFERENCES transaction(id),
    FOREIGN KEY(product_id) REFERENCES product(id)
);


#Comando donde nos separara y introducira dentro de la nueva tabla todos los ids sin perder información
INSERT INTO transactions_with_products (id, card_id, business_id, timestamp, amount, declined, product_id, user_id, lat, longitude)
SELECT
    id,
    card_id,
    business_id,
    timestamp,
    amount,
    declined,
    SUBSTRING_INDEX(SUBSTRING_INDEX(product_ids, ',', n), ',', -1) AS product_id,
    user_id,
    lat,
    longitude
FROM
    transaction
JOIN
    (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) AS numbers
ON
    CHAR_LENGTH(product_ids) - CHAR_LENGTH(REPLACE(product_ids, ',', '')) >= n - 1;

#- Exercici 1
#Realitza una subconsulta que mostri tots els usuaris amb més de 30 transaccions utilitzant almenys 2 taules.

SELECT data_user.id ,data_user.name AS Nombre_usuario, COUNT(*) AS total_transacciones
FROM data_user
JOIN transaction ON transaction.user_id = data_user.id
GROUP BY data_user.id ,data_user.name
HAVING total_transacciones > 30;

#-----------------------------------------------------------------------------------------------------------------
#- Exercici 2
#Mostra la mitjana de la suma de transaccions per IBAN de les targetes de crèdit en la companyia Donec Ltd. utilitzant almenys 2 taules.

SELECT AVG(transaction.amount) AS media_transacciones, company.company_name
FROM company
JOIN transaction ON transaction.business_id = company.company_id
WHERE company.company_name = "Donec Ltd" #AND transaction.declined = 0
GROUP BY company.company_name;

SELECT *
FROM company
JOIN transaction ON transaction.business_id = company_id
WHERE company.company_name = "Donec Ltd";


#-------------------------------------------------------------------------------------------------------------------
#Nivell 2
#Crea una nova taula que reflecteixi l'estat de les targetes de crèdit basat en si les últimes tres 
#transaccions van ser declinades i genera la següent consulta:

#Exercici 1
#Quantes targetes estan actives?
CREATE TABLE estat_actual_tarjetes (
WITH ranked_transactions AS (
    SELECT
        id,
        card_id,
        business_id,
        timestamp,
        amount,
        declined,
        product_ids,
        user_id,
        lat,
        longitude,
        ROW_NUMBER() OVER (PARTITION BY card_id ORDER BY timestamp DESC) AS row_num,
        COUNT(*) OVER (PARTITION BY card_id) AS total_transactions
    FROM
        transaction
)
SELECT
    card_id,
    CASE
        WHEN total_transactions >= 3 AND SUM(declined) = 3 THEN 'Tarjeta cancelada'
        ELSE 'Tarjeta activa'
    END AS estado_tarjeta
FROM
    ranked_transactions
WHERE
    row_num <= 3
GROUP BY
    card_id, total_transactions
ORDER BY
    card_id);
    
SELECT *
FROM estat_actual_tarjetes;

#-----------------------------------------------------------------------------------------------------------------------

#Nivell 3
#Crea una taula amb la qual puguem unir les dades del nou arxiu products.csv amb la base de dades creada, tenint en compte que des de transaction tens product_ids. Genera la següent consulta:

#Exercici 1

#Necessitem conèixer el nombre de vegades que s'ha venut cada producte.

SELECT COUNT(product_id), product_name
FROM transactions_with_products, product
WHERE transactions_with_products.product_id = product.id
GROUP BY product_name;


















