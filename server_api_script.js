const { Pool } = require('pg');

// === CONFIGURATION ===
const GRAPHQL_ENDPOINT = "https://gateway-arbitrum.network.thegraph.com/api/ae36a6bfa6af7dfa3487d2cecf583ebe/subgraphs/id/FPPoFB7S2dcCNrRyjM5QbaMwKqRZPdbTg8ysBrwXd4SP";

// Configuration des tailles de lots
const WALLET_BATCH_SIZE = 50; // Traiter 50 wallets à la fois
const TOKEN_BATCH_SIZE = 100;  // Traiter 100 tokens à la fois

// Configuration PostgreSQL
const pool = new Pool({
  host: 'postgres',
  database: 'realtoken',
  user: 'nocodb',
  password: 'nocodbpassword',
  port: 5432,
});

const query = `
query GetTransferEvents($tokenAddresses: [String!], $destinations: [String!], $skip: Int!) {
  transferEvents(
    where: { token_in: $tokenAddresses, destination_in: $destinations }
    orderBy: timestamp
    orderDirection: desc
    first: 1000
    skip: $skip
  ) {
    id token { id } amount sender destination timestamp transaction { id }
  }
}`;

// Fonction utilitaire pour diviser un array en chunks
function chunkArray(array, chunkSize) {
  const chunks = [];
  for (let i = 0; i < array.length; i += chunkSize) {
    chunks.push(array.slice(i, i + chunkSize));
  }
  return chunks;
}

async function getWalletsAndTokens() {
  try {
    console.log("📤 Récupération des wallets et tokens depuis PostgreSQL...");
    const client = await pool.connect();
    try {
      const [walletsResult, tokensResult] = await Promise.all([
        client.query('SELECT address FROM address_list'),
        client.query('SELECT "uuid" FROM real_tokens')
      ]);

      const destinations = walletsResult.rows
        .map(rec => rec.address?.toLowerCase())
        .filter(Boolean);
      const tokenAddresses = tokensResult.rows
        .map(rec => rec.uuid?.toLowerCase())
        .filter(Boolean);

      console.log(`✅ ${destinations.length} wallets et ${tokenAddresses.length} tokens récupérés.`);
      return { destinations, tokenAddresses };
    } finally {
      client.release();
    }
  } catch (err) {
    console.error("❌ Erreur lors de la récupération des wallets/tokens:", err.message);
    console.error("❌ Stack trace:", err.stack);
    return { destinations: [], tokenAddresses: [] };
  }
}

async function fetchTransactions(tokenAddresses, destinations, skip = 0) {
  try {
    const variables = { tokenAddresses, destinations, skip };
    const response = await fetch(GRAPHQL_ENDPOINT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ query, variables })
    });
    if (!response.ok) throw new Error(`GraphQL query failed`);
    
    const data = await response.json();
    return data.data.transferEvents;
  } catch (err) {
    console.error("❌ Erreur lors de la récupération des transactions:", err.message);
    return [];
  }
}

async function fetchTransactionsForBatch(tokenBatch, destinationBatch) {
  console.log(`🔄 Traitement du lot: ${tokenBatch.length} tokens × ${destinationBatch.length} wallets`);
  
  let allTransactions = [], skip = 0, fetched;
  do {
    const transactions = await fetchTransactions(tokenBatch, destinationBatch, skip);
    fetched = transactions.length;
    allTransactions = allTransactions.concat(transactions);
    skip += 1000;
    
    if (fetched === 1000) {
      console.log(`  📄 Page récupérée: ${skip - 1000 + 1}-${skip} (${fetched} transactions)`);
    } else if (fetched > 0) {
      console.log(`  📄 Dernière page: ${skip - 1000 + 1}-${skip - 1000 + fetched} (${fetched} transactions)`);
    }
  } while (fetched === 1000);

  console.log(`  ✅ Lot terminé: ${allTransactions.length} transactions récupérées`);
  return allTransactions;
}

async function getExistingTransactionIds() {
  const existingIds = new Set();

  console.log("📤 Récupération des transactions existantes depuis PostgreSQL...");
  try {
    const client = await pool.connect();
    try {
      const result = await client.query('SELECT "Transaction ID" FROM transactions_history');
      
      result.rows.forEach(rec => {
        if (rec["Transaction ID"]) {
          existingIds.add(rec["Transaction ID"].toLowerCase().trim());
        }
      });
    } finally {
      client.release();
    }
  } catch (err) {
    console.error(`❌ Erreur dans getExistingTransactionIds: ${err.message}`);
  }

  console.log(`✅ ${existingIds.size} transactions déjà stockées.`);
  return existingIds;
}

async function storeTransactions(records) {
  if (records.length === 0) {
    console.log("🚀 Aucune nouvelle transaction à stocker.");
    return;
  }

  // Dédoublonner les records au cas où il y aurait des doublons dans les données
  const uniqueRecords = [];
  const seenIds = new Set();
  
  for (const record of records) {
    if (!seenIds.has(record.transactionId)) {
      seenIds.add(record.transactionId);
      uniqueRecords.push(record);
    }
  }

  if (uniqueRecords.length < records.length) {
    console.log(`⚠️ ${records.length - uniqueRecords.length} doublons détectés et supprimés dans les nouvelles données`);
  }

  try {
    const client = await pool.connect();
    try {
      // Compter les transactions existantes avant insertion
      const countBefore = await client.query(`
        SELECT COUNT(*) as count FROM transactions_history
      `);

      // Création d'une table temporaire pour le batch insert
      await client.query(`
        CREATE TEMP TABLE temp_transactions (
          \"Transaction ID\" VARCHAR(255),
          \"Token ID\" VARCHAR(255),
          amount DECIMAL(20,4),
          sender VARCHAR(255),
          destination VARCHAR(255),
          timestamp VARCHAR(255),
          \"Transaction Hash\" VARCHAR(255)
        )
      `);

      // Insertion des données dans la table temporaire
      for (const record of uniqueRecords) {
        await client.query(`
          INSERT INTO temp_transactions (
            \"Transaction ID\", \"Token ID\", amount, sender, destination,
            timestamp, \"Transaction Hash\"
          ) VALUES ($1, $2, $3, $4, $5, $6, $7)
        `, [
          record.transactionId,
          record.tokenId,
          record.amount,
          record.sender,
          record.destination,
          record.timestamp,
          record.transactionHash
        ]);
      }

      // Insertion des données de la table temporaire vers la table principale
      // Utilise ON CONFLICT pour éviter les erreurs de doublons
      await client.query(`
        INSERT INTO transactions_history (
          \"Transaction ID\", \"Token ID\", amount, sender, destination,
          timestamp, \"Transaction Hash\"
        )
        SELECT * FROM temp_transactions
        ON CONFLICT (\"Transaction ID\") DO NOTHING
      `);

      // Compter les transactions après insertion pour voir combien ont été réellement ajoutées
      const countAfter = await client.query(`
        SELECT COUNT(*) as count FROM transactions_history
      `);

      const actuallyInserted = parseInt(countAfter.rows[0].count) - parseInt(countBefore.rows[0].count);
      const duplicatesSkipped = uniqueRecords.length - actuallyInserted;

      console.log(`✅ ${actuallyInserted} nouvelles transactions ajoutées`);
      if (duplicatesSkipped > 0) {
        console.log(`⚠️ ${duplicatesSkipped} transactions ignorées (déjà existantes)`);
      }
    } finally {
      client.release();
    }
  } catch (err) {
    console.error("❌ Erreur lors du stockage des transactions:", err.message);
  }
}

async function main() {
  try {
    console.log("🚀 Démarrage du script...");
    const { destinations, tokenAddresses } = await getWalletsAndTokens();
    if (!destinations.length || !tokenAddresses.length) {
      console.warn("⚠️ Aucun wallet ou token trouvé, arrêt du script.");
      return;
    }

    // Diviser en lots
    const tokenBatches = chunkArray(tokenAddresses, TOKEN_BATCH_SIZE);
    const destinationBatches = chunkArray(destinations, WALLET_BATCH_SIZE);
    
    console.log(`📊 Traitement par lots: ${tokenBatches.length} lots de tokens × ${destinationBatches.length} lots de wallets = ${tokenBatches.length * destinationBatches.length} requêtes`);

    const existingIds = await getExistingTransactionIds();
    let allNewRecords = [];
    let batchCount = 0;
    const totalBatches = tokenBatches.length * destinationBatches.length;

    // Traiter chaque combinaison de lots
    for (const tokenBatch of tokenBatches) {
      for (const destinationBatch of destinationBatches) {
        batchCount++;
        console.log(`\n🔄 Traitement du lot ${batchCount}/${totalBatches}`);
        
        const transactions = await fetchTransactionsForBatch(tokenBatch, destinationBatch);
        
        // Filtrer les nouvelles transactions pour ce lot
        const newRecords = transactions
          .filter(tx => !existingIds.has(tx.id.toLowerCase()))
          .map(tx => ({
            transactionId: tx.id,
            tokenId: tx.token.id,
            amount: tx.amount,
            sender: tx.sender,
            destination: tx.destination,
            timestamp: tx.timestamp,
            transactionHash: tx.transaction.id
          }));

        allNewRecords = allNewRecords.concat(newRecords);
        console.log(`  🔍 ${newRecords.length} nouvelles transactions dans ce lot`);
        
        // Petite pause entre les lots pour éviter de surcharger l'API
        if (batchCount < totalBatches) {
          await new Promise(resolve => setTimeout(resolve, 100));
        }
      }
    }

    console.log(`\n📦 Total: ${allNewRecords.length} nouvelles transactions à insérer`);
    await storeTransactions(allNewRecords);
  } catch (err) {
    console.error("❌ Erreur dans le script:", err.message);
  } finally {
    await pool.end();
  }
}

main(); 