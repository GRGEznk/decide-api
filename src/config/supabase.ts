import { createClient } from "@supabase/supabase-js";

// Configuración de Supabase
const supabaseUrl = process.env.SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

// Cliente de Supabase con service role key (para operaciones de backend)
export const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

// Para queries SQL directas si las necesitas
import { Pool } from "pg";

export const pgPool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false,
  },
});

// Verificar conexión
pgPool.on("connect", () => {
  console.log("✅ Conectado a Supabase PostgreSQL");
});

pgPool.on("error", (err) => {
  console.error("❌ Error en conexión PostgreSQL:", err);
});
