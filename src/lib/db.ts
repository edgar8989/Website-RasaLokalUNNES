import mysql, { Pool } from 'mysql2/promise';

const globalForMySql = globalThis as unknown as { mysqlPool?: Pool };

export const db = globalForMySql.mysqlPool ?? mysql.createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'rasa_lokal',
  waitForConnections: true,
  connectionLimit: 10,
  decimalNumbers: true,
  dateStrings: true,
});

if (process.env.NODE_ENV !== 'production') globalForMySql.mysqlPool = db;
